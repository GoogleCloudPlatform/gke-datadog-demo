/*
Copyright 2018 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/


// https://www.terraform.io/docs/providers/google/d/google_container_cluster.html
// Create the primary cluster for this project.
// Node count is 2 to better illustrate that DaemonSet deploys datadog agent to
// each node
resource "google_container_cluster" "primary" {
  name               = "${var.clusterName}"
  zone               = "${var.zone}"
  initial_node_count = 2

  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials ${google_container_cluster.primary.name}"
  }

  provisioner "local-exec" {
    command  = "kubectl create configmap nginx-config --from-file=manifests/configs/default.conf"
  }

  provisioner "local-exec" {
    command  = "kubectl create configmap datadog-config --from-file=manifests/configs/conf.yaml"
  }

  provisioner "local-exec" {
    command = "kubectl apply -f manifests/"
  }
}
