#!/bin/bash

if [[ $UID -ge 10000 ]]; then
    GID=$(id -g)
    sed -e "s/^postgres:x:[^:]*:[^:]*:/postgres:x:$UID:$GID:/" /etc/passwd > /tmp/passwd
    cat /tmp/passwd > /etc/passwd
    rm /tmp/psasswd
fi

# FIX -> FATAL:  data directory "..." has group or world access
mkdir -p "$PATRONI_POSTGRESQL_DATA_DIR"
chmod 700 "$PATRONI_POSTGRESQL_DATA_DIR"

echo "Chris was here"

cat > /home/postgres/patroni.yml <<__EOF__
bootstrap:
  post_bootstrap: /usr/share/scripts/patroni/post_init.sh
  dcs:
    postgresql:
      use_pg_rewind: true
      parameters:
        max_connections: ${POSTGRESQL_MAX_CONNECTIONS:-100}
        max_prepared_transactions: ${POSTGRESQL_MAX_PREPARED_TRANSACTIONS:-0}
        max_locks_per_transaction: ${POSTGRESQL_MAX_LOCKS_PER_TRANSACTION:-64}
__EOF__
# TODOL The port would be variable and can be discovered with: oc -n c57b11-dev get ts
# TODO: perhaps output as a json and obtain the desired information or grep and sed the port?
# TODO: Also the service (host) is hard coded here, this would be better to pull that info from the helm values file, or pass it into this script.
if ($GOLD) cat >> /home/postgres/patroni.yml <<__EOF__
    standby_cluster:
      host: patroni-gold
      port: 16206
      username: ${PATRONI_REPLICATION_USERNAME}
      password: ${PATRONI_REPLICATION_PASSWORD}
__EOF__
cat >> /home/postgres/patroni.yml <<__EOF__
  initdb:
  - auth-host: md5
  - auth-local: trust
  - encoding: UTF8
  - locale: en_US.UTF-8
  - data-checksums
  pg_hba:
  - host all all 0.0.0.0/0 md5
  - host replication ${PATRONI_REPLICATION_USERNAME} ${POD_IP}/16    md5
restapi:
  connect_address: '${POD_IP}:8008'
postgresql:
  connect_address: '${POD_IP}:5432'
  authentication:
    superuser:
      password: '${PATRONI_SUPERUSER_PASSWORD}'
    replication:
      password: '${PATRONI_REPLICATION_PASSWORD}'
__EOF__

unset PATRONI_SUPERUSER_PASSWORD PATRONI_REPLICATION_PASSWORD
export KUBERNETES_NAMESPACE=$PATRONI_KUBERNETES_NAMESPACE
export POD_NAME=$PATRONI_NAME

exec /usr/bin/python3 /usr/local/bin/patroni /home/postgres/patroni.yml