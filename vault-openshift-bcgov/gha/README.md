# Consuming BC Gov't Vault Secrets into Github Actions
Generally the vault is used for jobs/deployments in BC Gov't run Openshift (OCP). On occasion there may be a need to pull in a secret from the BC Gov't run Vault into Github Actions (GHA). An example of such a need is when we use Helm to generate routes in OCP where the private key is stored in vault. This repository is a sample of how to accomplish this task.

High level how it works is one of the technical contacts with Vault access will obtain their Token (PAT) which is stored as a secret in GHA. This will be used by GHA to obtain the Vault secrets (Private Key, Certificate, CACertificate) and save them as temporary files on the GHA container. Then, during the Helm Upgrade, these files will be injested into the chart and deployed.

# Known issues:
- it's not optimal to have PAT as the token for connecting to the Vault. A service account (SA) would be better but at this time a SA token is not available.
- the private key is being stored on the GHA container during execution. This is left behind after the container is terminated. We're relying on Github to take responsibility for both ensuring the data isn't leaking and the container is cleaned up after termination. In both cases, when we echo out the output of the secret as well as cat out the file that the secret was stored, the secret is masked in the output during workflow execution.
- at the time of this writing it's unclear how long this PAT will live. The Vault default is 32 days, but this may have been overridden by the Platform Services team.

# Thanks
Thank you to [Chris Berg](https://github.com/cberg-aot) and [Adam Ell](https://github.com/a-ell) for their help with figuring this out.