# lotus-miner
[English](README_en.md)

石榴矿池lotus-miner社区版，持续免费向公众提供。

# 推荐配置
* CPU：AMD 3960X 或 Ryzen Threadripper 其他型号
* 内存：256 GB
* SSD：2 TB * 2
* GPU：NVIDIA 2080 Ti
* 操作系统：Ubuntu 18.04

# 特点
* 首次启动之后，以后所有操作自动化，无需人工干预。
* 支持存储接单。
* 封装操作完全在worker完成，除了最终sealed sector（约33 GB）回传miner之外没有网络传输。
* 自动发现空闲worker，启动封装操作。
* 程序退出后，再次启动都能恢复运行。如果出现不能恢复的情况，可以提issue。
* 基于推荐配置，可以进行单机3-4个sector的并行运行，每日产出存力200 GB以上。

# 注意
* 开始之前请确保有足够的空闲内存。
* 请确保所有设备能够正常连接互联网。

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
export LOTUS_PATH="$HOME/.lotus"
export LOTUS_STORAGE_PATH="$HOME/.lotusminer"
export WORKER_PATH="$HOME/.lotusworker"
export FIL_PROOFS_PARAMETER_CACHE="$HOME/filecoin-proof-parameters"

# 设置国内的零知识证明参数下载源
export IPFS_GATEWAY="https://proof-parameters.s3.cn-south-1.jdcloud-oss.com/ipfs/"
# 手动下载零知识证明参数到FIL_PROOFS_PARAMETER_CACHE目录中，有200GB
lotus fetch-params 32GiB
```

启动lotus。
```
# 确定版本
lotus -v
lotus version 0.4.6+git.4dae4e70

# 启动lotus
nohup lotus daemon > ~/lotus.log 2>&1 &

# 查看日志
tail -f ~/lotus.log

# 生成address
lotus wallet new bls

# 等待节点同步完成
lotus sync wait
```

用address去 [Slack](https://filecoinproject.slack.com/archives/C017CCH1MHB) 领取测试币。

启动miner。
```
# 查看测试币余额
lotus wallet balance

# 使用address注册矿工
lotus-miner init --owner=xxx --sector-size=32GiB

# 如果miner和worker不在一台机器，需要在LOTUS_STORAGE_PATH中配置miner的IP
# 取消ListenAddress和RemoteListenAddress前面的注释，并将它们的IP改成局域网IP
vi ~/.lotusminer/config.toml

# 启动miner。
nohup lotus-miner run > ~/miner.log 2>&1 &

# 查看日志
tail -f ~/miner.log

# storage attach，即告诉miner真正存储数据的地方。请选择机械硬盘或网盘下的目录
lotus-miner storage attach /path/to/storage

# 查看miner信息
lotus-miner info
```

启动worker。
```
# 如果miner和worker不在一台机器，需要将miner机器LOTUS_STORAGE_PATH下的api和token两个文件拷贝到worker机器的LOTUS_STORAGE_PATH下

# 可选的环境变量
# 以下设置会让worker使用GPU计算PreCommit2。
export FIL_PROOFS_USE_GPU_COLUMN_BUILDER=1
export FIL_PROOFS_USE_GPU_TREE_BUILDER=1
# 以下设置会让worker不使用GPU计算Commit2，而改用CPU。
export BELLMAN_NO_GPU=true
# 以下设置将会让worker显示更详细的日志
export RUST_BACKTRACE=full
export RUST_LOG=debug

# 启动worker，需要加入局域网IP
lotus-worker run --address xxx.xxx.xxx.xxx:3456 > ~/worker.log 2>&1 &
# 查看日志
tail -f ~/miner.log
```

进阶：控制并发。
```
# worker使用多个封装路径，并发数也会随之增加。
lotus-worker run --address xxx.xxx.xxx.xxx:3456 --attach /path/to/another/ssd/directory

# 在miner上设置ParallelSealLimit，表示每个封装路径所允许的并发数。
vi ~/.lotusminer/config.toml
```

进阶：分离封装阶段（未测试）。
```
# 请使用Release中的lotus-miner.separate.tar.gz包代替
# PreCommit1 worker
lotus-worker run --address xxx.xxx.xxx.xxx:3456 --precommit2 false --commit false
# PreCommit2 & Commit worker
lotus-worker run --address xxx.xxx.xxx.xxx:3456 --addpiece false --precommit1 false
# 独立的PreCommit2 worker
lotus-worker run --address xxx.xxx.xxx.xxx:3456 --addpiece false --precommit1 false --commit false
# 独立的Commit worker
lotus-worker run --address xxx.xxx.xxx.xxx:3456 --addpiece false --precommit1 false --precommit2 false
```

观察运行情况。在miner机器执行。常用命令列举如下。
```
lotus-miner info
lotus-miner storage list
lotus-miner sectors list
lotus-miner sealing workers
lotus-miner sealing jobs
```

或者使用区块浏览器，例如 [Filfox](https://calibration.filfox.io/) ，查看。

如果sector出错，可以查看sector日志，找到出错原因。或者直接删除sector。以0号sector为例。
```
lotus-miner sectors status --log 0
lotus-miner sectors update-state --really-do-it 0 Removing
```

# TODO
* 当sector出现意料之外的错误，会进入如下两种状态。
    * FatalError。通常由于sector的链上信息不符合预期，此时需要手动排查问题。
    * Removing/RemoveFailed/Removed。当垃圾sector出现预料之外的错误，我们选择直接删除。
* 程序在推荐配置下顺利运行，没有做过其他环境的测试，如果遇到问题可以提issue。
* 会及时合入官方的代码改动。
* 运行前请保证可用内存和SSD空间充裕。