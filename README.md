# k8s

Docker与K8S学习笔记。

## 注意事项

需要修改本地的或者ansible所在机器的/etc/ansible/hosts中的配置文件信息
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
```

> 中括号 `[]` 中的内容可以理解为别名，可以在ansible playbook中使用`'11'`来表示是`10.4.7.11`那台主机，使用`nodes`来表示所有主机。

