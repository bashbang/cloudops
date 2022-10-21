This repo is actively a work in progress (WIP)

This repo is exploring a solution to provide multi-cluster high availability solution for Postgresql.
Patroni is assisting with this endeavour. This example deployment is on BCGov't Openshift on their "GOLD" cluster.
They have a failover cluster called GoldDR (as in Gold Disaster Recover so pronounce the D and R, but I prefer to use a-ell's pronunciation Golder).

This example sets up a Patroni Cluster on Gold with a Helm chart. The same helm chart can be used to deploy on to GoldDR using the appropriate values files of course.

There are a few quirks to this deployment.
1) The Docker file uses the stock BCGov't Patroni image but overrides it with a custom entrypoint script. Not that I've gotten further into the project I think we may be able to exclude that customization.  Originally it was used to allow for a tweak to the DCS on GoldDR which is setup as a "standby_cluser". But this may not longer be needed as the Helm chart is fabricating the configmap that patroni uses and there a custom install "Job" that overrides GoldDR's configmap.
2) As mentioned, Patroni generally makes its own configmap. This implementation overrides this by first creating the designed configmaps which patroni then sees and uses. I did this for the sole purpose of giving conttrol of those configmap asses to helm. It bothered my that when I did a helm delete that these assests were left behind and caused a conflict on future helm installs.  This of course would not be an issue in a normal course of deployment, only really during development.  However it's still tidy.
3) There's a "Job" container created that runs only on "helm install" and only runs on GoldDR that rewrites the configmap for patroni. This is done because at helm install time a custom BCGov't api called Transport Service Claim (TSC) is use to produce a Transport Service (TS). Here's further details (TODO: Include link here). The patroni config on GoldDR needs the port that this service runs on. We can only get it at runtime, not at HelmTime so the job was created to manage this updates.  Further notes are in the helm chart.  The TS is a service running on Gold (and GoldDR) that is leveraged by Patroni to send PSQL data allwoing GoldDRs cluster (which is a standby_cluster) to keep the PSQL data in sync. It remains as readonly until some action is take to promote the standby leader to leader.

The intention (which is still todo) is to create Github Workflows that will monitor Gold for uptime. This workflow will determine if Gold is happy and if not, it'll update the config on GoldDR to promote it from "Standby Leader" to "Leader".
There are no current plans to automate the switch back to gold.  However we will likely careate a procedure and manual workflow to taggle the tag back to Gold from GoldDR.
