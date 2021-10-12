Docker与K8S学习笔记。

## 运行命令
```bash
ansible-playbook -i hosts xxx.yml
```
其中xxx是需要执行的yml文件名。



## 安装注意事项

### 关于项目

由于这是一个k8s和ansible相结合的学习项目，大部分配置都是写死在脚本文件中，如果需要自定义配置，请自行按需修改，谢谢！

### 关于一键部署

如果**不需要**测试将自己打包的镜像推送到harbor中，可以全程一键部署。

~~在实践中发现在后期还是有需要用到自建harbor仓库的地方，因此还不能实现一键部署。~~

关于一键部署的问题，在昨晚回家之后突发奇想，如果我们不用自建harbor仓库的镜像，而是用官方镜像（`docker.io/kubernetes/pause:latest`），是不是就可实现一键部署？

#### 一键部署脚本

进入到k8s项目目录下，执行命令

```
sh install.sh
```



### 关于playbook

这不是一个优雅的ansible playbook项目，原因如下：

* 需要手动进入页面去进行操作，再执行后续命令。
* 其次是由于内功不足，某些操作也不够优雅。

**有强烈的代码洁癖的请跳过，以免引起不适。**

**或者也可以提issue告知修改建议，不胜感激！**

### 关于注释

在yml文件中有许多被注释的内容，需要注意的是，因为是边运行边测，因此是注释已经运行过的命令，再运行新的命令。

如果看到注释的`#`是两个或以上的，说明是不需要运行的内容，但可以参考。

### 关于集群规划

| IP         | 节点               |  节点  | docker | proxy | etcd |
| ---------- | ------------------ | :----: | :----: | :---: | :--: |
| 10.4.7.11  | hdss7-11.host.com  | master |        |   Y   |      |
| 10.4.7.12  | hdss7-12.host.com  |        |        |   Y   |  Y   |
| 10.4.7.21  | hdss7-21.host.com  |  node  |   Y    |       |  Y   |
| 10.4.7.22  | hdss7-22.host.com  |  node  |   Y    |       |  Y   |
| 10.4.7.200 | hdss7-200.host.com |        |   Y    |       |      |

### 关于hosts文件

```text
[nodes]
node01 ansible_ssh_user="root" ansible_ssh_host=10.4.7.11 ansible_ssh_port=22 ansible_ssh_pass="1"
node02 ansible_ssh_user="root" ansible_ssh_host=10.4.7.12 ansible_ssh_port=22 ansible_ssh_pass="1"
node03 ansible_ssh_user="root" ansible_ssh_host=10.4.7.21 ansible_ssh_port=22 ansible_ssh_pass="1"
node04 ansible_ssh_user="root" ansible_ssh_host=10.4.7.22 ansible_ssh_port=22 ansible_ssh_pass="1"
node05 ansible_ssh_user="root" ansible_ssh_host=10.4.7.200 ansible_ssh_port=22 ansible_ssh_pass="1"

[11]
node01

[12]
node02

[21]
node03

[22]
node04

[200]
node05

```

> 中括号 `[]` 中的内容可以理解为别名，可以在ansible playbook中使用`'11'`来表示是`10.4.7.11`那台主机，使用`nodes`来表示所有主机。



### 关于高版本k8s

在k8s资源清单中，有如下区别：

apiVersion

* 低版本：可以用`apiVersion: extensions/v1beta1`
* 高版本：需要改成`apiVersion: apps/v1`

selector：

* 低版本：可以不用加
* 高版本：必须加上`selector`



#### 新老版本资源清单对比

**老版本**

```yaml
apiVersion: extensions/v1beta1
kind: DaemonSet
metadata:
  name: nginx-ds
spec:
  template:
    metadata:
      labels:
        app: nginx-ds
    spec:
      containers:
      - name: my-nginx
        image: harbor.od.com/public/nginx:v1.7.9
        ports:
        - containerPort: 80
```

**新版本**

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: nginx-ds
spec:
  selector:
    matchLabels:
      app: nginx-ds
  template:
    metadata:
      labels:
        app: nginx-ds
    spec:
      containers:
      - name: my-nginx
        image: harbor.od.com/public/nginx:v1.7.9
        ports:
        - containerPort: 80
```



### 修改宿主机DNS

建议在安装部署好harbor之后，再修改DNS为`10.4.7.11`，然后就可以通过宿主机访问harbor页面。

修改完宿主机的DNS之后，如果由于从公司到家切换网络，可能造成ansible连接被控机器缓慢，或访问网页缓慢，可以尝试在DNS中添加DNS地址：

```
223.5.5.5
8.8.8.8
114.114.114.144
```

或者可以删除`10.4.7.11`以外的DNS信息并保存之后，马上再重新添加回去，网络即可恢复异常。如还是未能正常，请自行搜索资料排查解决。

## harbor页面配置

访问`harbor.od.com`页面，输入账户密码，新建项目，项目名为**public**。

> 默认账号: admin 密码: Harbor12345
>
> 账号密码可在`/opt/harbor/harbor.yml`去修改

![](https://borinboy.oss-cn-shanghai.aliyuncs.com/huan/20211009221842.png)



## 其他详解

### keepalived

从节点中check_port.sh文件中：

```
! Configuration File for keepalived

