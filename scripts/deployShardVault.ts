import hre from 'hardhat';
import { BigNumber } from 'ethers';
import { ShardVaultManager } from '../typechain-types';
import {
  createFile,
  ShardVault,
  readFile,
  ShardVaultAddresses,
  ShardVaultUints,
} from './utils/utils';

async function main() {
  const ethers = hre.ethers;
  const [deployer] = await ethers.getSigners();
  const dirPath = `data`;

  let coreDiamond = '0xB468647B04bF657C9ee2de65252037d781eABafD';
  const shardName: string = 'name';
  const shardSymbol: string = 'symbol';
  const shardBaseURI: string = 'baseURI';

  const uints: ShardVaultUints = {
    shardValue: ethers.utils.parseEther('0.5'),
    maxSupply: BigNumber.from('100'),
    maxMintBalance: BigNumber.from('1'),
    saleFeeBP: BigNumber.from('0'),
    acquisitionFeeBP: BigNumber.from('0'),
    yieldFeeBP: BigNumber.from('0'),
    ltvBufferBP: BigNumber.from('0'),
    ltvDeviationBP: BigNumber.from('0'),
  };

  const addresses: ShardVaultAddresses = {
    shardVaultDiamond: '0x47c05BCCA7d57c87083EB4e586007530eE4539e9',
    marketPlaceHelper: '0x408F924BAEC71cC3968614Cb2c58E155A35e6890',
    collection: '0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB', //CryptoPunkMarket
    jpegdVault: '0x4e5F305bFCa77b17f804635A9bA669e187d51719', //PunkPETH
    jpegdVaultHelper: '0x2bE665ee27096344B8f015b1952D3dFDb4Db4691', //PunkPETH helper
    authorized: [ethers.constants.AddressZero],
  };

  const network = hre.network.name;
  const shardVaultManager: ShardVaultManager = await ethers.getContractAt(
    'ShardVaultManager',
    coreDiamond,
  );

  console.log('\nDeploying new ShardVault...');
  try {
    const deploymentTx = await shardVaultManager
      .connect(deployer)
      [
        'deployShardVault((address,address,address,address,address,address[]),(uint256,uint64,uint64,uint16,uint16,uint16,uint16,uint16),string,string,string,bool)'
      ](addresses, uints, shardName, shardSymbol, shardBaseURI, false);

    const rcpt = await deploymentTx.wait();
    const { deployment } = rcpt.events.find(
      (e) => e.event == 'ShardVaultDeployed',
    ).args;

    console.log(`\nSuccessfully deployed new ShardVault at: ${deployment}`);

    let shardVaults: ShardVault[] = [];
    const readVaults = readFile(`${dirPath}/${network}/ShardVaults.json`);

    if (readVaults.length == 0) {
      shardVaults = [];
    } else {
      shardVaults = JSON.parse(readVaults);
    }

    shardVaults.push({
      ShardVault: deployment,
      ShardCollectionName: shardName,
    });

    createFile(
      `${dirPath}/${network}/ShardVaults.json`,
      JSON.stringify(shardVaults),
    );
  } catch (err) {
    console.log('\n\nAn error occurred: ', err);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
