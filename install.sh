#!/bin/sh
ansible-playbook -i hosts 01_init.yml
ansible-playbook -i hosts 02_install_harbor.yml
ansible-playbook -i hosts 04_install_etcd.yml
ansible-playbook -i hosts 05_install_kube_apiserver.yml
ansible-playbook -i hosts 06_install_master_proxy.yml
ansible-playbook -i hosts 07_install_kube_related.yml
ansible-playbook -i hosts 08_install_kubelet.yml
ansible-playbook -i hosts 09_install_kube_proxy.yml
ansible-playbook -i hosts 10_check_cluster.yml
