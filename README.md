# lotus-miner
[English](README_en.md)

# 推荐配置
* CPU：AMD 3970X 或 Ryzen Threadripper 其他型号
* 内存：256 GB
* SSD：2 TB
* 操作系统：Ubuntu 18.04

# 最低配置
未测试。如果有问题可以提issue。
* CPU：带有 SHA 扩展的 AMD
* 内存：128 GB
* SSD：1 TB
* 操作系统：Linux

# 特点
* 首次启动之后，以后所有操作自动化，无需人工干预。
* 封装操作完全在worker完成，除了最终sealed sector（约33 GB）回传miner之外没有网络传输。
* 自动发现空闲worker，启动封装操作。
* 程序退出后，再次启动都能恢复运行。如果出现不能恢复的情况，可以提issue。
* 基于推荐配置，可以进行单机2个sector的并行运行，每日产出存力200 GB以上。

# 安装配置
将会安装挖矿程序、必要的库、时间校准、显卡驱动、ulimit、swap内存（64 GB）。
```
# 下载
git clone https://github.com/shannon-6block/lotus-miner.git
cd lotus-miner

# 切换至root账户
sudo su
# 执行安装
./script/install.sh
# 安装完后可以exit回到之前的账户
# 如果是首次安装显卡驱动，需要重启以生效
```

# 首次启动
几个可以配置的环境变量，根据自己需求设置。
```
# lotus、miner、worker、零知识证明参数的目录。建议设置为SSD上的目录
export LOTUS_PATH="$HOME/lotus"
export LOTUS_STORAGE_PATH="$HOME/lotusstorage"
export WORKER_PATH="$HOME/lotusworker"
export FIL_PROOFS_PARAMETER_CACHE="$HOME/filecoin-proof-parameters"

# 设置国内的零知识证明参数下载源
export IPFS_GATEWAY="https://proof-parameters.s3.cn-south-1.jdcloud-oss.com/ipfs/"
# 手动下载零知识证明参数到FIL_PROOFS_PARAMETER_CACHE目录中，有200GB
lotus fetch-params --proving-params 32GiB
```

启动lotus。
```
# 启动lotus
nohup lotus > ~/lotus.log 2>&1 &

# 查看日志
tail -f ~/lotus.log

# 生成account。需要去 https://faucet.testnet.filecoin.io/ 领取测试币和创建矿工账户
lotus wallet new bls

# 等待节点同步完成
lotus sync wait
```

启动miner。需要先完成领取测试币、注册矿工、节点同步完成。
```
# 使用矿工注册结果来初始化miner
# 建议如下所示加上--no-local-storage参数，不用默认位置LOTUS_STORAGE_PATH存数据
lotus-storage-miner init --actor=xxx --owner=xxxxx --no-local-storage

# 如果miner和worker不在一台机器，需要配置miner的IP
# 取消ListenAddress和RemoteListenAddress前面的注释，并将它们的IP改成局域网IP
vi ~/.lotusstorage/config.toml

# 启动miner。
# --max-parallel表示每个worker允许并行的sector数量。
# 当有 256 GB 内存、64 GB swap 和 1.4 TB 硬盘空闲空间的情况下，可以并行2个sector。
# 当有 128 GB 内存、64 GB swap 和 0.7 TB 硬盘空闲空间的情况下，可以并行1个sector。
nohup lotus-storage-miner run --max-parallel 2 > ~/miner.log 2>&1 &

# 查看日志
tail -f ~/miner.log

# storage attach，即告诉miner真正存储数据的地方。请选择机械硬盘或网盘下的目录
lotus-storage-miner storage attach --init=true --store=true /path/to/storage

# 查看miner信息
lotus-storage-miner info
```

启动worker。
```
# 如果miner和worker不在一台机器，需要将miner机器LOTUS_STORAGE_PATH下的api和token两个文件拷贝到worker机器的LOTUS_STORAGE_PATH下

# 一定需要的环境变量
export FIL_PROOFS_MAXIMIZE_CACHING=1

# 可选的环境变量
# 如下设置会让worker使用GPU计算PreCommit2。建议双显卡的情况下再使用，否则会报显存不够的错误。
export FIL_PROOFS_USE_GPU_COLUMN_BUILDER=1
# 如下设置会让worker不使用GPU计算Commit2，而改用CPU。
export BELLMAN_NO_GPU=true

# 启动worker，需要加入局域网IP
lotus-seal-worker run --address=xxx.xxx.xxx.xxx:3456 > ~/worker.log 2>&1 &
# 查看日志
tail -f ~/miner.log
```

观察运行情况。在miner机器执行。常用命令列举如下。
```
lotus-storage-miner info
lotus-storage-miner storage list
lotus-storage-miner workers list
lotus-storage-miner sectors list
```

# TODO
* 目前官方代码在Window PoSt部分存在问题。所以，存力有可能发生下降。为了避免这一问题，请不要进行过多手动操作。
* 程序在推荐配置下顺利运行，没有做过其他环境的测试，如果遇到问题可以提issue。
* 会及时合入官方的代码改动。
* 程序经过一段时间稳定之后，会再将算法优化合入。