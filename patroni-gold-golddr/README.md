## BCGov't Gold/GoldDR PSQL sample deployment
This repo is exploring a solution to provide multi-cluster high availability solution for Postgresql on the BC Governmet's Openshift deployment on their Gold and GoldDR (as in Gold Disaster Recover so pronounce the D and R, but I prefer to use [a-ell's](https://github.com/a-ell) pronunciation Golder) clusters.

This example sets up a Patroni Cluster on Gold with a Helm chart. The same helm chart can be used to deploy on to GoldDR using the appropriate values files of course. The order of deployment is important. Gold must be done first, then GoldDR.  This is because the TSC (see notes below on what a TSC is) is deployed with Gold only. The GoldDR service that's created when the TSC is needed in the helm deployment. So, in short, deploy Gold first, then GoldDR.

## Quick Start

```
# navigate to the helm folder:
cd cloudops/patroni-gold-golddr/helm/patroni-gold-golddr
# Login into Openshift Gold Cluster
oc login --token=sha256~{redacted} --server=https://api.gold.devops.gov.bc.ca:6443
# deploy Gold helm chart
helm upgrade --install --namespace abc123-dev -f values-gold.yaml patroni .
# Login into Openshift GoldDR Cluster
oc login --token=sha256~{redacted} --server=https://api.golddr.devops.gov.bc.ca:6443
# deoploy GoldDR helm chart
helm upgrade --install --namespace abc123-dev -f values-gold.yaml patroni .
```

## Things we learned and why we did stuff.
# Docker
We originaly created a custom docker file for use that included OCP cli toolset as well as a psql client, however we didn't want to have to manage all of that so we used stock off the shelf BC Gov't images for both and interwove the iamges. More details below.

# Patroni Configmaps
Patroni generally makes its own configmap for storing the Leader and Patroni config.  This is defined in the DCS section. We opted to generate our own configmap of the same name through the Helm template. I did this for the sole purpose of giving control of those configmap assets to helm. It bothered me that when I did a helm delete that these assests were left behind and caused a conflict on future helm installs. This of course would not be an issue in a normal course of deployment, only really during development. However it's still tidy and can come in handy on a fallback after a failover occurs.

# Job Pod
There's a "Job" pod created that runs only on "helm install" and only runs on GoldDR that rewrites the configmap for patroni. This is done because at helm install time a custom BCGov't api called Transport Service Claim (TSC) is use to produce a Transport Service (TS). Here's further details (TODO: Include link here). The patroni config on GoldDR needs the port that this service runs on. We can only get it at runtime, not at Helm-time so the job was created to manage this update. Further details are commented in the helm chart. The TS is a service running on Gold (and GoldDR) that acts as a tunnel by Patroni to send WAL data allowing GoldDRs cluster (which is a standby_cluster) to keep the PSQL data in sync. It remains as readonly until some action is take to promote the "Standby Leader" to "Leader".

# Probe Monitor
An Openshift Cronjob was created on GoldDR to act as a Probe/Monitor to watch Gold's status. This proved to be a bit more complicated than we initially expected.
Our end result was a Cronjob that had two init containers. The first init container uses a stock OCP cli image to obtain the port that the TS runs on. This then gets stored as a file in an empty folder that then gets consumed by the second init container. The second init container is a PSQL image that probes Gold's PSQL through the TS to determine if it's running or not. The health status gets saved into the same empty folder then consumed by the third (main) container).  This third container is again an OCP cli container that reads in the health status and if it's unhealthy updates GoldDR's patroni configmap to promote it to "Leader"

I just want to make a small note about inter container communications. We explored various methods and ended up landing on having a "emptyDir: {}" which allowed us to communicate between the different containers in the pod. Thanks to [Steven Barre](https://github.com/StevenBarre) for that help.
# Alternate Probe Monitor
A github workflow was created that will monitor Gold for uptime. This workflow will determine if Gold is happy and if not, it'll update the config on GoldDR to promote it from "Standby Leader" to "Leader". We created and tested this, but didn't use it in favour of the Openshift Cronjob.

# Fail Back
There are no current plans to automate the switch back to Gold. TODO: However we will likely create a procedure and manual workflow to taggle the tag back to Gold from GoldDR.

# Things discovered during development & deployment
During the development of this chart the infrastructure was torn down and rebuilt from scratch each time.  Things that didn't get torn down were the PVCs since they're generally holding DB data we'd not want to accidently have them torn down in a production environment.  This would have to me manually distroyed during developemnt. From time to time we didn't tear down the PVC allowing PSQL to re-connect to the db.  In these cases we would run into unusual behavour with the syncronization and sometimes would have challenges bring the DB up after it was deployed. We didn't look into this in any detail but are suspect that the WAL files have something to do with it. Possibly there's a state file being stored that's causing the issue. Once we move this initial implementation into a more real environment we expect we'll experience these problems again and be forced to do a deeper investigation.

# Assumptions
- This deals with the DB failover only. It does not consider an automated failback.
- This does not consider the application failover or failback. It assumes that the GSLB will be in place to fail over the application. There is a possibility the GSLB won't switch over the application, yet the PSQL will fail over to GoldDR. This could prove to be a problem. In theory if this were to happen Gold would continue to work so you'd not experience any issues, however it would sever the sync procedure and GoldDR would be stood up as a second Leader and of course then be out of sync with Gold. It would also do this silently. It would be a good idea to include an alert/alarm of some sort that would inform admins when a GoldDR failover occurred.
