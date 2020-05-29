# lotus-miner

# Recommended
* CPU：AMD 3970X or other models of Ryzen Threadripper
* RAM：256 GB
* SSD：2 TB
* OS：Ubuntu 18.04

# Minimum
Not tested. If there is any problem, please raise an issue.
* CPU：AMD with SHA extension
* RAM：128 GB
* SSD：1 TB
* OS：Linux

# Features
* After the first start-up, all subsequent operations are automate without any manual intervention.
* The sealing operation is completely completed by the worker. There is no network transmission except the final sealed sector (about 33 GB) back to the miner.
* Automatically find idle workers and start sealing operation.
* After the program exits, it can be resumed when it is started again. If there is an exception, please raise an issue.
* Based on the recommended configuration, it is possible to run two sectors in a single machine in parallel, with a daily output of more than 200 GB.

# Installation
The mining program, necessary libraries, time calibration , GPU driver, swap memory (64 GB) will be installed.
```
# Download
git clone https://github.com/shannon-6block/lotus-miner.git
cd lotus-miner

# Switch to root account
sudo su
# Execute installation
./script/install.sh
# After installation, you can exit and return to the previous account
# If it is the first time installing the GPU driver, reboot is needed to take effect
```

# Setup
Several configurable environment variables can be set according to your needs.
```
# The directory of lotus, miner, worker, and zero-knowledge proof parameters. It is recommended to set them to directories on SSD.
export LOTUS_PATH="$HOME/lotus"
export LOTUS_STORAGE_PATH="$HOME/lotusstorage"
export WORKER_PATH="$HOME/lotusworker"
export FIL_PROOFS_PARAMETER_CACHE="$HOME/filecoin-proof-parameters"

# Set Chinese zero-knowledge proof parameter download source.
export IPFS_GATEWAY="https://proof-parameters.s3.cn-south-1.jdcloud-oss.com/ipfs/"
# Manually download the zero-knowledge proof parameters to the FIL_PROOFS_PARAMETER_CACHE directory, 200GB
lotus fetch-params --proving-params 32GiB
```

Start lotus.
```
# Start lotus
nohup lotus > ~/lotus.log 2>&1 &

# View logs
tail -f ~/lotus.log

# Generate an account. Need to go to https://faucet.testnet.filecoin.io/ to get test coins and create a miner account.
lotus wallet new bls

# Wait for node synchronized
lotus sync wait
```

Start miner. Need to complete the test coin getting, miner registering, and node synchronization before.
```
# Use miner registration results to initialize miner
# It is recommended to add the --no-local-storage parameter as shown below, instead of storing data in the default location LOTUS_STORAGE_PATH
lotus-storage-miner init --actor=xxx --owner=xxxxx --no-local-storage

# If miner and worker are not on the same machine, you need to configure the miner's IP
# Cancel the comment in front of ListenAddress and RemoteListenAddress and change their IPs to LAN IPs
vi ~/.lotusstorage/config.toml

# Start miner.
# --max-parallel indicates the number of parallel sectors allowed for each worker.
# When there is 256 GB memory, 64 GB swap and 1.4 TB hard disk free space, two sectors can be parallel.
# When there is 128 GB memory, 64 GB swap and 0.7 TB hard disk free space, one sector can be used in parallel.
nohup lotus-storage-miner run --max-parallel 2 > ~/miner.log 2>&1 &

# View logs
tail -f ~/miner.log

# storage attach, which tells the miner where to store the data actually. Please choose directories under hard disks or network disks
lotus-storage-miner storage attach --init=true --store=true /path/to/storage

# View miner information
lotus-storage-miner info
```

Start worker.
```
# If miner and worker are not on the same machine, you need to copy the files of api and token under LOTUS_STORAGE_PATH of miner to LOTUS_STORAGE_PATH of worker

# Required environment variable
export FIL_PROOFS_MAXIMIZE_CACHING=1

# Optional environment variables
# The following setting will allow the worker to use the GPU to compute PreCommit2. It is recommended to use it in the case of dual GPUs, otherwise it will report an error of insufficient GPU memory.
export FIL_PROOFS_USE_GPU_COLUMN_BUILDER=1
# The following setting will cause the worker to use the CPU instead of the GPU to compute Commit2.
export BELLMAN_NO_GPU=true

# Start worker, need to add LAN IP
lotus-seal-worker run --address=xxx.xxx.xxx.xxx:3456 > ~/worker.log 2>&1 &
# View logs
tail -f ~/miner.log
```

Observe the operation. Executed on the miner machine. commonly used commands are listed as follows.
```
lotus-storage-miner info
lotus-storage-miner storage list
lotus-storage-miner workers list
lotus-storage-miner sectors list
```

# TODO
* Currently, there is a problem with the official code in the Window PoSt part. Therefore, a decline of storage power may happen. To avoid this problem, please do not do too many manual operations.
* The program runs smoothly under the recommended configuration, and has not been tested in other environments. If you encounter problems, please raise an issue.
* The official code changes will be merged in time.
* After the program is stable for a period, the algorithm optimization will be merged.