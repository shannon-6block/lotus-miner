#!/bin/bash

rm -rf lotus-miner.tar.gz cmd
wget https://github.com/shannon-6block/lotus-miner/releases/download/test.0.4.0.17/lotus-miner.tar.gz
mkdir cmd
tar zxvf lotus-miner.tar.gz -C cmd/
cp cmd/* /usr/local/bin/

apt update
apt install -y mesa-opencl-icd ocl-icd-opencl-dev ntpdate ubuntu-drivers-common

# time adjust
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
ntpdate ntp.aliyun.com

# install ulimit
ulimit -n 1048576
sed -i "/nofile/d" /etc/security/limits.conf
echo "* hard nofile 1048576" >> /etc/security/limits.conf
echo "* soft nofile 1048576" >> /etc/security/limits.conf
echo "root hard nofile 1048576" >> /etc/security/limits.conf
echo "root soft nofile 1048576" >> /etc/security/limits.conf

# setup SWAP, 64GB, swappiness=1
SWAPSIZE=`swapon --show | awk 'NR==2 {print $3}'`
if [ "$SWAPSIZE" != "64G" ]; then
  OLDSWAPFILE=`swapon --show | awk 'NR==2 {print $1}'`
  NEWSWAPFILE="/swapfile"
  if [ -n "$OLDSWAPFILE" ]; then
    swapoff -v $OLDSWAPFILE
    rm $OLDSWAPFILE
    sed -i "/\$OLDSWAPFILE/d" /etc/fstab
    NEWSWAPFILE=$OLDSWAPFILE
  fi
  fallocate -l 64GiB $NEWSWAPFILE
  chmod 600 $NEWSWAPFILE
  mkswap $NEWSWAPFILE
  swapon $NEWSWAPFILE
  echo "$NEWSWAPFILE none swap sw 0 0" >> /etc/fstab
  sysctl vm.swappiness=1
  sed -i "/swappiness/d" /etc/sysctl.conf
  echo "vm.swappiness=1" >> /etc/sysctl.conf
fi

# install GPU driver
nvidia-smi
NEEDGPU=$?
if [ $NEEDGPU -ne 0 ]; then
  ubuntu-drivers autoinstall
  echo "reboot to make the GPU to take effect!"
fi
