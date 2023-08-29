echo "配置NFS存储类"
cd /opt && git clone https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner.git

echo "配置deploy文件"
mv /opt/nfs-subdir-external-provisioner/deploy/*.yaml /opt/nfs-subdir-external-provisioner

echo "配置namespace"
sed -i '' \"s/namespace:.*/namespace: nfs/g\" rbac.yaml deployment.yaml

echo "修改deployment.yaml文件的镜像地址为自己的镜像仓库地址"


echo "创建namespace"
cd /opt/nfs-subdir-external-provisioner && kubectl create ns nfs  # 创建命名空间

echo "创建rbac"
cd /opt/nfs-subdir-external-provisioner && kubectl apply -f rbac.yaml

echo "部署nfs-provisioner"
cd /opt/nfs-subdir-external-provisioner && kubectl apply -f deployment.yaml

echo "创建StorageClass"
cd /opt/nfs-subdir-external-provisioner && kubectl apply -f class.yaml

echo "创建PVC"
cd /opt/nfs-subdir-external-provisioner && kubectl apply -f test-claim.yaml

echo "查看PVC"
kubectl get pvc -n nfs
