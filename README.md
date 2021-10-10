Docker与K8S学习笔记。

## 运行命令
```bash
ansible-playbook -i hosts xxx.yml
```
其中xxx是需要执行的yml文件名。



## 安装注意事项

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

### 集群规划

| IP         | 节点               |  节点  | docker | proxy | etcd |
| ---------- | ------------------ | :----: | :----: | :---: | :--: |
| 10.4.7.11  | hdss7-11.host.com  | master |        |   Y   |      |
| 10.4.7.12  | hdss7-12.host.com  |        |        |   Y   |  Y   |
| 10.4.7.21  | hdss7-21.host.com  |  node  |   Y    |       |  Y   |
| 10.4.7.22  | hdss7-22.host.com  |  node  |   Y    |       |  Y   |
| 10.4.7.200 | hdss7-200.host.com |        |   Y    |       |      |

### 配置hosts文件

```text
[nodes]
node01 ansible_ssh_user="root" ansible_ssh_host=10.4.7.11 ansible_ssh_port=22 ansible_ssh_pass="1"
node02 ansible_ssh_user="root" ansible_ssh_host=10.4.7.12 ansible_ssh_port=22 ansible_ssh_pass="1"
node03 ansible_ssh_user="root" ansible_ssh_host=10.4.7.21 ansible_ssh_port=22 ansible_ssh_pass="1"
node04 ansible_ssh_user="root" ansible_ssh_host=10.4.7.22 ansible_ssh_port=22 ansible_ssh_pass="1"
node05 ansible_ssh_user="root" ansible_ssh_host=10.4.7.200 ansible_ssh_port=22 ansible_ssh_pass="1"

[11]
node01 ansible_ssh_user="root" ansible_ssh_host=10.4.7.11 ansible_ssh_port=22 ansible_ssh_pass="1"

[12]
node02 ansible_ssh_user="root" ansible_ssh_host=10.4.7.12 ansible_ssh_port=22 ansible_ssh_pass="1"

[21]
node03 ansible_ssh_user="root" ansible_ssh_host=10.4.7.21 ansible_ssh_port=22 ansible_ssh_pass="1"

[22]
node04 ansible_ssh_user="root" ansible_ssh_host=10.4.7.22 ansible_ssh_port=22 ansible_ssh_pass="1"

[200]
node05 ansible_ssh_user="root" ansible_ssh_host=10.4.7.200 ansible_ssh_port=22 ansible_ssh_pass="1"

[docker]
node03 ansible_ssh_user="root" ansible_ssh_host=10.4.7.21 ansible_ssh_port=22 ansible_ssh_pass="1"
node04 ansible_ssh_user="root" ansible_ssh_host=10.4.7.22 ansible_ssh_port=22 ansible_ssh_pass="1"
node05 ansible_ssh_user="root" ansible_ssh_host=10.4.7.200 ansible_ssh_port=22 ansible_ssh_pass="1"
```

> 中括号 `[]` 中的内容可以理解为别名，可以在ansible playbook中使用`'11'`来表示是`10.4.7.11`那台主机，使用`nodes`来表示所有主机。



### 修改宿主机DNS

建议在安装部署好harbor之后，再修改DNS为`10.4.7.11`，然后就可以通过宿主机访问harbor页面。



## harbor页面配置

访问`harbor.od.com`页面，输入账户密码，新建项目，项目名为**public**。

> 默认账号: admin 密码: Harbor12345
>
> 账号密码可在`/opt/harbor/harbor.yml`去修改

![](https://borinboy.oss-cn-shanghai.aliyuncs.com/huan/20211009221842.png)

