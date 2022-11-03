## Fail Back Procedure

TODO: This procedure needs to be properly tested and validated. This procedure is currently theoretical.

To failback from GoldDR to Gold after an incident.
- Turn off Gold's PSQL to zero pods
- Drop the Gold PVC and create a new one (or at least delete the data on the PVC)
- Re-create a empty PVC
- Update the config-patroni configmap to use the "Standby Leader" config (you can find a sample of this in /patroni-gold-golddr/helm/patroni-gold-golddr/README.md in this repo) It will likely need to be altered to use the correct TS as the names I think are different.
- turn on Gold's PSQL to 1 pod
- terminal into the PSQL and validate the config with ```patronictl list```
- confirm the synchronization is occuring and/or complete
- once the sync is complete you'll need to work out the timing of the DB fail back and the application failback.
- to toggle the DB back to Gold, NULL the "Standby Leader" field in the config (you can find a sample of this in /patroni-gold-golddr/helm/patroni-gold-golddr/README.md in this repo). This will promote Gold back to being a Leader
- At this point you'll need to get GoldDR back into sync.
- I feel the easies way is to just do a ```helm delete``` of the patroni chart on GoldDR, delete the PVC, then helm install the patroni chart into GoldDR again from scratch. This is basically the same init procedure we've run hundreds of times during development and has worked without issues.
