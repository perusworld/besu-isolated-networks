# Besu Isolated Networks

## Network Topology
![Network Topology](/network-topology.png)

## To build, checkout and build [p2p-over-ssl branch](https://github.com/perusworld/besu/tree/p2p-over-ssl) docker images
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
node scripts/deploy.js
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

