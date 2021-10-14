#!/bin/sh
harbor_path="packages/src/harbor-offline-installer-v2.2.2.tgz"
# 这里的-f参数判断$myFile是否存在
echo "检查$harbor_path 是否存在"
if [ ! -f "$harbor_path" ]; then
echo "$harbor_path 不存在，请手动下载"
exit 1
fi

k8s_path="packages/src/kubernetes-server-linux-amd64-v1.17.2.tar.gz"
# 这里的-f参数判断$myFile是否存在
echo "检查$k8s_path 是否存在"
if [ ! -f "$k8s_path" ]; then
echo "$k8s_path  不存在，请手动下载"
exit 1
fi

echo "ansible-playbook -i 00_init.yml"
ansible-playbook -i hosts 00_init.yml

echo "重启机器中，需要等待一分钟"
sleep 60
echo "机器重启完成"

echo "ansible-playbook -i hosts 01_install_bind_docker.yml"
ansible-playbook -i hosts 01_install_bind_docker.yml

echo "ansible-playbook -i hosts 02_install_harbor.yml"
ansible-playbook -i hosts 02_install_harbor.yml

echo "ansible-playbook -i hosts 04_install_etcd.yml"
ansible-playbook -i hosts 04_install_etcd.yml

echo "ansible-playbook -i hosts 05_install_kube_apiserver.yml"
ansible-playbook -i hosts 05_install_kube_apiserver.yml

echo "ansible-playbook -i hosts 06_install_master_proxy.yml"
ansible-playbook -i hosts 06_install_master_proxy.yml

echo "ansible-playbook -i hosts 07_install_kube_related.yml"
ansible-playbook -i hosts 07_install_kube_related.yml

echo "ansible-playbook -i hosts 08_install_kubelet.yml"
ansible-playbook -i hosts 08_install_kubelet.yml

echo "ansible-playbook -i hosts 09_install_kube_proxy.yml"
ansible-playbook -i hosts 09_install_kube_proxy.yml

echo "ansible-playbook -i hosts 10_check_cluster.yml -vvv"
ansible-playbook -i hosts 10_check_cluster.yml -vvv
