import hre, { ethers } from 'hardhat';
import {
  ICore,
  ICore__factory,
  Core__factory,
  IShardVault,
  IShardVault__factory,
  ShardVaultDiamond__factory,
  ShardVaultManager__factory,
  ShardVaultIO__factory,
  ShardVaultView__factory,
  ShardVaultBase__factory,
  IERC165__factory,
  Ownable__factory,
  ShardVaultAdmin__factory,
  IMarketPlaceHelper,
  MarketPlaceHelper__factory,
  IMarketPlaceHelper__factory,
  ShardVaultProxy,
} from '../../typechain-types';
import { describeBehaviorOfShardVaultProxy } from '../../spec/shard/ShardVaultProxy.behavior';
import { BigNumber } from 'ethers';

describe('ShardVaultProxy', () => {
  const ethers = hre.ethers;
  let snapshotId: number;
  let core: ICore;
  let instance: IShardVault;
  let secondInstance: IShardVault;
  let pethInstance: IShardVault;
  let marketplaceHelper: IMarketPlaceHelper;

  let deployer: any;
  let authorized: any;
  let jpegdOwner: any;

  const id = 1;
  const shardValue = ethers.utils.parseEther('1.0');
  const maxShards = BigNumber.from('20');

  //mainnet
  const CRYPTO_PUNKS_MARKET = '0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB';
  const BAYC = '0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D';
  const PUSD = '0x466a756E9A7401B5e2444a3fCB3c2C12FBEa0a54';
  const PETH = '0x836A808d4828586A69364065A1e064609F5078c7';
  const JPEG = '0xE80C0cd204D654CEbe8dd64A4857cAb6Be8345a3';
  const pusdCitadel = '0xF6Cbf5e56a8575797069c7A7FBED218aDF17e3b2';
  const pethCitadel = '0x56D1b6Ac326e152C9fAad749F1F4f9737a049d46';
  const lpFarm = '0xb271d2C9e693dde033d97f8A3C9911781329E4CA';
  const curvePUSDPool = '0x8EE017541375F6Bcd802ba119bdDC94dad6911A1';
  const curvePETHPool = '0x9848482da3Ee3076165ce6497eDA906E66bB85C5';
  const DAWN_OF_INSRT = '0x1522C79D2044BBC06f4368c07b88A32e9Cd64BD1';
  const pusdPunkVault = '0xD636a2fC1C18A54dB4442c3249D5e620cf8fE98F';
  const pusdPunkVaultHelper = '0x810fdbc7E5Cfe998127a1f2Aa26f34E64e0364f4';
  const pethPunkVault = '0x4e5F305bFCa77b17f804635A9bA669e187d51719';
  const pethPunkVaultHelper = '0x2bE665ee27096344B8f015b1952D3dFDb4Db4691';
  const baycVault = '0x271c7603AAf2BD8F68e8Ca60f4A4F22c4920259f';
  const jpegdOwnerAddress = '0x51C2cEF9efa48e08557A361B52DB34061c025a1B';
  const JPEG_CARDS_CIG_STAKING = '0xFf9233825542977cd093E9Ffb8F0fC526164D3B7';
  const JPEG_CARDS = '0x83979584eC8c6D94D93f838A524049173DebA6F4';
  const maxShardsPerUser = BigNumber.from('10');
  const saleFeeBP = BigNumber.from('200');
  const acquisitionFeeBP = BigNumber.from('100');
  const yieldFeeBP = BigNumber.from('1000');
  const ltvBufferBP = BigNumber.from('500');
  const ltvDeviationBP = BigNumber.from('200');
  const pUSDConversionBuffer = BigNumber.from('1000178');
  const pETHConversionBuffer = BigNumber.from('1000269');
  const BASIS = BigNumber.from('10000');

  const shardCollectionAddress: string[] = [];
  const marketplaceHelperAddress: string[] = [];

  interface ShardVaultAddresses {
    shardVaultDiamond: string;
    marketPlaceHelper: string;
    collection: string;
    jpegdVault: string;
    jpegdVaultHelper: string;
    authorized: string[];
  }

  interface ShardVaultUints {
    shardValue: BigNumber;
    maxSupply: BigNumber;
    maxMintBalance: BigNumber;
    saleFeeBP: BigNumber;
    acquisitionFeeBP: BigNumber;
    yieldFeeBP: BigNumber;
    conversionBuffer: BigNumber;
    ltvBufferBP: BigNumber;
    ltvDeviationBP: BigNumber;
  }

  interface JPEGParamsStruct {
    PUSD: string;
    PETH: string;
    JPEG: string;
    JPEG_CARDS_CIG_STAKING: string;
    JPEG_CARDS: string;
    PUSD_CITADEL: string;
    PETH_CITADEL: string;
    CURVE_PUSD_POOL: string;
    CURVE_PETH_POOL: string;
    LP_FARM: string;
  }

  interface AuxilaryParamsStruct {
    MARKETPLACE_HELPER: string;
    PUNKS: string;
    DAWN_OF_INSRT: string;
    TREASURY: string;
  }

  const uintsPUSD: ShardVaultUints = {
    shardValue: shardValue,
    maxSupply: maxShards,
    maxMintBalance: maxShardsPerUser,
    saleFeeBP: saleFeeBP,
    acquisitionFeeBP: acquisitionFeeBP,
    yieldFeeBP: yieldFeeBP,
    ltvBufferBP: ltvBufferBP,
    ltvDeviationBP: ltvDeviationBP,
    conversionBuffer: pUSDConversionBuffer,
  };

  const uintsPETH: ShardVaultUints = {
    shardValue: shardValue,
    maxSupply: maxShards,
    maxMintBalance: maxShardsPerUser,
    saleFeeBP: saleFeeBP,
    acquisitionFeeBP: acquisitionFeeBP,
    yieldFeeBP: yieldFeeBP,
    ltvBufferBP: ltvBufferBP,
    ltvDeviationBP: ltvDeviationBP,
    conversionBuffer: pETHConversionBuffer,
  };

  before(async () => {
    // TODO: must skip signers because they're not parameterized in SolidState spec
    [, , , deployer, authorized] = await ethers.getSigners();

    const marketplaceHelperDeployment = await new MarketPlaceHelper__factory(
      deployer,
    ).deploy(CRYPTO_PUNKS_MARKET);

    marketplaceHelper = IMarketPlaceHelper__factory.connect(
      marketplaceHelperDeployment.address,
      deployer,
    );

    const ERC165Selectors = new Set();
    const IERC165 = IERC165__factory.createInterface();
    IERC165.fragments.map((f) => ERC165Selectors.add(IERC165.getSighash(f)));
    const OwnableSelectors = new Set();
    const IOwnable = Ownable__factory.createInterface();
    IOwnable.fragments.map((f) => OwnableSelectors.add(IOwnable.getSighash(f)));

    const coreDiamond = await new Core__factory(deployer).deploy();
    const shardVaultDiamond = await new ShardVaultDiamond__factory(
      deployer,
    ).deploy();

    const coreFacetCuts = [
      await new ShardVaultManager__factory(deployer).deploy(
        shardVaultDiamond.address,
        marketplaceHelper.address,
      ),
    ].map(function (f) {
      return {
        target: f.address,
        action: 0,
        selectors: Object.keys(f.interface.functions).map((fn) =>
          f.interface.getSighash(fn),
        ),
      };
    });

    const jpegParams: JPEGParamsStruct = {
      PUSD: PUSD,
      PETH: PETH,
      JPEG: JPEG,
      JPEG_CARDS_CIG_STAKING: JPEG_CARDS_CIG_STAKING,
      JPEG_CARDS: JPEG_CARDS,
      PUSD_CITADEL: pusdCitadel,
      PETH_CITADEL: pethCitadel,
      CURVE_PUSD_POOL: curvePUSDPool,
      CURVE_PETH_POOL: curvePETHPool,
      LP_FARM: lpFarm,
    };

    const auxiliaryPArams: AuxilaryParamsStruct = {
      PUNKS: CRYPTO_PUNKS_MARKET,
      DAWN_OF_INSRT: DAWN_OF_INSRT,
      MARKETPLACE_HELPER: marketplaceHelper.address,
      TREASURY: deployer.address,
    };

    const addressesPUSD: ShardVaultAddresses = {
      shardVaultDiamond: ethers.constants.AddressZero,
      marketPlaceHelper: ethers.constants.AddressZero,
      collection: CRYPTO_PUNKS_MARKET,
      jpegdVault: pusdPunkVault,
      jpegdVaultHelper: pusdPunkVaultHelper,
      authorized: [authorized.address],
    };

    const addressesPUSDTwo: ShardVaultAddresses = {
      shardVaultDiamond: ethers.constants.AddressZero,
      marketPlaceHelper: ethers.constants.AddressZero,
      collection: BAYC,
      jpegdVault: baycVault,
      jpegdVaultHelper: ethers.constants.AddressZero,
      authorized: [authorized.address],
    };

    const addressesPETH: ShardVaultAddresses = {
      shardVaultDiamond: ethers.constants.AddressZero,
      marketPlaceHelper: ethers.constants.AddressZero,
      collection: CRYPTO_PUNKS_MARKET,
      jpegdVault: pethPunkVault,
      jpegdVaultHelper: pethPunkVaultHelper,
      authorized: [authorized.address],
    };

    const shardVaultSelectors = new Set();

    const shardVaultFacetCuts = [
      await new ShardVaultIO__factory(deployer).deploy(
        jpegParams,
        auxiliaryPArams,
      ),
      await new ShardVaultView__factory(deployer).deploy(
        jpegParams,
        auxiliaryPArams,
      ),
      await new ShardVaultAdmin__factory(deployer).deploy(
        jpegParams,
        auxiliaryPArams,
      ),
      await new ShardVaultBase__factory(deployer).deploy(
        jpegParams,
        auxiliaryPArams,
      ),
    ].map(function (f) {
      return {
        target: f.address,
        action: 0,
        selectors: Object.keys(f.interface.functions)
          .filter(
            (fn) => !shardVaultSelectors.has(fn) && shardVaultSelectors.add(fn),
          )
          .filter((fn) => !ERC165Selectors.has(f.interface.getSighash(fn)))
          .map((fn) => f.interface.getSighash(fn)),
      };
    });

    await coreDiamond.diamondCut(
      coreFacetCuts,
      ethers.constants.AddressZero,
      '0x',
    );

    await shardVaultDiamond.diamondCut(
      shardVaultFacetCuts,
      ethers.constants.AddressZero,
      '0x',
    );

    core = ICore__factory.connect(coreDiamond.address, ethers.provider);
    const deployShardVaultTx = await core
      .connect(deployer)
      [
        'deployShardVault((address,address,address,address,address,address[]),(uint256,uint64,uint64,uint16,uint16,uint16,uint16,uint16),string,string,string,bool)'
      ](addressesPUSD, uintsPUSD, 'name', 'name', 'something', true);

    const { events } = await deployShardVaultTx.wait();
    const { deployment } = events.find(
      (e) => e.event === 'ShardVaultDeployed',
    ).args;

    const marketPlaceHelperProxy = ethers.utils.getAddress(
      BigNumber.from(events[0].data).mask(160).toHexString(),
    );

    instance = IShardVault__factory.connect(deployment, deployer);

    const deploySecondShardVaultTx = await core
      .connect(deployer)
      [
        'deployShardVault((address,address,address,address,address,address[]),(uint256,uint64,uint64,uint16,uint16,uint16,uint16,uint16),string,string,string,bool)'
      ](addressesPUSDTwo, uintsPUSD, 'name', 'name', 'something', true);

    const rcpt = await deploySecondShardVaultTx.wait();
    const secondDeployment = rcpt.events.find(
      (e) => e.event === 'ShardVaultDeployed',
    ).args;

    secondInstance = IShardVault__factory.connect(
      secondDeployment.deployment,
      deployer,
    );

    const deployPethShardVaultTx = await core
      .connect(deployer)
      [
        'deployShardVault((address,address,address,address,address,address[]),(uint256,uint64,uint64,uint16,uint16,uint16,uint16,uint16),string,string,string,bool)'
      ](addressesPETH, uintsPETH, 'name', 'name', 'something', false);

    const pethDeploymentRcpt = await deployPethShardVaultTx.wait();
    const pethDeployment = pethDeploymentRcpt.events.find(
      (e) => e.event === 'ShardVaultDeployed',
    ).args;

    pethInstance = IShardVault__factory.connect(
      pethDeployment.deployment,
      deployer,
    );

    marketplaceHelperAddress.push(marketPlaceHelperProxy);

    await hre.network.provider.request({
      method: 'hardhat_impersonateAccount',
      params: [jpegdOwnerAddress],
    });

    jpegdOwner = await ethers.getSigner(jpegdOwnerAddress);

    await (await ethers.getContractAt('INoContract', pusdCitadel))
      .connect(jpegdOwner)
      ['setContractWhitelisted(address,bool)'](instance.address, true);

    await (await ethers.getContractAt('INoContract', pusdCitadel))
      .connect(jpegdOwner)
      ['setContractWhitelisted(address,bool)'](secondInstance.address, true);

    await (await ethers.getContractAt('INoContract', pethCitadel))
      .connect(jpegdOwner)
      ['setContractWhitelisted(address,bool)'](pethInstance.address, true);

    await (await ethers.getContractAt('INoContract', lpFarm))
      .connect(jpegdOwner)
      ['setContractWhitelisted(address,bool)'](instance.address, true);

    await (await ethers.getContractAt('INoContract', lpFarm))
      .connect(jpegdOwner)
      ['setContractWhitelisted(address,bool)'](secondInstance.address, true);

    await (await ethers.getContractAt('INoContract', lpFarm))
      .connect(jpegdOwner)
      ['setContractWhitelisted(address,bool)'](pethInstance.address, true);
  });

  beforeEach(async () => {
    snapshotId = await ethers.provider.send('evm_snapshot', []);
  });

  afterEach(async () => {
    await ethers.provider.send('evm_revert', [snapshotId]);
  });

  describeBehaviorOfShardVaultProxy(
    async () => instance,
    async () => secondInstance,
    async () => pethInstance,
    {
      getProtocolOwner: async () => deployer,
      marketplaceHelper: marketplaceHelperAddress,
      maxSupply: maxShards,
      shardValue: shardValue,
    },
  );
});
