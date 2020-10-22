# lotus-miner
6block lotus-miner community version, which is continuously freely available to the public.

# Recommended
* CPU：AMD 3960X or other models of Ryzen Threadripper
* RAM：256 GB
* SSD：2 TB * 2
* GPU：NVIDIA 2080 Ti
* OS：Ubuntu 18.04

# Features
* After the first start-up, all subsequent operations are automate without any manual intervention.
* Improved storage and retrieve deals.
* Improved the sync of blockchain.
* The sealing operation is completely completed by the worker. There is no network transmission except the final sealed sector (about 33 GB) back to the miner.
* Automatically find idle workers and start sealing operation.
* After the program exits, it can be resumed when it is started again. If there is an exception, please raise an issue.
* Based on the recommended configuration, it is possible to run 3-4 sectors in a single machine in parallel, with a daily output of more than 200 GB.

# Notice
* Make sure there is enough spare RAM before you get started.
* Make sure all your hardware can connect to the Internet.

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
export LOTUS_PATH="$HOME/.lotus"
export LOTUS_MINER_PATH="$HOME/.lotusminer"
export LOTUS_WORKER_PATH="$HOME/.lotusworker"
export FIL_PROOFS_PARAMETER_CACHE="$HOME/filecoin-proof-parameters"

# Set Chinese zero-knowledge proof parameter download source.
export IPFS_GATEWAY="https://proof-parameters.s3.cn-south-1.jdcloud-oss.com/ipfs/"
# Manually download the zero-knowledge proof parameters to the FIL_PROOFS_PARAMETER_CACHE directory, 200GB
lotus fetch-params 32GiB
```

Start lotus.
```
# Check the version
lotus -v
lotus version 1.1.0+6block+git.888b0101.1603346418

# Start lotus
nohup lotus daemon > ~/lotus.log 2>&1 &

# View logs
tail -f ~/lotus.log

# Generate an address
lotus wallet new bls

# Wait for node synchronized
lotus sync wait
```

Use the address to get testnet coins from the [Slack](https://filecoinproject.slack.com/archives/C017CCH1MHB).

Start miner. Need to complete the test coin getting, miner registering, and node synchronization before.
```
# check the balance of the testnet coins
lotus wallet balance

# Use miner registration results to initialize miner
lotus-miner init --owner=xxx --sector-size=32GiB

# If miner and worker are not on the same machine, you need to configure the miner's IP in LOTUS_STORAGE_PATH
# Cancel the comment in front of ListenAddress and RemoteListenAddress and change their IPs to LAN IPs
vi ~/.lotusstorage/config.toml

# Start miner.
# See an explanation of --max-parallel at the end
nohup lotus-miner run > ~/miner.log 2>&1 &

# View logs
tail -f ~/miner.log

# storage attach, which tells the miner where to store the data actually. Please choose a non-existing new directory under a hard disk or a network disk
lotus-miner storage attach /path/to/storage

# View miner information
lotus-miner info
```

Start worker.
```
# If miner and worker are not on the same machine, you need to copy the files of api and token under LOTUS_STORAGE_PATH of miner to LOTUS_STORAGE_PATH of worker

# Optional environment variables
# The following setting will allow PreCommit1 to use more RAM and have a higher speed, which we suggest to set on the recommended hardware.
# You need to set it both for miner and worker
export FIL_PROOFS_SDR_PARENTS_CACHE_SIZE=1073741824
# The following settings will allow the worker to use the GPU to compute PreCommit2.
export FIL_PROOFS_USE_GPU_COLUMN_BUILDER=1
export FIL_PROOFS_USE_GPU_TREE_BUILDER=1
# The following settings will allow the worker to show more detailed logs.
export RUST_BACKTRACE=full
export RUST_LOG=debug

# Start worker, need to add LAN IP
lotus-worker run --listen xxx.xxx.xxx.xxx:3456 > ~/worker.log 2>&1 &
# View logs
tail -f ~/miner.log
```

Advanced: control concurrency.
We can allow the worker to deal with multiple sectors at the same time by the following.
Although the final computational parallelism still depends on the worker's RAM, increasing concurrency can make the worker's computational resources not idle when some sectors are in WaitSeed.
```
# worker uses multiple sealing paths, which will increase concurrency.
lotus-worker run --address xxx.xxx.xxx.xxx:3456 --attach /path/to/another/ssd/directory

# set ParallelSealLimit on the miner, which stands for the number of sectors allowed for each sealing storage
vi ~/.lotusminer/config.toml

# on the recommended hardware, the recommended concurrency is in total 6.
# If you set ParallelSealLimit to p on the miner and attached n sealing paths on the worker, since the worker starts with a WORKER_PATH as sealing path, the concurrency of the worker is in total p * (n + 1 ).
# When setting the concurrency, you need to consider the size of the SSD where the sealing path is located. Because each sector consumes 520GB of space, the size of the SSD where each sealing path is located should not be less than 520GB * p.
```

Advanced: fetch final sector files to shared directories.
If the storage path attached to the miner can also be accessed through the same path on the worker, the worker can directly transfer the sector file to the shared directory during the FinalizeSector phase, instead of transferring it back to the miner.
```
# set FetchToShared = true
vi ~/.lotusminer/config.toml
```

Advanced: not to auto pledge new sectors when the balance is insufficient (sectors that have already started will continue sealing).
```
# not to auto pledge new sectors when the balance is less than 10 FIL (default 10000 FIL)
lotus-miner run --min-worker-balance-for-auto-pledge 10
```

Observe the operation. Executed on the miner machine. commonly used commands are listed as follows.
```
lotus-miner info
lotus-miner storage list
lotus-miner sectors list
lotus-miner sealing workers
lotus-miner sealing jobs
```

Or you can use the block explorer, like [Filfox](https://calibration.filfox.io/) , to check it.

If any sector has error, you can check out the sector log for the reason of the error. Or simply remove the sector. Take sector 0 as an example.
```
lotus-miner sectors status --log 0
lotus-miner sectors update-state --really-do-it 0 Removing
```

# TODO
* When the sector has some unexpected errors, it will get into the following states
    * FatalError. It happens when the sector information on the blockchain is unexpected, in which case a manual trouble-shooting is needed.
    * Removing/RemoveFailed/Removed. When a garbage sector has unexpected errors, we choose to remove it directly.
* The program runs smoothly under the recommended configuration, and has not been tested in other environments. If you encounter problems, please raise an issue.
* The official code changes will be merged in time.
* Before running, please ensure that available memory and SSD spaces are sufficient.
