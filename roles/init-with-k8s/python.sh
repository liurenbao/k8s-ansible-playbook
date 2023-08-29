#!/bin/sh
#安装python相关依赖
yum -y install gcc zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel db4-devel libpcap-devel xz-devel libffi-devel

# 下载python安装包
cd /opt && wget https://www.python.org/ftp/python/3.8.6/Python-3.8.6.tgz

# 解压python安装包
cd /opt && tar -zxvf /opt/Python-3.8.6.tgz

# 创建相关目录
mkdir -p /usr/local/python3

# 编译安装
cd /opt/Python-3.8.6 && ./configure --prefix=/usr/local/python3

# 编译
cd /opt/Python-3.8.6 && make && make install

# 创建python3软链接
ln -s /usr/local/python3/bin/python3 /usr/bin/python3

# 添加pip3的软链接
ln -s /usr/local/python3/bin/pip3 /usr/bin/pip3

# 修改python pip源为清华源
/usr/bin/pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

# 更新pip3
/usr/bin/pip3 install --upgrade pip