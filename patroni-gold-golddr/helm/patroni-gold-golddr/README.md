Notes:
- the pvc is created here by helm, but there's also a template in the stateful set that wishes to create the PVC.  Placing the one in help for easier cleanup


# The idea is to use github actions to montior the state of patroni cluster on Gold and if Gold is offline for some reason,
# to update the config on GoldDR to standup as master. Maybe we need to also consider looking at the GLB to ensure it's
# switched over from Gold to GoldDR first? Or should we just trust that part is working as expected?


# OC Command to get the leader that's listed in the configmap
leader=`oc get configmap patroni-leader -o "jsonpath={.metadata.annotations.leader}"|cut -c1-`

# OC command to get patroni state of selected $leader
state=`oc exec $leader -- curl -s http://localhost:8008/health | jq -r '.state'`

# validate the role of the leader
oc exec $leader -- curl -s http://localhost:8008/health | jq -r '.role'

#set the standby to be leader by removing the standby setting in the cluster config....this will make it the leader
oc get configmap patroni-config -o json | sed -e "s/standby_cluster/null/g" | oc replace -f -

# This is used in a service container to obtain the port for the TSC that we can then inject into a secret so that patroni config can use it
tsc_port=`oc get services patroni-master-gold -o jsonpath={.spec.ports[0].port}`

# Config for Gold
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


# Config for GoldDR
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