#!/bin/bash

rm -rf lotus-miner.tar.gz cmd
wget https://github.com/shannon-6block/lotus-miner/releases/download/mainnet.1.4.0.6/lotus-miner.tar.gz
mkdir cmd
tar zxvf lotus-miner.tar.gz -C cmd/
cp cmd/* /usr/local/bin/

apt update
apt install -y mesa-opencl-icd ocl-icd-opencl-dev ntpdate ubuntu-drivers-common gcc git bzr jq pkg-config curl clang build-essential hwloc libhwloc-dev wget

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

sysctl vm.dirty_bytes=53687091200
sed -i "/dirty_bytes/d" /etc/sysctl.conf
echo "vm.dirty_bytes=53687091200" >> /etc/sysctl.conf

sysctl vm.dirty_background_bytes=10737418240
sed -i "/dirty_background_bytes/d" /etc/sysctl.conf
echo "vm.dirty_background_bytes=10737418240" >> /etc/sysctl.conf

sysctl vm.vfs_cache_pressure=1000
sed -i "/vfs_cache_pressure/d" /etc/sysctl.conf
echo "vm.vfs_cache_pressure=1000" >> /etc/sysctl.conf

sysctl vm.dirty_writeback_centisecs=100
sed -i "/dirty_writeback_centisecs/d" /etc/sysctl.conf
echo "vm.dirty_writeback_centisecs=100" >> /etc/sysctl.conf

sysctl vm.dirty_expire_centisecs=100
sed -i "/dirty_expire_centisecs/d" /etc/sysctl.conf
echo "vm.dirty_expire_centisecs=100" >> /etc/sysctl.conf

# install GPU driver
nvidia-smi
NEEDGPU=$?
if [ $NEEDGPU -ne 0 ]; then
  apt install -y nvidia-driver-440-server
  echo "reboot to make the GPU to take effect!"
fi
