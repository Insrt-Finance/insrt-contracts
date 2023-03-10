import { getBalancerContractAddress } from '@balancer-labs/v2-deployments';
import hre from 'hardhat';
import {
  Core__factory,
  IndexDiamond,
  IndexDiamond__factory,
  IndexManager__factory,
  IndexBase__factory,
  IndexIO__factory,
  IVault,
  IVault__factory,
  IndexView__factory,
  IndexManager,
  IndexView,
  IndexIO,
  IndexBase,
  Core,
  IndexSettings,
  IndexSettings__factory,
} from '../typechain-types';
import { createDir, createFile, CoreAddresses } from './utils/utils';

async function main() {
  const ethers = hre.ethers;
  const [deployer] = await ethers.getSigners();

  const dirPath = `data`;
  const network = hre.network.name;
  createDir(`/${dirPath}/${network}`);

  const EXIT_FEE = ethers.constants.Zero;
  const balancerVaultAddress = await getBalancerContractAddress(
    '20210418-vault',
    'Vault',
    'arbitrum',
  );

  const investmentPoolFactoryAddress = await getBalancerContractAddress(
    '20210907-investment-pool',
    'InvestmentPoolFactory',
    'arbitrum',
  );

  const BALANCER_HELPERS = '0x77d46184d22CA6a3726a2F500c776767b6A3d6Ab'; // arbitrum
  const balancerVault: IVault = IVault__factory.connect(
    balancerVaultAddress,
    deployer,
  );

  const coreDiamond: Core = await new Core__factory(deployer).deploy();

  const indexDiamond: IndexDiamond = await new IndexDiamond__factory(
    deployer,
  ).deploy();

  const indexManagerImpl: IndexManager = await new IndexManager__factory(
    deployer,
  ).deploy(
    indexDiamond.address,
    investmentPoolFactoryAddress,
    balancerVault.address,
  );

  const coreFacetCuts = [indexManagerImpl].map((facet) => {
    return {
      target: facet.address,
      action: 0,
      selectors: Object.keys(facet.interface.functions).map((fn) =>
        facet.interface.getSighash(fn),
      ),
    };
  });

  const indexSelectors = new Set();

  const indexBaseImpl: IndexBase = await new IndexBase__factory(
    deployer,
  ).deploy(balancerVault.address, BALANCER_HELPERS, EXIT_FEE);
  const indexIOImpl: IndexIO = await new IndexIO__factory(deployer).deploy(
    balancerVault.address,
    BALANCER_HELPERS,
    EXIT_FEE,
  );
  const indexViewImpl: IndexView = await new IndexView__factory(
    deployer,
  ).deploy(balancerVault.address, BALANCER_HELPERS, EXIT_FEE);
  const indexSettingsImpl: IndexSettings = await new IndexSettings__factory(
    deployer,
  ).deploy(balancerVault.address, BALANCER_HELPERS, EXIT_FEE);
  const indexFacetCuts = [
    indexBaseImpl,
    indexIOImpl,
    indexViewImpl,
    indexSettingsImpl,
  ].map((facet) => {
    return {
      target: facet.address,
      action: 0,
      selectors: Object.keys(facet.interface.functions)
        .filter((fn) => !indexSelectors.has(fn) && indexSelectors.add(fn))
        .map((fn) => facet.interface.getSighash(fn)),
    };
  });

  console.log('\n\nCutting core facets into core diamond...');
  try {
    const coreCutTx = await coreDiamond
      .connect(deployer)
      .diamondCut(coreFacetCuts, ethers.constants.AddressZero, '0x');
    await coreCutTx.wait();

    console.log('\n\nSuccessfully cut core facets into core diamond!');
  } catch (err) {
    console.log('\n\nAn error occurred: ', err);
  }

  console.log('\n\nCutting index facets into index diamond...');
  try {
    const indexCutTx = await indexDiamond
      .connect(deployer)
      .diamondCut(indexFacetCuts, ethers.constants.AddressZero, '0x');

    await indexCutTx.wait();
    console.log('\n\nSuccessfully cut index facets into index diamond!');
  } catch (err) {
    console.log('\n\nAn error occurred: ', err);
  }

  const coreAddresses: CoreAddresses = {
    CoreDiamond: coreDiamond.address,
    IndexDiamond: indexDiamond.address,
    IndexManager: indexManagerImpl.address,
    IndexBase: indexBaseImpl.address,
    IndexIO: indexIOImpl.address,
    IndexView: indexViewImpl.address,
    IndexSettings: indexSettingsImpl.address,
  };

  createFile(
    `${dirPath}/${network}/deployments.json`,
    JSON.stringify(coreAddresses),
  );

  console.log(`\n\nCore Diamond Address: ${coreDiamond.address}`);
  console.log('----------------------------------------------');
  console.log('Facet Addresses for Core Diamond: ');
  console.log(`IndexManager Facet: ${indexManagerImpl.address}`);
  console.log('----------------------------------------------');

  console.log(`\n\nIndex Diamond Address: ${indexDiamond.address}`);
  console.log('----------------------------------------------');
  console.log('Facet Addresses for Index Diamond: ');
  console.log(`IndexBase Facet: ${indexBaseImpl.address}`);
  console.log(`IndexView Facet: ${indexViewImpl.address}`);
  console.log(`IndexIO Facet: ${indexIOImpl.address}`);
  console.log(`IndexSettings Facet: ${indexSettingsImpl.address}`);
  console.log('----------------------------------------------');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
