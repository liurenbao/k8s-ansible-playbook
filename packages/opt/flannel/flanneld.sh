#!/bin/sh
./flanneld \
  --public-ip=10.4.7.21 \
  --etcd-endpoints=https://10.4.7.12:2379,https://10.4.7.21:2379,https://10.4.7.22:2379 \
  --etcd-keyfile=/opt/flannel/cert/client-key.pem \
  --etcd-certfile=/opt/flannel/cert/client.pem \
  --etcd-cafile=/opt/flannel/cert/ca.pem \
  --iface=eth0 \
  --subnet-file=/opt/flannel/subnet.env \
  --healthz-port=2401
