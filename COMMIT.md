# 分离ProveCommitSector地址
## 背景
在封装过程中，如果不能一直保持worker balance充足，则有可能出现部分扇区成功发送PreCommitSector消息但没有足够币发送ProveCommitSector消息的情况。这样会造成扇区无法完成上链，抵押币和gas fee浪费。

为了解决这个问题，我们可以分离发送PreCommitSector消息和发送ProveCommitSector消息的地址，并在后者充入足够的币。从而保证前者余额消耗完的时候，后者还能有余额。

## 步骤
```shell
# 新建地址
lotus wallet new bls
# 向新地址打一点币
lotus send <new address> 0.01
# 获取当前的control地址列表
lotus-miner actor control list --verbose
# 更新control地址列表，加入新的地址，地址间空格分隔
lotus-miner actor control set --really-do-it [old + new control addresses]
# 编辑miner的config.toml，设置Address分类下的CommitControl项
[Addresses]
  CommitControl = ["<new control address>"]
# 重启miner，查看最终control地址列表，显示如下例子
lotus-miner actor control list --verbose

name       ID      key    use     balance                     
owner      f0...  f3...  other   123.456 FIL  
worker     f0...  f3...  other   234.567 FIL  
control-0  f0...  f3...  commit  345.678 FIL    
control-1  f0...  f3...  post    456.789 FIL 
```
