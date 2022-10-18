Notes:
- the pvc is created here by helm, but there's also a template in the stateful set that wishes to create the PVC.  Placing the one in help for easier cleanup
- patroni creates configmaps for managing the DCS and the leader states. They're here in helm for easier cleanup on helm delete.