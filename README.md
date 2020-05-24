# lotus-miner

# 推荐配置
* CPU：AMD 3970X 或 Ryzen Threadripper 其他型号
* 内存：256 GB
* SSD：2 TB
* 操作系统：Ubuntu 18.04

# 特点
* 首次启动之后，以后所有操作自动化，无需人工干预。
* 封装操作完全在worker完成，除了最终sealed sector回传miner之外没有网络传输。
* 自动发现空闲worker，启动封装操作。

# 安装配置
将会安装和配置挖矿程序、必要的库、校准时间、显卡驱动、swap内存。
```
# 下载
git clone https://github.com/shannon-6block/lotus-miner.git
cd lotus-miner

# 切换root
sudo su
# 执行安装
./script/install.sh
```

# 首次启动
几个可以配置的环境变量，根据自己需求设置。
```
# 设置国内的零知识证明参数下载源
export IPFS_GATEWAY="https://proof-parameters.s3.cn-south-1.jdcloud-oss.com/ipfs/"

# lotus、miner、worker、零知识证明参数的目录，建议设置为SSD上的目录
export LOTUS_PATH="$HOME/lotus"
export LOTUS_STORAGE_PATH="$HOME/lotusstorage"
export WORKER_PATH="$HOME/lotusworker"
export FIL_PROOFS_PARAMETER_CACHE="$HOME/filecoin-proof-parameters"
```

启动lotus。
```
# 启动lotus
nohup lotus > ~/lotus.log 2>&1 &

# 等待api就绪
lotus wait-api

# 生成account。需要去https://faucet.testnet.filecoin.io/领取测试币和创建矿工账户
lotus wallet new bls

# 等待节点同步完成
lotus sync wait
```

启动miner。需要先完成领取测试币、注册矿工、节点同步完成。
```
# 使用矿工注册结果来初始化miner
# 建议如下所示加上--no-local-storage参数，不用默认位置存数据
lotus-storage-miner init --actor=xxx --owner=xxxxx --no-local-storage

# 配置IP
# 取消ListenAddress和RemoteListenAddress前面的注释，并将IP改成局域网IP
vi ~/.lotusstorage/config.toml

# 启动miner。
# --max-parallel表示每个worker允许的并行数量。
# 当有 256 GB 内存、64 GB swap 和 1.4 TB 硬盘空闲的情况下，可以并行2个。
nohup lotus-storage-miner run --max-parallel 2 > ~/miner.log 2>&1 &

# storage attach，即告诉miner真正存数据的地方
lotus-storage-miner storage attach --init=true --store=true /path/to/storage

# 查看miner信息
lotus-storage-miner info
```

启动worker。
```
# 如果miner和worker不在一台机器，需要将miner机器LOTUS_STORAGE_PATH下的api和token两个文件拷贝到worker机器的LOTUS_STORAGE_PATH下

# 一定需要的环境变量
export FIL_PROOFS_MAXIMIZE_CACHING=1

# 可以配置的环境变量
# 如下设置会让worker使用GPU计算PreCommit2
export FIL_PROOFS_USE_GPU_COLUMN_BUILDER=1
# 如下设置会让worker不使用GPU计算Commit2
export BELLMAN_NO_GPU=true

# 启动worker，需要加入局域网IP
lotus-seal-worker run --address=xxx.xxx.xxx.xxx:3456 > ~/worker.log 2>&1 &
```

观察运行情况。miner和worker启动后会自动开始pledge，只需要在miner机器查看info即可。
```
watch lotus-storage-miner info
```

# TODO
目前官方代码，在Window PoSt环节存在问题。所以，存力下降的问题暂时无法避免。