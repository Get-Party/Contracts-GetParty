require("@nomicfoundation/hardhat-toolbox");
require('./tasks/tasks');
const MNEUMONIC = "";
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
  networks: {
    ganache: {
      url: "http://localhost:7545",
      chainId: 1337,
      accounts: {
        mnemonic: MNEUMONIC,
      },
    }
  }
};
