This repo is exploring a solution to provide multi-cluster high availability solution for Postgresql on the BC Governmet's Openshift deployment on their Gold and GoldDR (as in Gold Disaster Recover so pronounce the D and R, but I prefer to use a-ell's pronunciation Golder) clusters.

This example sets up a Patroni Cluster on Gold with a Helm chart. The same helm chart can be used to deploy on to GoldDR using the appropriate values files of course. The order of deployment is important. Gold must be done first, then GoldDR.  This is because the TSC (see notes below on what a TSC is) is deployed with Gold only. The GoldDR service that's created when the TSC is needed in the helm deployment. So, in short, deploy Gold first, then GoldDR.

Quick Start
a) Login into Openshift Gold Cluster: oc login --token=sha256~{redacted} --server=https://api.gold.devops.gov.bc.ca:6443
b) navigate to the helm folder and deploy:  
   cd cloudops/patroni-gold-golddr/helm/patroni-gold-golddr
   helm upgrade --install --namespace abc123-dev -f values-gold.yaml patroni .
c) Login into Openshift GoldDR Cluster: oc login --token=sha256~{redacted} --server=https://api.golddr.devops.gov.bc.ca:6443
d) helm upgrade --install --namespace abc123-dev -f values-gold.yaml patroni .

Things we learned and why we did stuff.
1) We originall created a custom docker file for use that included OC cli toolset as well as a psql client, however we didn't want to have to manage all of that so we used stock off the shelf BC Gov't images for both and interwove the iamges. More details below.
2) Patroni generally makes its own configmap for storing the Leader and Patroni config.  This is defined in the DCS section. We opted to generate our own configmap of the same name through the Helm template. I did this for the sole purpose of giving control of those configmap assets to helm. It bothered me that when I did a helm delete that these assests were left behind and caused a conflict on future helm installs. This of course would not be an issue in a normal course of deployment, only really during development. However it's still tidy and can come in handy on a fallback after a failover occurs.
3) There's a "Job" container created that runs only on "helm install" and only runs on GoldDR that rewrites the configmap for patroni. This is done because at helm install time a custom BCGov't api called Transport Service Claim (TSC) is use to produce a Transport Service (TS). Here's further details (TODO: Include link here). The patroni config on GoldDR needs the port that this service runs on. We can only get it at runtime, not at Helm-time so the job was created to manage this update. Further details are commented in the helm chart. The TS is a service running on Gold (and GoldDR) that acts as a tunnel by Patroni to send WAL data allowing GoldDRs cluster (which is a standby_cluster) to keep the PSQL data in sync. It remains as readonly until some action is take to promote the "Standby Leader" to "Leader".

A github workflow was created that will monitor Gold for uptime. This workflow will determine if Gold is happy and if not, it'll update the config on GoldDR to promote it from "Standby Leader" to "Leader". A second monitor (which we think is a better implementation) is also available and automatically deployed with the Helm chart that creates a Cronjob on GoldDR to do the same thing. This keeps the implementation all within Helm.

There are no current plans to automate the switch back to gold. TODO: However we will likely careate a procedure and manual workflow to taggle the tag back to Gold from GoldDR.
