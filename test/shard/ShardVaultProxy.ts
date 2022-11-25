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
  ShardCollection,
  ShardCollection__factory,
  ShardCollectionProxy,
  ShardCollectionProxy__factory,
  ERC165__factory,
  Ownable__factory,
  IShardCollection__factory,
  IShardCollection,
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
  let shardCollectionInstance: IShardCollection;
  let marketplaceHelper: IMarketPlaceHelper;

  let deployer: any;
  let jpegdOwner: any;

  const id = 1;
  const shardValue = ethers.utils.parseEther('1.0');
  const maxShards = BigNumber.from('20');

  //mainnet
  const CRYPTO_PUNKS_MARKET = '0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB';
  const BAYC = '0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D';
  const PUSD = '0x466a756E9A7401B5e2444a3fCB3c2C12FBEa0a54';
  const PETH = '0x836A808d4828586A69364065A1e064609F5078c7';
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

  interface FeeParamsStruct {
    saleFeeBP: BigNumber;
    acquisitionFeeBP: BigNumber;
    yieldFeeBP: BigNumber;
  }

  interface BufferParamsStruct {
    ltvBufferBP: BigNumber;
    ltvDeviationBP: BigNumber;
    conversionBuffer: BigNumber;
  }

  const feeParams: FeeParamsStruct = {
    saleFeeBP: saleFeeBP,
    acquisitionFeeBP: acquisitionFeeBP,
    yieldFeeBP: yieldFeeBP,
  };

  const pUSDBufferParams: BufferParamsStruct = {
    ltvBufferBP: ltvBufferBP,
    ltvDeviationBP: ltvDeviationBP,
    conversionBuffer: pUSDConversionBuffer,
  };

  const pETHBufferParams: BufferParamsStruct = {
    ltvBufferBP: ltvBufferBP,
    ltvDeviationBP: ltvDeviationBP,
    conversionBuffer: pETHConversionBuffer,
  };

  before(async () => {
    // TODO: must skip signers because they're not parameterized in SolidState spec
    [, , , deployer] = await ethers.getSigners();

    const marketplaceHelperDeployment = await new MarketPlaceHelper__factory(
      deployer,
    ).deploy(CRYPTO_PUNKS_MARKET);

    marketplaceHelper = IMarketPlaceHelper__factory.connect(
      marketplaceHelperDeployment.address,
      deployer,
    );

    const ERC165Selectors = new Set();
    const IERC165 = ERC165__factory.createInterface();
    IERC165.fragments.map((f) => ERC165Selectors.add(IERC165.getSighash(f)));
    const OwnableSelectors = new Set();
    const IOwnable = Ownable__factory.createInterface();
    IOwnable.fragments.map((f) => OwnableSelectors.add(IOwnable.getSighash(f)));

    const coreDiamond = await new Core__factory(deployer).deploy();
    const shardVaultDiamond = await new ShardVaultDiamond__factory(
      deployer,
    ).deploy();
    const shardCollectionProxy = await new ShardCollectionProxy__factory(
      deployer,
    ).deploy('ShardVaultCollection', 'SVC', 'shards');

    const shardCollectionFacetCuts = [
      await new ShardCollection__factory(deployer).deploy(),
    ].map(function (f) {
      return {
        target: f.address,
        action: 0,
        selectors: Object.keys(f.interface.functions)
          .filter((fn) => !ERC165Selectors.has(f.interface.getSighash(fn)))
          .filter((fn) => !OwnableSelectors.has(f.interface.getSighash(fn)))
          .map((fn) => f.interface.getSighash(fn)),
      };
    });

    const coreFacetCuts = [
      await new ShardVaultManager__factory(deployer).deploy(
        shardVaultDiamond.address,
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

    const shardVaultSelectors = new Set();

    const shardVaultFacetCuts = [
      await new ShardVaultIO__factory(deployer).deploy(
        shardCollectionProxy.address,
        PUSD,
        PETH,
        CRYPTO_PUNKS_MARKET,
        pusdCitadel,
        pethCitadel,
        lpFarm,
        curvePUSDPool,
        curvePETHPool,
        DAWN_OF_INSRT,
        marketplaceHelper.address,
      ),
      await new ShardVaultView__factory(deployer).deploy(
        shardCollectionProxy.address,
        PUSD,
        PETH,
        CRYPTO_PUNKS_MARKET,
        pusdCitadel,
        pethCitadel,
        lpFarm,
        curvePUSDPool,
        curvePETHPool,
        DAWN_OF_INSRT,
        marketplaceHelper.address,
      ),
      await new ShardVaultAdmin__factory(deployer).deploy(
        shardCollectionProxy.address,
        PUSD,
        PETH,
        CRYPTO_PUNKS_MARKET,
        pusdCitadel,
        pethCitadel,
        lpFarm,
        curvePUSDPool,
        curvePETHPool,
        DAWN_OF_INSRT,
        marketplaceHelper.address,
      ),
    ].map(function (f) {
      return {
        target: f.address,
        action: 0,
        selectors: Object.keys(f.interface.functions)
          .filter(
            (fn) => !shardVaultSelectors.has(fn) && shardVaultSelectors.add(fn),
          )
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

    await shardCollectionProxy.diamondCut(
      shardCollectionFacetCuts,
      ethers.constants.AddressZero,
      '0x',
    );

    core = ICore__factory.connect(coreDiamond.address, ethers.provider);

    const deployShardVaultTx = await core
      .connect(deployer)
      [
        'deployShardVault(address,address,address,uint256,uint16,uint16,(uint16,uint16,uint16),(uint256,uint16,uint16))'
      ](
        CRYPTO_PUNKS_MARKET,
        pusdPunkVault,
        pusdPunkVaultHelper,
        shardValue,
        maxShards,
        maxShardsPerUser,
        feeParams,
        pUSDBufferParams,
      );

    const { events } = await deployShardVaultTx.wait();
    const { deployment } = events.find(
      (e) => e.event === 'ShardVaultDeployed',
    ).args;

    instance = IShardVault__factory.connect(deployment, deployer);

    const deploySecondShardVaultTx = await core
      .connect(deployer)
      .connect(deployer)
      [
        'deployShardVault(address,address,address,uint256,uint16,uint16,(uint16,uint16,uint16),(uint256,uint16,uint16))'
      ](
        BAYC,
        baycVault,
        ethers.constants.AddressZero,
        shardValue,
        maxShards,
        maxShardsPerUser,
        feeParams,
        pUSDBufferParams,
      );

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
      .connect(deployer)
      [
        'deployShardVault(address,address,address,uint256,uint16,uint16,(uint16,uint16,uint16),(uint256,uint16,uint16))'
      ](
        CRYPTO_PUNKS_MARKET,
        pethPunkVault,
        pethPunkVaultHelper,
        shardValue,
        maxShards,
        maxShardsPerUser,
        feeParams,
        pETHBufferParams,
      );

    const pethDeploymentRcpt = await deployPethShardVaultTx.wait();
    const pethDeployment = pethDeploymentRcpt.events.find(
      (e) => e.event === 'ShardVaultDeployed',
    ).args;

    pethInstance = IShardVault__factory.connect(
      pethDeployment.deployment,
      deployer,
    );

    shardCollectionInstance = IShardCollection__factory.connect(
      shardCollectionProxy.address,
      deployer,
    );

    shardCollectionAddress.push(shardCollectionProxy.address);
    marketplaceHelperAddress.push(marketplaceHelper.address);

    await shardCollectionInstance
      .connect(deployer)
      ['addToWhitelist(address)'](deployment);

    await shardCollectionInstance
      .connect(deployer)
      ['addToWhitelist(address)'](secondDeployment.deployment);

    await shardCollectionInstance
      .connect(deployer)
      ['addToWhitelist(address)'](pethDeployment.deployment);

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
      shardCollection: shardCollectionAddress,
      marketplaceHelper: marketplaceHelperAddress,
      maxSupply: maxShards,
      shardValue: shardValue,
    },
  );
});
