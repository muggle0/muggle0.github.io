---
title: k8s-kubesphere
date: 2022-09-19 23:33:14
tags:
---

## KubeSphere 介绍

KubeSphere是k8s控制台，ubeSphere 目前提供了工作负载管理、微服务治理、DevOps 工程、Source to Image、多租户管理、多维度监控、日志查询与收集、告警通知、服务与网络、应用管理、基础设施管理、镜像管理、应用配置密钥管理等功能模块。

kubeSphere 帮我们把诸多云原生功能集中在一起并提供了web界面。利用KubeSphere我们可以根据我们之前学习的 Jenkins docker k8s 搭建一套完整的私有云系统，极大的减少运维以及开发的工作量。具体的搭建思路我在下一节中给出，这一节我们先安装并使用KubeSphere。

## kubeSphere 安装

为了简化安装，我们这里使用的是KubeKey，KubeKey安装k8s的最低配置要求是2核4G，低于这个配置使用KubeKey会安装失败。由于KubeKey会访问github。所以需要保证你的主机能联网。我们本地实验的方式可以使用前文提到过的vagrant搭建虚拟机集群。然后在vagrant中安装。也可以在云上上实验，云上实验采用按量计费的方式，阿里云收费如下，网络带宽另计费
![image.png](images/kube-1.png)
腾讯云的：
![image.png](images/kube-2.png)
腾讯云的服务器要便宜很多，而且阿里云要使用按量计费需要余额大于100 元，腾讯云没有这个限制，不过两家都支持余额提现。做云实验的话我建议使用腾讯云的按量计费服务器，100块钱能玩很久（它的对象存储也只要几毛钱一个月）。
阿里云和腾讯云都推出了轻量级云服务器，比普通云服务器便宜很多，这种服务器是你用多少给你分配多少，比如我买了2核4g的服务器，如果我只用了1核1g，那剩余的资源就会被系统分配出去。这种服务器做实验体验不是很好，所以没考虑，感兴趣的小伙伴可以试试这种服务器。
为了偷个懒，这次我们实验就是在腾讯云上进行（主要是本地机器网络不太好）。
执行命令：

```
export KKZONE=cn

curl -sfL https://get-kk.kubesphere.io | VERSION=v2.2.2 sh -
```

![image.png](images/kube-3.png)
为 kk 添加可执行权限，并初始化本地主机：

```
chmod +x kk
./kk init os
```

