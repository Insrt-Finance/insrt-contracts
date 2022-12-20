import fs from 'fs';
import { BigNumber, ethers } from 'ethers';

export interface CoreAddresses {
  CoreDiamond: string;
  IndexDiamond: string;
  IndexManager: string;
  IndexBase: string;
  IndexIO: string;
  IndexView: string;
  IndexSettings: string;
}

export interface ShardCoreAddresses {
  CoreDiamond: string;
  ShardVaultManager: string;
  MarketplaceHelper: string;
  ShardVaultDiamond: string;
  ShardVaultBase: string;
  ShardVaultIO: string;
  ShardVaultView: string;
  ShardVaultAdmin: string;
}

export interface ShardVault {
  ShardVault: string;
  ShardCollectionName: string;
}

export interface JPEGParamsStruct {
  PUSD: string;
  PETH: string;
  JPEG: string;
  PUSD_CITADEL: string;
  PETH_CITADEL: string;
  CURVE_PUSD_POOL: string;
  CURVE_PETH_POOL: string;
  LP_FARM: string;
  JPEG_CARDS_CIG_STAKING: string;
}

export interface AuxilaryParamsStruct {
  TREASURY: string;
  PUNKS: string;
  DAWN_OF_INSRT: string;
  MARKETPLACE_HELPER: string;
}

export interface ShardVaultAddresses {
  shardVaultDiamond: string;
  marketPlaceHelper: string;
  collection: string;
  jpegdVault: string;
  jpegdVaultHelper: string;
  authorized: string[];
}

export interface ShardVaultUints {
  shardValue: BigNumber;
  maxSupply: BigNumber;
  maxMintBalance: BigNumber;
  saleFeeBP: BigNumber;
  acquisitionFeeBP: BigNumber;
  yieldFeeBP: BigNumber;
  ltvBufferBP: BigNumber;
  ltvDeviationBP: BigNumber;
}

export interface EncodedCallStruct {
  data: string;
  value: BigNumber;
  target: string;
}

export interface Index {
  Index: string;
}

export interface MockToken {
  name: string;
  symbol: string;
  address: string;
}

export function parseEncodedCalls(callsString: string): EncodedCallStruct[] {
  let calls: EncodedCallStruct[] = [];
  for (let call in callsString.split('--')) {
    let callComponents = call.split('$');
    calls.push({
      data: callComponents[0],
      value: BigNumber.from(ethers.utils.parseEther(callComponents[1])),
      target: callComponents[2],
    });
  }
  return calls;
}

export function readFile(filePath: string): any {
  if (fs.existsSync(filePath)) {
    try {
      return fs.readFileSync(filePath, 'utf8');
    } catch (error) {
      console.error(`An error occured: `, error);
    }
  } else {
    return [];
  }
}

export function createDir(_dirPath: string): void {
  if (!fs.existsSync(_dirPath)) {
    try {
      fs.mkdirSync(process.cwd() + _dirPath, { recursive: true });
    } catch (error) {
      console.error(`An error occurred: `, error);
    }
  }
}

export function createFile(
  filePath: string,
  fileContent: string | NodeJS.ArrayBufferView,
): void {
  try {
    fs.writeFileSync(filePath, fileContent);
  } catch (error) {
    console.error(`An error occurred: `, error);
  }
}