vrrp_instance VI_1 {
    state MASTER
    interface eth0
    virtual_router_id 251
    priority 100
    advert_int 1
    mcast_src_ip 10.4.7.11
    nopreempt
}
```

nopreempt：非抢占式，避免因为网络抖动导致节点漂移，当主节点恢复正常以后，vip再次回到主节点。

如果因各种原因，导致主节点漂移到从节点，需要手动将vip节点切换到主节点的时候，**需要万分小心！！！**

**恢复主节点操作顺序**

1. 先确认从节点keepalived及nginx存活（如果都挂了当我没说）

2. 启动主节点的nginx

    ```
    systemctl start nginx
    ```

3. 多方多人确认，确保7443端口存活

    ```
    netstat -lntp | grep 7443
    ```

4. 重启==**主**==节点的keepalived

    ```
    systemctl restart keepalived
    ```

5. 重启==**从**==节点的keepalived

    ```
    systemctl restart keepalived
    ```



### kube-controller-manager

```sh
#!/bin/sh
./kube-scheduler \
  --leader-elect  \
  --log-dir /data/logs/kubernetes/kube-scheduler \
  # 这里采用http协议，因此不需要证书，而主控节点应该是一个整体，因此它们也是没有用tls证书的。
  # 如果主控在不同的机器上，则需要部署证书
  --master http://127.0.0.1:8080 \
  --v 2
```



### kubelet

签发证书时，可以将没有的节点添加进`hosts`中，避免以后增加节点时，需要将已存在节点添加到hosts中，然后手撕证书命令，重新签发证书。

```json
{
    "CN": "k8s-kubelet",
    "hosts": [
    "127.0.0.1",
    "10.4.7.10",
    "10.4.7.21",
    "10.4.7.22",
    "10.4.7.23",
     "xxx.xxx.xxx.xxx"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "ST": "beijing",
            "L": "beijing",
            "O": "od",
            "OU": "ops"
        }
    ]
}
```



### K8S用户体系简介

k8s用户分为普通用户和服务用户，普通用户和server通信的时候会有一个接入点，而这个接入点就是这个"VIP"（10.4.7.10:7443）。
kubelet不能只找自己的接入点，万一自己的接入点挂了，就没法搞了。
如果是接入到vip server，kubelet汇报给vip server，vip server再发送给APIserver，告诉apiserver我的状态是什么，和APIserver通信。

### k8s-node.yml
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: k8s-node
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:node
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: k8s-node
```
* rbac也是一种资源
* roleRef：集群角色绑定
  * name: 集群角色叫node

### LVS调度算法
网上搜索相关文档

```yaml
- hosts: kube-proxy
  user: root
  tasks:
    - name: 安装ipvsadm
      shell: yum install -y ipvsadm

    - name: 使用ipvsadm查看路由
      shell: ipvsadm -Ln
      
    - name: 查看svc
      shell: kubectl get svc
```



## 集群验证

在7-21机器上，使用ansible-playbook命令来执行脚本。

```yaml
---
- hosts: '21'
  user: root
  tasks:
    - name: 配置验证集群的yaml文件
      copy:
        src: packages/root/nginx-ds.yaml
        dest: /root/nginx-ds.yaml
        mode: 0644

    - name: kubectl create -f nginx-ds.yaml
      shell: kubectl create -f /root/nginx-ds.yaml

    - name: kubectl get pods
      shell: kubectl get pods

    - name: kubectl get cs
      shell: kubectl get cs

    - name: kubectl get node
      shell: kubectl get node
```

也可以手动执行命令

```
[root@hdss7-21 ~]# kubectl get pods
NAME             READY   STATUS              RESTARTS   AGE
nginx-ds-8m278   0/1     ContainerCreating   0          15m

[root@hdss7-21 ~]# kubectl get cs
NAME                 STATUS    MESSAGE              ERROR
controller-manager   Healthy   ok
scheduler            Healthy   ok
etcd-1               Healthy   {"health": "true"}
etcd-0               Healthy   {"health": "true"}
etcd-2               Healthy   {"health": "true"}

[root@hdss7-21 ~]# kubectl get node
NAME                STATUS   ROLES         AGE    VERSION
hdss7-21.host.com   Ready    master,node   152m   v1.17.2
hdss7-22.host.com   Ready    master,node   152m   v1.17.2
```

