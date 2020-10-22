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
* 优化了存储和检索订单。
* 优化了区块链同步。
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
export LOTUS_MINER_PATH="$HOME/.lotusminer"
export LOTUS_WORKER_PATH="$HOME/.lotusworker"
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
lotus version 1.1.0+6block+git.888b0101.1603346418

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

# 如果miner和worker不在一台机器，需要在LOTUS_MINER_PATH中配置miner的IP
# 取消ListenAddress和RemoteListenAddress前面的注释，并将它们的IP改成局域网IP
vi ~/.lotusminer/config.toml

# 启动miner。
nohup lotus-miner run > ~/miner.log 2>&1 &

# 查看日志
tail -f ~/miner.log

# storage attach，即告诉miner真正存储数据的地方。请选择机械硬盘或网盘下不存在的新目录。
lotus-miner storage attach /path/to/storage

# 查看miner信息
lotus-miner info
```

启动worker。
```
# 如果miner和worker不在一台机器，需要将miner机器LOTUS_MINER_PATH下的api和token两个文件拷贝到worker机器的LOTUS_MINER_PATH下

# 可选的环境变量
# 以下设置会让PreCommit1使用更多的内存并且计算更快，在推荐的硬件配置上建议使用
# 需要给miner和worker都设置
export FIL_PROOFS_SDR_PARENTS_CACHE_SIZE=1073741824
# 以下设置会让worker使用GPU计算PreCommit2。
export FIL_PROOFS_USE_GPU_COLUMN_BUILDER=1
export FIL_PROOFS_USE_GPU_TREE_BUILDER=1
# 以下设置将会让worker显示更详细的日志
export RUST_BACKTRACE=full
export RUST_LOG=debug

# 启动worker，需要加入局域网IP
lotus-worker run --listen xxx.xxx.xxx.xxx:3456 > ~/worker.log 2>&1 &
# 查看日志
tail -f ~/miner.log
```

进阶：控制并发。
我们可以通过以下方式让worker同时处理多个sector。
虽然最终的计算并行度仍然取决于worker的内存，但增加并发可以让worker在部分sector处于WaitSeed的时候计算资源不闲置。
```
# worker使用多个封装路径，并发数也会随之增加。
lotus-worker run --address xxx.xxx.xxx.xxx:3456 --attach /path/to/another/ssd/directory

# 在miner上设置ParallelSealLimit，表示每个封装路径所允许的并发数。
vi ~/.lotusminer/config.toml

# 在推荐的硬件配置上，推荐的总并发数是6。
# 如果在miner上设置ParallelSealLimit为p，在worker上attach了n个封装路径，由于worker启动就带一个LOTUS_WORKER_PATH作为封装路径，所以该worker的总并发数为 p * ( n + 1 )。
# 设置并发数时需要考虑封装路径所在SSD的大小，因为每个sector会消耗520GB的空间，所以每个封装路径所在SSD的大小应不小于 520GB * p。
```

进阶：将封装后的sector文件存至共享目录。
如果miner所attach的存储路径也能在worker上以同样的路径访问到，则worker可以在FinalizeSector阶段直接将sector文件传至共享目录，而不必传回给miner。
```
# 设置FetchToShared = true
vi ~/.lotusminer/config.toml
```

进阶：WindowPoSt账户分离，避免MessagePool堵塞时WindowPoSt无法上链导致的掉算力问题
```
# 新增一个账户用于WindowPoSt
$ lotus wallet new bls
t3defg...

# 然后往新地址里打100FIL用于做WindowPoSt
$ lotus send --from <address> t3defg... 100

# 把这个地址设置成发WindowPoSt消息的地址
$ lotus-miner actor control set --really-do-it t3defg...
Add t3defg...
Message CID: bafy2..

# 等待消息上链
$ lotus state wait-msg bafy2..
...
Exit Code: 0
...

# 检查矿工控制地址列表以确保正确添加了地址
$ lotus-miner actor control list
name       ID      key           use    balance
owner      t01111  t3abcd...  other  300 FIL
worker     t01111  t3abcd...  other  300 FIL
control-0  t02222  t3defg...  post   100 FIL
```

进阶：设置ulimit，以lotus-miner为例
```
# 获取lotus-miner的PID(如下所示，PID为2333)
$ ps -ef | grep lotus-miner
root       2333 6666 88 Nov31 ?        1-02:50:00 lotus-miner run
# 为lotus-miner设置ulimit
sudo prlimit --nofile=1048576 --nproc=unlimited --stack=1048576 --rtprio=99 --nice=-19 --pid 2333
```

进阶：新建lotus节点时导入快照快速同步
```
# 获取快照文件，该文件每6小时更新一次
$ wget https://very-temporary-spacerace-chain-snapshot.s3.amazonaws.com/Spacerace_pruned_stateroots_snapshot_latest.car
# 启动lotus时添加daemon启动参数 --import-snapshot /path/to/Spacerace_stateroots_snapshot_latest.car
```

进阶：余额不足情况下不再自动添加新的封装任务（已经开始封装的会继续完成）
```
# 设置余额不足10 FIL情况下不再自动添加新的封装任务（默认 10000 FIL）
lotus-miner run --min-worker-balance-for-auto-pledge 10
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
