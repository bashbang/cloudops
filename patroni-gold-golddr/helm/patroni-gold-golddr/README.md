TODO Notes:
- the pvc is created here by helm, but there's also a template in the stateful set that wishes to create the PVC. Maybe this should be changed and only created with helm?
- the passwords are hard codeded in the values files.  Gold and GoldDR need to have the same replication uid/pwd. If we were to use random passwords in Helm and Gold were deployed, how would GoldDR obtain that information for its config? We could OC login into Gold from GoldDR but that would then require GoldDR to have a service account with permissions to access secrets (yuck). We can't use the TransportService (TS) to tunnel into Gold since it's dedicated to the PSQL. Perhaps we could create a second TS but that seems overkill and it still grants access to Gold from GoldDR into secrets (again, yuck). The best idea we've had is to use the Vault Service (Platform servies offers a HasiCorp Vault service), however we don't have access to a Vault that could be used for testing/development.

# CLI help
OC Command to get the leader that's listed in the configmap:
```
leader=`oc get configmap patroni-leader -o "jsonpath={.metadata.annotations.leader}"|cut -c1-`
```
OC command to get patroni state of selected $leader:
```
state=`oc exec $leader -- curl -s http://localhost:8008/health | jq -r '.state'`
```

validate the role of the leader
```
oc exec $leader -- curl -s http://localhost:8008/health | jq -r '.role'
```

set the standby to be leader by removing the standby setting in the cluster config....this will make it the leader
```
oc get configmap patroni-config -o json | sed -e "s/standby_cluster/null/g" | oc replace -f -
```

This is used in a service container to obtain the port for the TSC that we can then inject into a secret so that patroni config can use it
```
tsc_port=`oc get services patroni-master-gold -o jsonpath={.spec.ports[0].port}`
```

Config for Gold
```
echo '{
    "apiVersion": "v1",
    "kind": "ConfigMap",
    "metadata": {
        "annotations": {
            "config": "{\"postgresql\":{\"use_pg_rewind\":true,\"parameters\":{\"max_connections\":100,\"max_prepared_transactions\":0,\"max_locks_per_transaction\":64}}}"
        },
        "labels": {
            "app.kubernetes.io/name": "patroni",
            "cluster-name": "patroni"
        },
        "name": "patroni-config",
        "namespace": "c57b11-dev"
    }
}' | oc replace -f -
```

Config for GoldDR - Note you need to set the $tsc_port variable first
```
tsc_port=`oc get services patroni-master-gold -o jsonpath={.spec.ports[0].port}`
 echo '{
    "apiVersion": "v1",
    "kind": "ConfigMap",
    "metadata": {
        "annotations": {
            "config": "{\"postgresql\":{\"use_pg_rewind\":true,\"parameters\":{\"max_connections\":100,\"max_prepared_transactions\":0,\"max_locks_per_transaction\":64}},\"standby_cluster\":{\"host\":\"patroni-master-gold\",\"port\":'$tsc_port',\"username\":\"replication\",\"password\":\"testing123\"}}"
        },
        "labels": {
            "app.kubernetes.io/name": "patroni",
            "cluster-name": "patroni"
        },
        "name": "patroni-config",
        "namespace": "c57b11-dev"
    }
}' | oc replace -f -
```

This is the raw "Standby Leader" config. This was used a few times during testing to force a cluster into standby mode. It was also used on Gold to allow for fail back.
```
{"postgresql":{"use_pg_rewind":true,"parameters":{"max_connections":100,"max_prepared_transactions":0,"max_locks_per_transaction":64}},"standby_cluster":{"host":"patroni-master-gold","port":53647,"username":"replication","password":"testing123"}}
```
