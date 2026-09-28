# Purpose

This will be me documenting my learning process for Kubernetes

## What is Kubernetes?

Kubernetes is an open-source platform to manage your containers and services. It supports declarative configuration (YAML configs) and automation.
So Kubernetes use cases would be:

- Management of scaling and failure of your distributed system
- Manage a canary deployment of a system
- Automated rollouts/rollbacks, by describing a desired state, which k8s then veers to in increments
- Storage orchestration, either local or public storage mountain
- Self-healing is done via automated defined health-checks, it will restart/kill containers that dont pass them, and not view them as ready till they pass.
- Secret management such as OAuth  keys, ssh keys, passwords can be deployed and updated without rebuilding container images or exposing the secrets.
- Automatic scaling via methods such as UI, commands, or based on usage. The scaling is Horizontal.
- IPv4/6 allocation to pods and services


## Components

Kubernetes is made up of components, a control pane, and worker node(s).

### Control Pane

Manages the cluster state and contains the following:

- kube-apiserver exposes the Kubernetes HTTP API
- etcd is consistent and highly-available key value storage for all API server data
- kube-scheduler assigns not yet bound pods to suitable nodes after searching for them
- kube-controller-mangager in charge of [controllers](controllers.md) to implement kubernetes API behavior
- cloud-controller-manager is in charge of integrating with cloud provider(s) such as AWS, GCP, Azure..

### Node

A node conists of: 
- Kubelets: Ensures that pods are running, alongside their containers
- kube-proxy: maintains network rules on nodes to implement Services
- Runtime: Software which runs the container


### Objects

Objects are persistent entities in the system, they represent our current cluster state. They describe applications that are running and their respective nodes, the resources available, and the policies governing them.
An object is a "record of intent", meaning that its creation tells kubernetes adesired state, and k8s will work relentlessly to ensure that this object exists. The object descibres what the workload should look like.

Objects are handled via the API, which you call via `kubectl`.

Objects have two nested fields, a `spec` and a `status` that govern its configuration. 

A `spec` has to be set when the object is created, which describes the desired state of the object.
A `status` describes the current status of the object, which gets updated by the kubernetes environment and components.
The control plane manages the states of objects to get them to their desired states.


#### Example 
A deployment can be an object, which represents an application running in a cluster. The deployment `spec` can specify that we want 3 instances of the application running on the cluster. So the system starts the replicas, updates the status to match spec, and continually monitors, if one fails and doesnt match spec anymore, it tries to fix it by e.g. restarting a replica.

The object spec is defined in YAML language.

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 2 # tells deployment to run 2 pods matching the template
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80


```
The yaml has these required fields:
- apiVersion: Kubernetes api version used to create the object
- kind: the kind of object we want to create
- metadata: has fields such as name or namepsace, that uniquely identify this object
- spec: the desired state of the object

These are applied with the command `kubectl apply`  kubectl apply -f spec.yaml
We use `--validate` in order to perform server-side field validation on the YAML, with options of `ignore`, `warn`, and `strict` 
