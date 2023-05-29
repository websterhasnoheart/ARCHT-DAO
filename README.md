# ARCHT-DAO

The content of this repo is affiliated with the graduation research project by the author. The research is **'A Decentralized Autonomous Organization(DAO) framework for architectural design evaluation.'**

The contract is developed with libraries provided by `OpenZeppeLin`, deployed and verified with `hardhat`, for more info, please check the websites:
1. OpenZeppeLin : https://www.openzeppelin.com/
2. HardHat: https://hardhat.org/hardhat-runner/docs/getting-started#overview

**1. Install OpenZeppeLin libraries**

`npm install @openzeppelin/contracts`

**2. Install hardhat**

`npm install --save-dev hardhat`

**3. SetUp: Create a hardhat project for your contracts to be compiled, deployed and verified**

`npx hardhat`

Select `Create a JavaScript project` for the full package

**4a. Open the created project folder and Compile your contracts**

`npx hardhat compile`

Modify your contract parameters accordingly in `deploy.js` -> `contractFactory.deploy` like the follows :

```
const archt = await ARCHT.deploy(
              '0xb944D8c673142aA64548C8660E9b24c2948CcB89',
              '0xd625E0B8eBB492bbfB9a4fE5C7CbC07Ab5126B28',
              '0x4B26a638EC85457a8c683Dee79100A7C77374460');
```
The contract I develoepd requires 3 wallet addresses as arguments.

**4b. Modify hardhat.config.js**

```
require("@nomicfoundation/hardhat-toolbox");
require('hardhat-deploy');

/** @type import('hardhat/config').HardhatUserConfig */

const INFURA_API_KEY = "YOUR INFURA API KEY";

//Get your key at https://www.infura.io/

const SEPOLIA_PRIVATE_KEY = "YOUR WALLET PRIVATE KEY";

module.exports = {
  solidity: "0.8.18",
    etherscan: {
      apiKey : "YOUR ETHER SCAN API KEY", // get your key at https://etherscan.io/ by creating an account
    },
    networks: {
      sepolia: {
        url: `https://sepolia.infura.io/v3/${INFURA_API_KEY}`,
        accounts: [SEPOLIA_PRIVATE_KEY],
      },
    }
}

```


**5. Test your contracts**

`npx hardhat test` after modify `test/contract.js` accordingly.

**6. Deploy your contracts**

`npx hardhat run`

**7. Connecting a wallet or Dapp to Hardhat Network**

```
$ npx hardhat node
Started HTTP and WebSocket JSON-RPC server at http://127.0.0.1:8545/
```
Open a new terminal and deploy the smart contract in the localhost network

`npx hardhat run --network localhost scripts/deploy.js`

If you would like to deploy your contract in another network other than mainnet :

`npx hardhat run --network <your-network> scripts/deploy.js`

**8. Verify your contract on ethereum so others can interact**

`npx hardhat run scripts/deploy.js --network sepolia`

`npx hardhat verify --network sepolia <contract address> <arguments(separated by spaces if there are more)>`

`npx hardhat verify --network mainnet DEPLOYED_CONTRACT_ADDRESS "Constructor argument 1"`

In case you have more complex args :

Create a file `arguments.js`
```
module.exports = [
  50,
  "a string argument",
  {
    x: 10,
    y: 5,
  },
  // bytes have to be 0x-prefixed
  "0xabcdef",
];
```
And run

`npx hardhat verify --constructor-args arguments.js DEPLOYED_CONTRACT_ADDRESS`

For more info : [HardHat Verify](https://hardhat.org/hardhat-runner/plugins/nomicfoundation-hardhat-verify)
