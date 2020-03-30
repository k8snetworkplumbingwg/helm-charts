# helm-charts
Helm charts for deployment of NPWG implementations and ancillary tools

## Quick guide - Helm

Refer Helm [Quickstart Guide](https://helm.sh/docs/intro/quickstart/) and [Installation Guide](https://helm.sh/docs/intro/install/)

Helm charts are generally structured like an example below:
```
$ tree multus/
multus/
|-- charts
|-- Chart.yaml
|-- templates
|   |-- clusterRoleBinding.yaml
|   |-- clusterRole.yaml
|   |-- configMap.yaml
|   |-- customResourceDefinition.yaml
|   |-- daemonSet.yaml
|   |-- _helpers.tpl
|   |-- NOTES.txt
|   |-- serviceAccount.yaml
|-- values.yaml
```

Here,
The `templates/` directory is for template files. When Helm evaluates a chart, it will send all of the files in the templates/ directory through the template rendering engine. It then collects the results of those templates and sends them on to Kubernetes.

The `values.yaml` file is important to templates and contains the default values for a chart. These values may be overridden by users during helm install or helm upgrade.

The `Chart.yaml` file contains a description of the chart. You can access it from within a template. 

## Multus deployment using Helm Charts

### Prerequisites for Multus Deployment

* Kubelet configured to use CNI
* Charts have been tested with Kubernetes version >= 1.16
* Helm is deployed on the sever. Refer [installation guide](https://helm.sh/docs/intro/install/) for more details.
* Helm charts have been downloaded on server from [git repository](https://github.com/k8snetworkplumbingwg/helm-charts)

Your Kubelet(s) must be configured to run with the CNI network plugin. Please see [Kubernetes document for CNI](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/#cni) for more details.

### Installing Multus using Helm

To configure a helm chart, you need to configure some parameters as per your environment. To make such adjustments, please check `values.yaml`. The following configurations might need some adjustments based on your environment:
* Multus image parameters
```
image:
  registry: docker.io
  repository: nfvpe/multus
  tag: v3.4
  pullPolicy: IfNotPresent
```
* Node Selector Labels
```
labels:
  nodeSelector:
    kubernetes.io/arch: amd64
```
* Multus configuration parameters
```
config:
  cni_conf:
    name: multus-cni-network
    type: multus
    kubeconfig: /etc/cni/net.d/multus.d/multus.kubeconfig
    cniVersion: 0.3.1
    confDir: /etc/cni/net.d
    cniDir: /var/lib/cni/multus
    binDir: /opt/cni/bin
    logFile: /var/log/multus.log
    logLevel: panic
    capabilities:
      portMappings: true
    readinessindicatorfile: ""
    namespaceIsolation: false
    clusterNetwork: k8s-pod-network
    defaultNetwork: []
    delegates: []
    systemNamespaces: ["kube-system"]
```
* Multus pod resources
```
pod:
  resources:
    enabled: false
    multus:
      requests:
        memory: "128Mi"
        cpu: "250m"
      limits:
        memory: "1024Mi"
        cpu: "2000m"
```

Once the parameters are configured per the environment, you can install Multus helm chart with following steps:
```
$ cd helm-charts/
$ helm  install choice-unlimited ./multus
```

You can check your environment for appropriate deployment of Multus:
```
$ kubectl get all -A  | grep choice-unlimited
kube-system   pod/choice-unlimited-multus-ds-fxsl7                 1/1     Running   0          39h
kube-system   pod/choice-unlimited-multus-ds-qvcsj                 1/1     Running   0          39h
kube-system   daemonset.apps/choice-unlimited-multus-ds               2         2         2       2            2           kubernetes.io/arch=amd64      39h

$ kubectl get cm -A | grep choice-unlimited
kube-system   choice-unlimited-multus-0.1.0-config       1      39h

$ kubectl get crd | grep network-attachment
network-attachment-definitions.k8s.cni.cncf.io   2020-03-29T00:07:09Z
```
Ensure that these pods are in `running` state. One can additionally check forcreation of following files:
* /etc/cni/net.d/00-multus.cfg
* /etc/cni/net.d/multus.d/multus.kubeconfig
* /opt/cni/bin/multus
* files under /var/lib/cni/multus/
* log file created per path mentioned in configuration

At this stage, try creating a pod and you should be able to see the networking through using the default/clusterNetwork. One can now add other CNIs and enable the pods to be connected to those using network-attachment-defintions. An example is shown below for addition of SR-IOV CNI which shall also create SR-IOV CNI related network attachment defintions.

## SR-IOV CNI deployment using Helm Charts

### Prerequisites for SR-IOV CNI Deployment

* Kubelet configured to use CNI
* Charts have been tested with Kubernetes version >= 1.16
* Helm is deployed on the sever. Refer [installation guide](https://helm.sh/docs/intro/install/) for more details.
* Helm charts have been downloaded on server from [git repository](https://github.com/k8snetworkplumbingwg/helm-charts)
* Compute servers are configured for sriov configuration
* Virtual functions are configured on respective NIC cards and are bind with appropriate driver

Your Kubelet(s) must be configured to run with the CNI network plugin. Please see [Kubernetes document for CNI](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/#cni) for more details.

### Installing SR-IOV CNI using Helm

To configure a helm chart, you need to configure some parameters as per your environment. To make such adjustments, please check `values.yaml`. The following configurations might need some adjustments based on your environment:
* SR-IOV CNI image parameters
```
images:
  registry: docker.io
  sriovCni:
    repository: nfvpe/sriov-cni
    tag: v2.2
  sriovDevicePlugin:
    repository: nfvpe/sriov-device-plugin
    tag: v3.1
  pullPolicy: IfNotPresent
```
* Node selector labels
```
labels:
  nodeSelector:
    kubernetes.io/arch: amd64
```
* Configuration with apprrpriate resource list. The code herein assumes that the virtual functions 8-31 on interfaces enp67s0f0 and enp68s0f0 are bind with VFIO driver. 
```
config:
  scMountPaths:
    cnibin: "/host/opt/cni/bin"
  sdpMountPaths:
    deviceSock: "/var/lib/kubelet/device-plugins/"
    log: "/var/log"
    configVolume: "/etc/pcidp/config.json"
  sriov_device_plugin:
    resourceList:
    - resourceName: intel_sriov_netdevice
      selectors:
        vendors:
        - '8086'
        devices:
        - 154c
        - 10ed
        drivers:
        - i40evf
        - ixgbevf
    - resourceName: intel_sriov_dpdk
      selectors:
        vendors:
        - '8086'
        devices:
        - 154c
        - 10ed
        drivers:
        - vfio-pci
        pfNames:
        - enp67s0f1#8-31
        - enp68s0f0#8-31
```
* Creation fo appropriate charts
```
manifests:
  serviceAccount: true
  configMap_sriov_device_plugin: true
  daemonSet_sriov_device_plugin: true
  daemonSet_sriov_cni: true
  net_attach_def_netdev: true
  net_attach_def_dpdk: true
  test_netdevice: true
  test_dpdk: true
```
On can disable the creation of network attachment definitions and test pods by setting value `false` in configuration above. At this stage, you can create more network-attachment-definitions and pods for SR-IOV according to your environment.

So far, we have seen the deployment of Multus and SR-IOV CNI using helm charts. Post deployment of each of these charts, the output shows the components deployed as part of helm deployment. It also states the steps to uninstall the helm charts in the environment.
