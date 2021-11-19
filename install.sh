#!/bin/sh
#harbor_path="packages/src/harbor-offline-installer-v2.2.2.tgz"
## 这里的-f参数判断$myFile是否存在
#echo "检查$harbor_path 是否存在"
#if [ ! -f "$harbor_path" ]; then
#echo "$harbor_path 不存在，请手动下载"
#exit 1
#fi
#
#k8s_path="packages/src/kubernetes-server-linux-amd64-v1.17.2.tar.gz"
## 这里的-f参数判断$myFile是否存在
#echo "检查$k8s_path 是否存在"
#if [ ! -f "$k8s_path" ]; then
#echo "$k8s_path  不存在，请手动下载"
#exit 1
#fi

s_time=$(date "+%Y-%m-%d %H:%M:%S")

echo "$(date "+%Y-%m-%d %H:%M:%S") init.yml"
ansible-playbook -i hosts init.yml

echo "$(date "+%Y-%m-%d %H:%M:%S") 初始化完成，重启机器中，需要等待一分钟"
sleep 60

echo "$(date "+%Y-%m-%d %H:%M:%S") 机器重启完成"
ansible-playbook -i hosts install.yml

e_time=$(date "+%Y-%m-%d %H:%M:%S")

echo "开始时间：${s_time}"
echo "结束时间：${e_time}"
