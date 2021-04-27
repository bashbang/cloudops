# Infrastructure Architecture

When building cloud infrastructure, organizations generally go through several stages:

* Manual Changes (through CLI and/or GUI)
* Semi-Automated (mix of Terraform and/or scripts mixed with manual CLI and/or GUI)
* Infrastructure as Code (IaS) (yeah!  You're using all Terraform and have everything version controlled!)
* Collaborative IaS (Now it's time to work with your friend.)
* Advanced Collaborative IaS (Let's take it to the next level.)

This project is setting up a skeleton to help skip to the Collaborative IaS stage.

## Github

Source code needs a place to call home. Git is a distributed version control system. When you "clone" the repository to your workstation you're not only getting the code in it's current state (like svn), you're also getting the entire history of the repository (unlike svn). A cloud based home is best as it will have several tools, hooks and 3rd party integrations that will allow for faster development and deployment.  We've chosen GitHub for this project as it currently has the greatest industry adoption. This repository will house both our application source code and our infrastructure source code.  Although Github is owned by Microsoft it runs independently to easily be used across any programming language or platform service.

## Github Actions

Once our code is pushed into our version control system we'll leverage one of the many pipeline tools.  A pipeline is the automated process of taking the raw code from source through to the consumer. Some of these steps can include validating the code for standards (eg: lint tests), security checking the code for known vulnerabilities, enforcing code controls (eg: peer reviews), compiling the code for deployment, running unit tests on the compiled code, creating test infrastructure to execute tests in a simulated production environment, allowing for manual gateway approvals (eg: manual approval process to move from Stage to Production). There are several pipeline management tools to choose from. Due to the integration with Github we've opted to use "Github Actions".  Here's a recent [article](https://www.cbtnuggets.com/blog/certifications/microsoft/how-to-move-from-azure-devops-to-github-actions) with another source that believes Github Actions is the correct place to develop in   This pipeline will be configured through code, stored in the git repository and executed on code commit. How cool is that!

## Azure

So once the pipeline has done its work and we have an application to deploy, we need a place to put the app for consumption. Once more we have many options at our disposal. We can deploy on AWS S3 for storage, or we could deploy an Azure Compute resource, or maybe we want a GCP Kubernetes service to deploy containers. There's all sorts of fun we can have with infrastructure.  For this current engagement, rather than having a virtual server or cluster of servers up and running 100% of the time wasting resources and money, we've decided to use an Azure service called "functions". The concept of a function is the binary code will be placed in cloud storage and when a web user makes a request for that api endpoint, Azure will very quickly grab the file, unpack it and execute the code.  It'll hang out for a bit uncase there are consecutive calls, but if no new calls come it, it'll just die off and stop charging us. It's like the McDonalds of web apps...service on demand.

So how to we set up this tres cool Azure service? I'm so happy you asked.  I'd like to introduce you to...

## Terraform Cloud

We'll be leveraging Terraform and Terraform Cloud to automate the setup of the Azure functions and any other infrastructure we may need throughout the project.

Hashicorp's tool "Terrafrom" is a mutliplatform tool (workstation executable) used to provision cloud based infrastructure. It's Platform as a Service (PaaS) agnostic allowing this single tool to provision infrastructure across most major providers (eg: Azure, AWS, GPC, etc.) while also having integrations into boutique providers (eg: RabbitMQ, Rancher, Datadog, Cloudflare, etc). As of this writing Terraform has 145 documented providers and 189 community providers. The tool is also based on IaC. If properly enforced, all infrastructure changes are easily tracked and audited through version control and enforcement controls managed by a deployment pipeline.

So why Terraform instead of the native tool such at Azure Resource Manager (ARM) templates?  Here's a list of differences [according to Sam Cogan (Microsoft MVP)](https://docs.microsoft.com/en-us/answers/questions/59990/arm-templates-vs-terraform-in-azure.html) with some alterations by me:

##### ARM Templates

* Azure specific
* Get the latest Azure resources as they are released
* Does not maintain a state file
* Written in JSON
* Does not have a Destroy/Cleanup command
* ARM templates follow the explicit sequencing as declared in the template

##### Terraform

* Supports multiple cloud providers and on-prem resources
* Can lag behind when new Azure resources are released
* Relies on a state file that must be maintained
* Written in HCL, a custom DSL from Hashicorp
* Able to cleanup/destroy resources
* Terraform can automatically manage the dependency of resources itself as it is imperative (or is it?  That can be [debated](https://aws-blog.de/2020/02/the-declarative-vs-imperative-infrastructure-as-code-discussion-is-flawed.html)).

This agnostic adoption allows for cross platform support and a future deployment of "MultiCloud".  We won't be starting with multicloud, but this skeleton setup will allow you to more easily advance in that direction over time.

Terraform is the tool used to interface with the various providers APIs. Terrafrom Cloud is HashiCorp's web service that allows for easier infrastructure collaboration. It's a holding ground for the "state" file that keeps track of the current state of your infrastructure as well as allows for locking of infrastructure changes to ensure no one clobbers another work.

## So, what does that all mean

It means a programmer (or maybe a content manager) can make a change to a file on their workstation, submit the changes to Github, Github will request a peer evaluation of the change.  Once approved, Github Actions will make efforts to ensure the changes wont break anything, Terraform will update or change infrastructure required/requested, and the changes will get deployed to an staging environment. A release manager will be prompted to review the changes and if happy, with a click of a mouse button have the changes reliably and consistently deployed to the production environment.  But wait!  What if a mistake was made?  No problem, just revert the code changes and redeploy to put everything back the way it was.

This model change is so smooth, fast and efficient it can quite easily take an organization from releasing once per month to multiple times a day.
