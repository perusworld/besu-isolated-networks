# Besu Isolated Networks

## Network Topology
![Network Topology](/network-topology.png)

## To build. Checkout and build [p2p-tls-at-cli branch](https://github.com/perusworld/besu/tree/p2p-tls-at-cli) docker images
```bash
./gradlew clean spotlessApply build -x test -x acceptanceTest distDocker
```
## To Run
```bash
./run.sh
```
## To Test
```bash
cd smart_contracts
npm install
node scripts/eth_tx.js
node scripts/private_tx.js
node scripts/public_tx.js
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

