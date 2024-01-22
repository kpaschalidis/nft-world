# World Land Sale Smart Contracts

`World` is a Metaverse consisting of a 3D world. Will provide virtual experiences, community engagement opportunities, hosted
content and utility to a wide range of vertical and horizontal market segments.

## Development

### Install dependencies

```sh
npm install
```

### Compile typescript, contracts, and generate typechain wrappers

```sh
npm run build
```

### Run tests

```sh
npm run test
```

### Environment Setup

Copy `.env.example` to `.env` and fill in fields

### Commands

````sh
# compiling
npx hardhat compile

# deploying
npx hardhat deploy --network rinkeby --base-token-uri {BASE_TOKEN_URI}

# is-paused
npx hardhat is-paused --network rinkeby --world-land-token-proxy {WORLD_LAND_TOKEN_ADDRESS_PROXY}

# unpause, token contract, initial the contract paused
npx hardhat unpause --network rinkeby --world-land-token-proxy {WORLD_LAND_TOKEN_ADDRESS_PROXY}

# Hardhat console
npx hardhat console --network rinkeby

# commands via `hardhat console`
```sh
# get instance of token proxy contract
const proxyFactory = await ethers.getContractFactory('WorldLandToken');
const proxyContract = await proxyFactory.attach('0x83C80B5A7012843769D9a015546Ae1589cdCDf00');

# get instance of token sale factory contract
const saleFactory = await ethers.getContractFactory('WorldSaleFactory');
const saleContract = await saleFactory.attach('<WORLD_LAND_SALE_FACTORY_ADDRESS>');

# grant role to the `factory` contract
await (await proxyContract.grantRole(ethers.utils.keccak256(ethers.utils.toUtf8Bytes('MINTER_ROLE')), '0xD69b574aDfB0E8dD7A0C1b0E3Ff884da3A913eae')).wait();

# verify the role has granted
await proxyContract.hasRole(ethers.utils.keccak256(ethers.utils.toUtf8Bytes('MINTER_ROLE')), '0xD69b574aDfB0E8dD7A0C1b0E3Ff884da3A913eae');

# mint lazy
const tokenIds: []; # ['0,', '1', '2', '3']
await saleContract.lazyMint(tokenIds);
````

# mint (not lazy), only owner

npx hardhat mint-land --network rinkeby --world-land-token-proxy {WORLD_LAND_TOKEN_ADDRESS_PROXY} --to {RECEIVER_ADDRESS} --x {X_COORDINATE} --y {Y_COORDINATE}

# pause

npx hardhat pause --network rinkeby --world-land-token-proxy {WORLD_LAND_TOKEN_ADDRESS_PROXY}

# replace `rinkeby` with `mainnet` to productionize

```

```
