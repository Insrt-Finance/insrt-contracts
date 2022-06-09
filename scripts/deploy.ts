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
} from '../typechain-types';

async function main() {
  const ethers = hre.ethers;
  const [deployer] = await ethers.getSigners();

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

  const indexManagerFacet: IndexManager = await new IndexManager__factory(
    deployer,
  ).deploy(
    indexDiamond.address,
    investmentPoolFactoryAddress,
    balancerVault.address,
  );

  const coreFacetCuts = [indexManagerFacet].map((facet) => {
    return {
      target: facet.address,
      action: 0,
      selectors: Object.keys(facet.interface.functions).map((fn) =>
        facet.interface.getSighash(fn),
      ),
    };
  });

  const indexSelectors = new Set();

  const indexBaseFacet: IndexBase = await new IndexBase__factory(
    deployer,
  ).deploy(balancerVault.address, BALANCER_HELPERS);
  const indexIOFacet: IndexIO = await new IndexIO__factory(deployer).deploy(
    balancerVault.address,
    BALANCER_HELPERS,
  );
  const indexViewFacet: IndexView = await new IndexView__factory(
    deployer,
  ).deploy(balancerVault.address, BALANCER_HELPERS);
  const indexFacetCuts = [indexBaseFacet, indexIOFacet, indexViewFacet].map(
    (facet) => {
      return {
        target: facet.address,
        action: 0,
        selectors: Object.keys(facet.interface.functions)
          .filter((fn) => !indexSelectors.has(fn) && indexSelectors.add(fn))
          .map((fn) => facet.interface.getSighash(fn)),
      };
    },
  );

  await coreDiamond
    .connect(deployer)
    .diamondCut(coreFacetCuts, ethers.constants.AddressZero, '0x');

  await indexDiamond
    .connect(deployer)
    .diamondCut(indexFacetCuts, ethers.constants.AddressZero, '0x');

  console.log(`\n\nCore Diamond Address: ${coreDiamond.address}`);
  console.log('Facet Addresses for Core Diamond: ');
  console.log('----------------------------------------------');
  console.log(`IndexManager Facet: ${indexManagerFacet.address}`);

  console.log(`\n\nIndex Diamond Address: ${indexDiamond.address}`);
  console.log('Facet Addresses for Index Diamond: ');
  console.log('----------------------------------------------');
  console.log(`IndexBase Facet: ${indexBaseFacet.address}`);
  console.log(`IndexView Facet: ${indexViewFacet.address}`);
  console.log(`IndexIO Facet: ${indexIOFacet.address}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
