#!/bin/sh
./etcd --name etcd-server-7-12 \
       --data-dir /data/etcd/etcd-server \
       --listen-peer-urls https://10.4.7.12:2380 \
       --listen-client-urls https://10.4.7.12:2379,http://127.0.0.1:2379 \
       --quota-backend-bytes 8000000000 \
       --initial-advertise-peer-urls https://10.4.7.12:2380 \
       --advertise-client-urls https://10.4.7.12:2379,http://127.0.0.1:2379 \
       --initial-cluster  etcd-server-7-12=https://10.4.7.12:2380,etcd-server-7-21=https://10.4.7.21:2380,etcd-server-7-22=https://10.4.7.22:2380 \
       --ca-file ./certs/ca.pem \
       --cert-file ./certs/etcd-peer.pem \
       --key-file ./certs/etcd-peer-key.pem \
       --client-cert-auth  \
       --trusted-ca-file ./certs/ca.pem \
       --peer-ca-file ./certs/ca.pem \
       --peer-cert-file ./certs/etcd-peer.pem \
       --peer-key-file ./certs/etcd-peer-key.pem \
       --peer-client-cert-auth \
       --peer-trusted-ca-file ./certs/ca.pem \
       --log-output stdout