![image.png](https://cdn.nlark.com/yuque/0/2022/png/22548376/1663205816318-d423f602-f49e-4127-97cc-1c03c9e61b42.png#clientId=u1e478135-eafe-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=58&id=u8c094f61&margin=%5Bobject%20Object%5D&name=image.png&originHeight=58&originWidth=497&originalType=binary&ratio=1&rotation=0&showTitle=false&size=6308&status=done&style=none&taskId=ub5f09e45-f428-4ab4-8191-5534990410c&title=&width=497)
接下来我们生成一个配置文件来安装k8s和kubeSphere

```
./kk create config [--with-kubernetes version] [--with-kubesphere version] [(-f | --file) path]
```

示例：

```
## 使用默认配置创建示例配置文件
./kk create config
## 指定要安装的 KubeSphere 版本
./kk create config --with-kubesphere v3.3.0
./kk create config --with-kubernetes v1.22.10 --with-kubesphere v3.3.0
```

![image.png](https://cdn.nlark.com/yuque/0/2022/png/22548376/1663221894511-ddd043ca-8038-4967-81c7-2ba813fd409b.png#clientId=u1e478135-eafe-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=70&id=u839d9e1b&margin=%5Bobject%20Object%5D&name=image.png&originHeight=70&originWidth=676&originalType=binary&ratio=1&rotation=0&showTitle=false&size=6163&status=done&style=none&taskId=ua58d0df5-61fc-4eb8-b6ac-5b7e04b21a8&title=&width=676)
这里建议指定版本号，因为有的机器会不支持安装高版本kubeSphere，指定版本生成配置文件会有对应提示。
![image.png](https://cdn.nlark.com/yuque/0/2022/png/22548376/1663224867706-e5a29273-1b42-4263-86fe-125b7f25b322.png#clientId=u1e478135-eafe-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=44&id=ude675e6a&margin=%5Bobject%20Object%5D&name=image.png&originHeight=44&originWidth=901&originalType=binary&ratio=1&rotation=0&showTitle=false&size=4424&status=done&style=none&taskId=udfc5e54c-5507-4615-98ac-92cec648aba&title=&width=901)
config-sample.yaml示例：

```
apiVersion: kubekey.kubesphere.io/v1alpha2
kind: Cluster
metadata:
  name: sample
spec:
  hosts:
  - {name: node1, address: 192.168.221.128, internalAddress: 192.168.221.128, user: root, password: "root"}
  roleGroups:
    etcd:
    - node1
    control-plane: 
    - node1
    worker:
    - node1
  controlPlaneEndpoint:
    ## Internal loadbalancer for apiservers 
    # internalLoadbalancer: haproxy

    domain: lb.kubesphere.local
    address: ""
    port: 6443
  kubernetes:
    version: v1.18.6
    clusterName: cluster.local
  network:
    plugin: calico
    kubePodsCIDR: 10.233.64.0/18
    kubeServiceCIDR: 10.233.0.0/18
    ## multus support. https://github.com/k8snetworkplumbingwg/multus-cni
    multusCNI:
      enabled: false
  registry:
    plainHTTP: false
    privateRegistry: ""
    namespaceOverride: ""
    registryMirrors: []
    insecureRegistries: []
  addons: []


---
apiVersion: installer.kubesphere.io/v1alpha1
kind: ClusterConfiguration
metadata:
  name: ks-installer
  namespace: kubesphere-system
  labels:
    version: v3.0.0
spec:
  zone: ""
  local_registry: ""
  persistence:
    storageClass: ""
  authentication:
    jwtSecret: ""
  etcd:
    monitoring: true
    endpointIps: localhost
    port: 2379
    tlsEnable: true
  common:
    es:
      elasticsearchDataVolumeSize: 20Gi
      elasticsearchMasterVolumeSize: 4Gi
      elkPrefix: logstash
      logMaxAge: 7
    mysqlVolumeSize: 20Gi
    minioVolumeSize: 20Gi
    etcdVolumeSize: 20Gi
    openldapVolumeSize: 2Gi
    redisVolumSize: 2Gi
  console:
    enableMultiLogin: false  # enable/disable multi login
    port: 30880
  alerting:
    enabled: false
  auditing:
    enabled: false
  devops:
    enabled: false
    jenkinsMemoryLim: 2Gi
    jenkinsMemoryReq: 1500Mi
    jenkinsVolumeSize: 8Gi
    jenkinsJavaOpts_Xms: 512m
    jenkinsJavaOpts_Xmx: 512m
    jenkinsJavaOpts_MaxRAM: 2g
  events:
    enabled: false
    ruler:
      enabled: true
      replicas: 2
  logging:
    enabled: false
    logsidecarReplicas: 2
  metrics_server:
    enabled: true
  monitoring:
    prometheusMemoryRequest: 400Mi
    prometheusVolumeSize: 20Gi
  multicluster:
    clusterRole: none  # host | member | none
  networkpolicy:
    enabled: false
  notification:
    enabled: false
  openpitrix:
    enabled: false
  servicemesh:
    enabled: false
```

安装前配置：

```
## 指定服务器hostname
hostnamectl set-hostname master
## 关闭防火墙:
systemctl disable firewalld
## 关闭selinux:  (临时关闭 setenforce 0)
sed -i 's/enforcing/disabled/' /etc/selinux/config
## 关闭swap(临时关闭swapoff -a)
sed -ri 's/.*swap.*/#&/' /etc/fstab 

## 同步时间
yum install ntpdate -y
ntpdate time.windows.com
```

执行命令创建集群：

```
./kk create cluster -f config-sample.yaml
## 或者直接单机安装
./kk create cluster --with-kubesphere v3.0.0
```

![image.png](https://cdn.nlark.com/yuque/0/2022/png/22548376/1663222331249-a6d8f947-c0c8-4a13-b1b9-3add4fd8282f.png#clientId=u1e478135-eafe-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=586&id=u908ed8f4&margin=%5Bobject%20Object%5D&name=image.png&originHeight=586&originWidth=1146&originalType=binary&ratio=1&rotation=0&showTitle=false&size=25637&status=done&style=none&taskId=u66c2ce3d-c239-405f-815b-1e345dd4ef2&title=&width=1146)
安装过程比较耗时，中途可能出现安装失败的情况，可以使用该命令卸载再进行重装：

```
./kk delete cluster 
```

安装成功后会有如下日志：
安装完成后执行指令：

```
 kubectl get pod -A
```

![image.png](https://cdn.nlark.com/yuque/0/2022/png/22548376/1663222971174-02a1bd8e-cbb6-4e1b-b49b-a2bbaa552da4.png#clientId=u1e478135-eafe-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=365&id=uc0cf7a59&margin=%5Bobject%20Object%5D&name=image.png&originHeight=365&originWidth=843&originalType=binary&ratio=1&rotation=0&showTitle=false&size=30435&status=done&style=none&taskId=ue37e84f4-93e0-4151-b8fd-52939cdb2a0&title=&width=843)
根据日志访问网页：
![image.png](https://cdn.nlark.com/yuque/0/2022/png/22548376/1663559378158-10e6b3fd-4855-49d0-8dab-7934b66578e0.png#clientId=u4bc37523-6d99-4&crop=0&crop=0&crop=1&crop=1&from=paste&id=u7f025167&margin=%5Bobject%20Object%5D&name=image.png&originHeight=460&originWidth=496&originalType=url&ratio=1&rotation=0&showTitle=false&size=324028&status=done&style=none&taskId=u6426e325-5d05-4fa8-9dc2-4242a67afc2&title=)
![image.png](https://cdn.nlark.com/yuque/0/2022/png/22548376/1663559409610-621c903d-3059-4cd7-b8a2-a7ddf16ce4b1.png#clientId=u4bc37523-6d99-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=220&id=uc844787e&margin=%5Bobject%20Object%5D&name=image.png&originHeight=220&originWidth=1899&originalType=binary&ratio=1&rotation=0&showTitle=false&size=54723&status=done&style=none&taskId=u869ea835-03dc-43be-b91d-a7e171904ef&title=&width=1899)

## kubekey 指令

- 添加节点

kk add nodes -f config-sample.yaml

-  删除节点

kk delete node <nodeName> -f config-sample.yaml

- 删除集群

kk delete cluster
kk delete cluster [-f config-sample.yaml]

- 集群升级

kk upgrade [--with-kubernetes version] [--with-kubesphere version]
kk upgrade [--with-kubernetes version] [--with-kubesphere version] [(-f | --file) path]

## kubesphere 功能介绍

1）Kubernetes 资源管理
支持工作负载管理、镜像管理、服务与应用路由管理 (服务发现)、密钥配置管理等
![image.png](https://cdn.nlark.com/yuque/0/2022/png/22548376/1663559863676-11a27819-f37f-4df1-b8d0-c681c3cb3553.png#clientId=u4bc37523-6d99-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=545&id=uea4d4dab&margin=%5Bobject%20Object%5D&name=image.png&originHeight=545&originWidth=1402&originalType=binary&ratio=1&rotation=0&showTitle=false&size=74909&status=done&style=none&taskId=u2485654e-133b-47bf-8fc5-f825a9afae9&title=&width=1402)
2）微服务治理

- 支持熔断、灰度发布、流量管控、限流、链路追踪、智能路由等完善的微服务治理功能，同时，支持代码无侵入的微服务治理

![image.png](https://cdn.nlark.com/yuque/0/2022/png/22548376/1663559941567-5be18801-dd62-49b5-b067-50df1c9b0abf.png#clientId=u4bc37523-6d99-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=810&id=u0991e854&margin=%5Bobject%20Object%5D&name=image.png&originHeight=810&originWidth=1377&originalType=binary&ratio=1&rotation=0&showTitle=false&size=149783&status=done&style=none&taskId=uda39f509-d935-4064-afce-786c74d319f&title=&width=1377)
3）DevOps
基于 Jenkins 的可视化 CI / CD 流水线，支持从仓库 (GitHub / SVN / Git)、代码编译、镜像制作、镜像安全、推送仓库、版本发布、到定时构建的端到端流水线设置
![image.png](https://cdn.nlark.com/yuque/0/2022/png/22548376/1663565422814-637ba193-be9f-48ea-9439-0c6eaf7bdb70.png#clientId=u4bc37523-6d99-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=493&id=ua1c2b7e2&margin=%5Bobject%20Object%5D&name=image.png&originHeight=493&originWidth=1461&originalType=binary&ratio=1&rotation=0&showTitle=false&size=176602&status=done&style=none&taskId=uca53a9a1-1002-450d-997b-9b4eca71dce&title=&width=1461)
4）监控
![image.png](https://cdn.nlark.com/yuque/0/2022/png/22548376/1663565534605-f8012570-d85a-40b8-83af-1fb848470936.png#clientId=u4bc37523-6d99-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=508&id=u1d379133&margin=%5Bobject%20Object%5D&name=image.png&originHeight=508&originWidth=1000&originalType=binary&ratio=1&rotation=0&showTitle=false&size=107283&status=done&style=none&taskId=u5645c0ad-cd8e-4f2f-9768-e227d7ff46e&title=&width=1000)
5）应用管理与编排
使用开源的OpenPitrix提供应用商店和应用仓库服务，提供应用全生命周期管理功能
![image.png](https://cdn.nlark.com/yuque/0/2022/png/22548376/1663565755876-d0038659-1123-47c8-900f-c2e2ef283179.png#clientId=u4bc37523-6d99-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=840&id=u59522995&margin=%5Bobject%20Object%5D&name=image.png&originHeight=840&originWidth=1229&originalType=binary&ratio=1&rotation=0&showTitle=false&size=174048&status=done&style=none&taskId=u04297f58-8fdf-45ac-974e-daaac9258bb&title=&width=1229)

## 结语

k8s系列在这一篇算是终结了，下一篇会写普罗米修斯相关的文章，然后之后按照计划就是写我的 poseidon 项目了，目前对自己的要求就是一周一更新。

