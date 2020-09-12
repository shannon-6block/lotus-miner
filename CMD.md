```
深圳
/dns4/bootstrap1.testnet.filfox.info/tcp/16666/p2p/12D3KooW9uSxsSh3qwAPxSwwRDVqTTPg8HTBthujVYFXy7Dizb6Q
上海
/dns4/bootstrap2.testnet.filfox.info/tcp/16666/p2p/12D3KooWKths1fzziHsmeMdTdV7dgB9DzoeiGVSwcW2HCygztH9e
```

```
# In lotusminer/config.toml
ParallelFetchLimit = xxx
# In lotus-worker
lotus-worker run --parallel-fetch-limit xxx
```

https://lotu.sh/en+mining#separate-address-for-windowpost-messages-439130

```
curl -X POST \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $(cat $LOTUS_PATH/token)" \
     --data '{ "jsonrpc": "2.0", "method": "Filecoin.MpoolGetConfig", "params": [], "id": 3}' \
     http://$(cat $LOTUS_PATH/api | awk -F\/ '{printf "%s:%s", $3, $5}')/rpc/v0 | jq

curl -X POST \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $(cat $LOTUS_PATH/token)" \
     --data '{ "jsonrpc": "2.0", "method": "Filecoin.MpoolSetConfig", "params": [{"PriorityAddrs":["t3xxxxxxxxxxxxxxxxxxxxx"],"SizeLimitHigh":30000,"SizeLimitLow":20000,"ReplaceByFeeRatio":1.25,"PruneCooldown":60000000000,"GasLimitOverestimation":1.25}], "id": 3}' \
     http://$(cat $LOTUS_PATH/api | awk -F\/ '{printf "%s:%s", $3, $5}')/rpc/v0

curl -X POST \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $(cat $LOTUS_PATH/token)" \
     --data '{ "jsonrpc": "2.0", "method": "Filecoin.MpoolSelect", "params": [[], 1.0], "id": 3}' \
     http://$(cat $LOTUS_PATH/api | awk -F\/ '{printf "%s:%s", $3, $5}')/rpc/v0 | jq
```

```
# In lotusminer/config.toml
MaxWindowPoStGasFee = "xxx FIL"
```