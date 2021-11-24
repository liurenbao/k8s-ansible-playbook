## 项目简介

这是一个k8s和ansible相结合的学习项目，使用ansible在**centos服务器**上一键部署K8S高可用集群。

## 项目部署

进入到k8s项目目录下，执行命令：

```
sh install.sh
```

## 环境准备

> 这是在执行主机上需要执行的操作。
>
> 不提供Windows版本，如有需求，请自行解决环境问题。

**macOS**

```bash
brew install ansible
```

> 如果macOS没有安装brew，请自行安装brew并设置国内源。

**CentOS**

```
yum install -y epal-release
yum install -y ansible
```

**Ubuntu\Debian（未验证）**

```
sudo apt-get install software-properties-common
sudo apt-add-repository ppa:ansible/ansible
sudo apt-get update
sudo apt-get install ansible
```

关闭ssh登录前输入确认

```
echo "host_key_checking = False" >> /etc/ansible/ansible.cfg
```

修改`group_vars/all.yml`文件，将下面的内容替换成你自己的节点的IP，**只需改IP，其他不能改**。

```
---
# macOS
# root_path: /Users/liuhuan

# Linux
# root_path: /root

node11: 10.4.7.11
node12: 10.4.7.12
node21: 10.4.7.21
node22: 10.4.7.22
node200: 10.4.7.200
gateway: 10.4.7.2

virtual_ipaddress: 10.4.7.10
```

**virtual_ipaddress**：是keepalived中的虚拟IP，不能和内网其他机器的IP地址冲突（重复）。

## 安装注意事项

### 关于安装包

由于某种不可描述的原因，下载某些包无法下载，因此需要手动下载到`/opt/src`目录下。

```
wget https://github.com/goharbor/harbor/releases/download/v2.2.2/harbor-offline-installer-v2.2.2.tgz
wget https://github.com/etcd-io/etcd/releases/download/v3.1.20/etcd-v3.1.20-linux-amd64.tar.gz
wget https://dl.k8s.io/v1.17.2/kubernetes-server-linux-amd64.tar.gz
wget https://github.com/flannel-io/flannel/releases/download/v0.11.0/flannel-v0.11.0-linux-amd64.tar.gz
```

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
hdss7-11 ansible_ssh_user="root" ansible_ssh_host="{{ node11 }}" ansible_ssh_port=22 ansible_ssh_pass="1"
hdss7-12 ansible_ssh_user="root" ansible_ssh_host="{{ node12 }}" ansible_ssh_port=22 ansible_ssh_pass="1"
hdss7-21 ansible_ssh_user="root" ansible_ssh_host="{{ node21 }}" ansible_ssh_port=22 ansible_ssh_pass="1"
hdss7-22 ansible_ssh_user="root" ansible_ssh_host="{{ node22 }}" ansible_ssh_port=22 ansible_ssh_pass="1"
hdss7-200 ansible_ssh_user="root" ansible_ssh_host="{{ node200 }}" ansible_ssh_port=22 ansible_ssh_pass="1"

[11]
hdss7-11

```

> 中括号 `[]` 中的内容可以理解为别名，可以在ansible playbook中使用`'11'`来表示是`10.4.7.11`那台主机，使用`nodes`来表示所有主机。

### 关于注释

在yml文件中有许多被注释的内容，需要注意的是，因为是边运行边测，因此是注释已经运行过的命令，再运行新的命令。

如果看到注释的`#`是两个或以上的，说明是不需要运行的内容，但可以参考。

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

### 关于DNS

由于是测试和学习环境，因此可以用`10.4.7.200:1800`来访问harbor页面，在服务器节点之间只要能解析到harbor.od.com即可。

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


