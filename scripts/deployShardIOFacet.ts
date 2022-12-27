import hre from 'hardhat';
import {
  ShardVaultDiamond,
  ShardVaultDiamond__factory,
  ShardVaultIO,
  ShardVaultIO__factory,
} from '../typechain-types';
import { AuxilaryParamsStruct, JPEGParamsStruct } from './utils/utils';

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
  const marketplaceHelperAddress: string = deployer.address; //MUST CHANGE TO DEPLOYMENT ADDRESS

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
    MARKETPLACE_HELPER: marketplaceHelperAddress,
  };

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
  const selectors = Object.keys(shardVaultIOImpl.interface.functions).map(
    (fn) => shardVaultIOImpl.interface.getSighash(fn),
  );
  console.log('ShardVaultIO selectors: ', selectors);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
