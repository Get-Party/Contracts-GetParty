# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a Hardhat Ignition module that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat ignition deploy ./ignition/modules/Lock.js
```

# Guide to Execute

```shell
npx hardhat test --network hardhat
npx hardhat run scripts/deploy.js --network ganache
npx hardhat compile
npx hardhat ignition deploy ./ignition/modules/GetPartyToken.js --network localhost
npx hardhat ignition deploy ./ignition/modules/GetPartyToken.js --network ganache
npx hardhat accounts --network ganache
```
