#!/bin/sh

echo "安装初始化需要的工具"
yum install -y wget net-tools telnet vim git ntpdate

echo "关闭selinux"
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

echo "关闭防火墙"
systemctl stop firewalld && systemctl disable firewalld

echo "关闭swap"
swapoff -a && sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

echo "设置时区"
timedatectl set-timezone Asia/Shanghai

echo "设置同步时间"
ntpdate ntp1.aliyun.com

echo "设置ntpdate开机启动"
systemctl start ntpdate && systemctl enable ntpdate

echo "设置同步时间定时任务"
echo "* * * * * root ntpdate ntp1.aliyun.com > /dev/null 2>&1" >> /etc/crontab

echo "安装docker需要的包"
yum -y install yum-utils

echo "安装docker源，推荐使用yum-config-manager --add-repo安装方式"
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

echo "安装docker"
yum install docker-ce -y

echo "创建docker相关目录"
mkdir -p /etc/docker /data/docker

echo "启动docker并设置开机自启"
systemctl start docker && systemctl enable docker

echo "安装nfs"
yum install nfs-utils -y

echo "创建nfs目录并设置权限"
mkdir -p /opt/data && chmod -R 777 /opt/data

echo "修改nfs共享目录配置文件，按需修改"
echo "/opt/data *(rw,no_root_squash)" >> /etc/exports

echo "启动nfs并设置开机自启"
systemctl start nfs && systemctl enable nfs

echo "设置代理"
cat >> /etc/profile << EOF
function pof() {
  unset http_proxy
  unset https_proxy
  echo -e "已关闭代理"
  curl cip.cc
}

function pon() {
  export http_proxy=http://192.168.50.23:7890
  export https_proxy=$http_proxy
  echo -e "已开启代理"
  curl cip.cc
}

function pos() {
  echo $http_proxy
}
EOF

echo "/etc/host添加github解析地址"
cat >> /etc/hosts << EOF
# GitHub Start
52.74.223.119 github.com
192.30.253.119 gist.github.com
54.169.195.247 api.github.com
185.199.111.153 assets-cdn.github.com
151.101.76.133 raw.githubusercontent.com
151.101.108.133 user-images.githubusercontent.com
151.101.76.133 gist.githubusercontent.com
151.101.76.133 cloud.githubusercontent.com
151.101.76.133 camo.githubusercontent.com
151.101.76.133 avatars0.githubusercontent.com
151.101.76.133 avatars1.githubusercontent.com
151.101.76.133 avatars2.githubusercontent.com
151.101.76.133 avatars3.githubusercontent.com
151.101.76.133 avatars4.githubusercontent.com
151.101.76.133 avatars5.githubusercontent.com
151.101.76.133 avatars6.githubusercontent.com
151.101.76.133 avatars7.githubusercontent.com
151.101.76.133 avatars8.githubusercontent.com
# GitHub End
EOF

echo "安装zsh"
yum install zsh -y

echo "切换bash为zsh"
chsh -s /bin/zsh

echo "安装oh-my-zsh"
source /etc/profile && pon && sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" << EOF
Y
EOF

echo "安装zsh插件"
cd /root/.oh-my-zsh/custom/plugins/ && source /etc/profile && pon && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git
cd /root/.oh-my-zsh/custom/plugins/ && source /etc/profile && pon && git clone https://github.com/zsh-users/zsh-autosuggestions.git

echo "修改.zshrc配置文件"
sed -i 's/plugins=(git)/plugins=(\ngit\nzsh-autosuggestions\nzsh-syntax-highlighting\n)/g' /root/.zshrc

echo "设置zsh显示主机名"
echo "PROMPT=%m\ \$PROMPT" >> /root/.zshrc

echo "设置为使用zsh"
/usr/bin/zsh

echo "source zsh"
source /root/.zshrc

echo "更新系统"
yum update -y

echo "重启系统"
reboot
