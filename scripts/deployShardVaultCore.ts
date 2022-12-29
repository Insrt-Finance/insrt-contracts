import hre from 'hardhat';
import {
  Core__factory,
  Core,
  ShardVaultDiamond,
  ShardVaultDiamond__factory,
  ShardVaultManager,
  ShardVaultManager__factory,
  ShardVaultIO,
  ShardVaultIO__factory,
  ShardVaultBase,
  ShardVaultBase__factory,
  MarketPlaceHelper,
  MarketPlaceHelper__factory,
  ShardVaultAdmin,
  ShardVaultAdmin__factory,
  ShardVaultView,
  ShardVaultView__factory,
  ERC165Base__factory,
  Ownable__factory,
} from '../typechain-types';
import {
  AuxilaryParamsStruct,
  createDir,
  createFile,
  JPEGParamsStruct,
  ShardCoreAddresses,
} from './utils/utils';

async function main() {
  const ethers = hre.ethers;
  const [deployer] = await ethers.getSigners();

  const CRYPTO_PUNKS_MARKET = '0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB';
  const PUSD = '0x466a756E9A7401B5e2444a3fCB3c2C12FBEa0a54';
  const PETH = '0x836A808d4828586A69364065A1e064609F5078c7';
  const JPEG = '0xE80C0cd204D654CEbe8dd64A4857cAb6Be8345a3';
  const PUSD_CITADEL = '0xF6Cbf5e56a8575797069c7A7FBED218aDF17e3b2';
  const PETH_CITADEL = '0x56D1b6Ac326e152C9fAad749F1F4f9737a049d46';
  const LP_FARM = '0xb271d2C9e693dde033d97f8A3C9911781329E4CA';
  const CURVE_PUSD_POOL = '0x8EE017541375F6Bcd802ba119bdDC94dad6911A1';
  const CURVE_PETH_POOL = '0x9848482da3Ee3076165ce6497eDA906E66bB85C5';
  const DAWN_OF_INSRT = '0x1522C79D2044BBC06f4368c07b88A32e9Cd64BD1';
  const JPEG_CARDS_CIG_STAKING = '0xFf9233825542977cd093E9Ffb8F0fC526164D3B7';
  const JPEG_CARDS = '0x83979584eC8c6D94D93f838A524049173DebA6F4';

  const treasury: string = deployer.address; //MUST CHANGE FOR MAINNET

  const dirPath = `data`;
  const network = hre.network.name;
  createDir(`/${dirPath}/${network}`);

  console.log(`\n\n\nDeploying Diamonds and Auxiliary contracts...`);
  console.log('---------------------------------------------------------\n');
  console.log('Deploying Core Diamond...');
  const coreDiamond: Core = await new Core__factory(deployer).deploy({
    gasPrice: ethers.utils.parseUnits('20', 'gwei'),
    gasLimit: 4000000,
  });
  console.log(`Successfully deployed Core Diamond at ${coreDiamond.address}`);

  console.log('Deploying ShardVaultDiamond...');
  const shardVaultDiamond: ShardVaultDiamond =
    await new ShardVaultDiamond__factory(deployer).deploy({
      gasPrice: ethers.utils.parseUnits('20', 'gwei'),
      gasLimit: 4000000,
    });
  console.log(
    `Successfully deployed ShardVaultDiamond at ${shardVaultDiamond.address}`,
  );

  console.log('Deploying MarketplaceHelper...');
  const marketplaceHelper: MarketPlaceHelper =
    await new MarketPlaceHelper__factory(deployer).deploy(CRYPTO_PUNKS_MARKET, {
      gasPrice: ethers.utils.parseUnits('20', 'gwei'),
      gasLimit: 4000000,
    });
  console.log(
    `Successfully deployed MarketplaceHelper at ${marketplaceHelper.address}`,
  );

  console.log(`\n\n\nDeploying Diamond Facets...`);
  console.log('---------------------------------------------------------\n');
  console.log('Deploying ShardVaultManager facet...');
  const shardVaultManagerImpl: ShardVaultManager =
    await new ShardVaultManager__factory(deployer).deploy(
      shardVaultDiamond.address,
      marketplaceHelper.address,
      { gasPrice: ethers.utils.parseUnits('20', 'gwei'), gasLimit: 4000000 },
    );
  console.log(
    `Successfully deployed ShardVaultManager facet at ${shardVaultManagerImpl.address}`,
  );

  const jpegParams: JPEGParamsStruct = {
    PUSD: PUSD,
    PETH: PETH,
    JPEG: JPEG,
    PUSD_CITADEL: PUSD_CITADEL,
    PETH_CITADEL: PETH_CITADEL,
    CURVE_PUSD_POOL: CURVE_PUSD_POOL,
    CURVE_PETH_POOL: CURVE_PETH_POOL,
    LP_FARM: LP_FARM,
    JPEG_CARDS_CIG_STAKING: JPEG_CARDS_CIG_STAKING,
    JPEG_CARDS: JPEG_CARDS,
  };

  const auxiliaryParams: AuxilaryParamsStruct = {
    TREASURY: treasury,
    PUNKS: CRYPTO_PUNKS_MARKET,
    DAWN_OF_INSRT: DAWN_OF_INSRT,
    MARKETPLACE_HELPER: marketplaceHelper.address,
  };

  console.log('Deploying ShardVaultBase facet...');
  const shardVaultBaseImpl: ShardVaultBase = await new ShardVaultBase__factory(
    deployer,
  ).deploy(jpegParams, auxiliaryParams, {
    gasPrice: ethers.utils.parseUnits('20', 'gwei'),
    gasLimit: 4000000,
  });
  console.log(
    `Successfully deployed ShardVaultBase facet at ${shardVaultBaseImpl.address}`,
  );
  console.log('Deploying ShardVaultIO facet...');
  const shardVaultIOImpl: ShardVaultIO = await new ShardVaultIO__factory(
    deployer,
  ).deploy(jpegParams, auxiliaryParams, {
    gasPrice: ethers.utils.parseUnits('20', 'gwei'),
    gasLimit: 4000000,
  });
  console.log(
    `Successfully deployed ShardVaultIO facet at ${shardVaultIOImpl.address}`,
  );

  console.log('Deploying ShardVaultAdmin facet...');
  const shardVaultAdminImpl: ShardVaultAdmin =
    await new ShardVaultAdmin__factory(deployer).deploy(
      jpegParams,
      auxiliaryParams,
      { gasPrice: ethers.utils.parseUnits('20', 'gwei'), gasLimit: 4000000 },
    );
  console.log(
    `Successfully deployed ShardVaultAdmin facet at ${shardVaultAdminImpl.address}`,
  );

  console.log('Deploying ShardVaultView facet...');
  const shardVaultViewImpl: ShardVaultView = await new ShardVaultView__factory(
    deployer,
  ).deploy(jpegParams, auxiliaryParams, {
    gasPrice: ethers.utils.parseUnits('20', 'gwei'),
    gasLimit: 4000000,
  });
  console.log(
    `Successfully deployed ShardVaultView facet at ${shardVaultViewImpl.address}`,
  );

  console.log(`\n\n\nCutting facets into Diamonds...`);
  console.log('---------------------------------------------------------');
  const coreFacetCuts = [shardVaultManagerImpl].map((facet) => {
    return {
      target: facet.address,
      action: 0,
      selectors: Object.keys(facet.interface.functions).map((fn) =>
        facet.interface.getSighash(fn),
      ),
    };
  });

  const ERC165Selectors = new Set();
  const IERC165 = ERC165Base__factory.createInterface();
  IERC165.fragments.map((f) => ERC165Selectors.add(IERC165.getSighash(f)));
  const OwnableSelectors = new Set();
  const IOwnable = Ownable__factory.createInterface();
  IOwnable.fragments.map((f) => OwnableSelectors.add(IOwnable.getSighash(f)));

  const shardVaultSelectors = new Set();

  const shardVaultFacetCuts = [
    shardVaultBaseImpl,
    shardVaultIOImpl,
    shardVaultViewImpl,
    shardVaultAdminImpl,
  ].map((facet) => {
    return {
      target: facet.address,
      action: 0,
      selectors: Object.keys(facet.interface.functions)
        .filter(
          (fn) => !shardVaultSelectors.has(fn) && shardVaultSelectors.add(fn),
        )
        .filter((fn) => !ERC165Selectors.has(facet.interface.getSighash(fn)))
        .map((fn) => facet.interface.getSighash(fn)),
    };
  });

  console.log('\nCutting Core facets into Core Diamond...');
  try {
    const coreCutTx = await coreDiamond
      .connect(deployer)
      .diamondCut(coreFacetCuts, ethers.constants.AddressZero, '0x', {
        gasPrice: ethers.utils.parseUnits('20', 'gwei'),
        gasLimit: 4000000,
      });
    await coreCutTx.wait();

    console.log('Successfully cut Core facets into Core Diamond');
  } catch (err) {
    console.log('An error occurred: ', err);
  }

  console.log('\n\nCutting ShardVault facets into ShardVault Diamond...');
  try {
    const shardVaultCutTx = await shardVaultDiamond
      .connect(deployer)
      .diamondCut(shardVaultFacetCuts, ethers.constants.AddressZero, '0x', {
        gasPrice: ethers.utils.parseUnits('20', 'gwei'),
        gasLimit: 4000000,
      });

    await shardVaultCutTx.wait();
    console.log('Successfully cut ShardVault facets into ShardVault Diamond');
  } catch (err) {
    console.log('An error occurred: ', err);
  }

  const shardCoreAddresses: ShardCoreAddresses = {
    CoreDiamond: coreDiamond.address,
    ShardVaultManager: shardVaultManagerImpl.address,
    MarketplaceHelper: marketplaceHelper.address,
    ShardVaultBase: shardVaultBaseImpl.address,
    ShardVaultDiamond: shardVaultDiamond.address,
    ShardVaultAdmin: shardVaultAdminImpl.address,
    ShardVaultView: shardVaultViewImpl.address,
    ShardVaultIO: shardVaultIOImpl.address,
  };

  createFile(
    `${dirPath}/${network}/shardVaultCoreDeployments.json`,
    JSON.stringify(shardCoreAddresses),
  );

  console.log('\n\nContract Addresses:');
  console.log('---------------------------------------------------------\n');
  console.log(`Core Diamond: ${coreDiamond.address}`);
  console.log(`ShardVaultManager Facet: ${shardVaultManagerImpl.address}`);
  console.log('\n---------------------------------------------------------\n');
  console.log(`MarketHelper: ${marketplaceHelper.address}`);
  console.log('\n---------------------------------------------------------\n');
  console.log(`ShardVault Diamond: ${shardVaultDiamond.address} `);
  console.log(`ShardVaultBase Facet: ${shardVaultBaseImpl.address}`);
  console.log(`ShardVaultIO Facet: ${shardVaultIOImpl.address} `);
  console.log(`ShardVaultAdmin Facet: ${shardVaultAdminImpl.address} `);
  console.log(`ShardVaultView Facet: ${shardVaultViewImpl.address}  \n\n\n`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
