# Kubernetes Engine Datadog Monitoring POC

## Table of Contents

* [Introduction](#introduction)
* [Architecture](#architecture)
* [Initial Setup](#initial-setup)
   * [Configure gcloud](#configure-gcloud)
* [Tools](#tools)
   * [Install Terraform](#install-terraform)
   * [Install Apache Bench](#install-apache-bench)
* [Configure Authentication](#configure-authentication)
* [Deployment](#deployment)
* [Validation](#validation)
* [Tear Down](#tear-down)
* [Troubleshooting](#troubleshooting)
* [Relevant Material](#relevant-material)


## Introduction
A common goal of cloud computing is to abstract away operational tasks from applications so that
developer efforts can be focused on providing business value. One feature common to most applications is the need to
monitor application and hardware metrics. On
[Google Cloud Platform (GCP)](https://cloud.google.com/) the [Stackdriver](https://cloud.google.com/stackdriver/) suite
of products addresses the need for monitoring and alerting. Some companies may already have a third party solution, however, and this project demonstrates configuring the use of [Datadog](https://www.datadoghq.com/) in a [Kubernetes Engine](https://cloud.google.com/kubernetes-engine/) environment. We show you how to collect [nginx](https://www.nginx.com/) metrics and pipe them to your existing Datadog account.

This demo contains a simple deployment script for Kubernetes Engine using personal accounts and Terraform. There is one manifest
that deploys the Datadog agents and nginx.

NOTE: Personal account should never be used in a CI/CD
pipeline. Provision a service account with all permissions needed to run this when automated.

## Architecture
There is a single Kubernetes Engine cluster with 2 nodes. The `datadog-agent.yaml` manifest creates a [DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/) that runs the Datadog agent on
each node in the cluster. Alongside the Datadog agents are nginx processes that feed metrics to Datadog.

## Initial Setup

### Configure gcloud

All the tools for the demo are installed. When using Cloud Shell execute the following command in order to setup gcloud cli. When executing this command please setup your region
and zone.

```console
gcloud init
```

### Tools
1. [Terraform >= 0.11.7](https://www.terraform.io/downloads.html)
2. Apache Bench

The specific versions used may not be absolutely required but if you run into issues this may help.


#### Install Terraform

Terraform is used to automate the manipulation of cloud infrastructure. Its
[installation instructions](https://www.terraform.io/intro/getting-started/install.html) are also available online.

#### Install Apache Bench

For many users this won't be necessary as many operating systems have Apache
Bench pre-installed. However it is contained within the `apache2-utils` package
for Ubuntu/Debian users, and the `httpd-tools` package for CentOS/Redhat users.

### Configure Authentication

Use `gcloud auth login <your.account@example.com> --no-launch-browser` to get a link to log in your
gcloud cli to your personal account.

## Deployment

### Set up Datadog
1. Create a [free account](https://www.datadoghq.com/pricing/) on Datadog or use an existing one.
1. Login to the DatadogHQ site and go to [Agent Installation](https://app.datadoghq.com/account/settings#agent/kubernetes) to display the text for the Datadog agent Kubernetes manifest. Scroll down until you see `DD_API_KEY`. Copy the value and paste it into `manifests/datadog-agent.yaml` at the same key.
1. In DatadogHQ site go to "Integrations" -> Type "nginx" in the search bar -> Click on the "NGINX" Tile -> "Configuration" Tab -> "Install Integration" -- NGINX dashboards will now be available in the "Dashboards List"

### Set up Kubernetes Engine Cluster Using Terraform and Deploy Services
```
 make create
```

## Validation

1. Log into your Datadog account.
1. Go to the [Dashboards page](https://app.datadoghq.com/dashboard/lists).
1. You will see two pre-built Nginx dashboards that contain metrics for the nginx containers.
1. Click on **NGINX - Metrics**.
1. From a terminal execute ```EXT_IP=http://$(kubectl get svc nginx -n default -ojsonpath='{.status.loadBalancer.ingress[0].ip}/'); echo $EXT_IP```. - If it displays a valid url with an IP address the service is deployed and ready to use. You can access the provided address in a browser to verify that nginx is handling requests.
1. Run ```ab -n 1000 $EXT_IP``` - This will run a load test against nginx and generate metrics that will be forwarded to Datadog.
1. In a few moments you should see data coming into your Datadog dashboard.


## Tear Down
Run `cd terraform` to get back to the Terraform directory and run `terraform destroy` to remove all resources created by this demo.


## Troubleshooting

** No data is displaying in Datadog **
 * Make sure you grabbed the `DD_API_KEY` value from the generated datadog-agent.yaml from the Datadog site. It is generated for you for your specific account.

** Terraform fails due to issues with zone or project **
 * Make sure your gcloud config has values for core/project and compute/zone.
 ```
 gcloud config set core/project <YOUR PROJECT>
 gcloud config set compute/zone <THE ZONE YOU WANT>
 ```

** The install script fails with a `Permission denied` when running Terraform **
 * The credentials that Terraform is using do not provide the
necessary permissions to create resources in the selected projects. Ensure
that the account listed in `gcloud config list` has necessary permissions to
create resources. If it does, regenerate the application default credentials
using `gcloud auth application-default login`.

## Relevant Material
You can find additional information at the following locations
* [DatadogHQ](https://www.datadoghq.com)
* [Terraform Documentation](https://www.terraform.io/docs/providers/google/index.html)

**This is not an officially supported Google product**

