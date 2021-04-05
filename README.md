# Besu Isolated Networks

## Ensure [p2p-over-ssl branch](https://github.com/perusworld/besu/tree/p2p-over-ssl) docker images
```bash
./gradlew clean spotlessApply build -x test -x acceptanceTest distDocker
```


## Key Configs
```
permissions-nodes-config-file-enabled=false
discovery-enabled=false
# with only validators
static-nodes-file="/config/static-nodes.json"
nat-method="NONE"
p2p-host="0.0.0.0"
Xdns-enabled=true
Xdns-update-enabled=true

```


## Network Topology
![Network Topology](/network-topology.png)