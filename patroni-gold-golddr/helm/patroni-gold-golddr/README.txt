Notes:
- the pvc is created here by helm, but there's also a template in the stateful set that wishes to create the PVC.  Placing the one in help for easier cleanup
- patroni creates configmaps for managing the DCS and the leader states. They're here in helm for easier cleanup on helm delete.



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
tsc_port=`oc get services patroni-gold -o jsonpath={.spec.ports[0].port}`
oc get configmap patroni-config -o json | sed -e "s/99999/$tsc_port/g" | oc replace -f -
