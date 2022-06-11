import hre from 'hardhat';
import {
  SolidStateERC20Mock,
  SolidStateERC20Mock__factory,
} from '../typechain-types';
import { createDir, createFile, CoreAddresses } from './utils/utils';

async function main() {
  const ethers = hre.ethers;
  const [deployer] = await ethers.getSigners();
  const tokens: string[] = [];

  const dirPath = `data`;
  const network = `arbitrum`;
  createDir(`/${dirPath}/${network}`);

  const tokenOne: SolidStateERC20Mock = await new SolidStateERC20Mock__factory(
    deployer,
  ).deploy();
  const tokenTwo: SolidStateERC20Mock = await new SolidStateERC20Mock__factory(
    deployer,
  ).deploy();

  tokens.push(tokenOne.address);
  tokens.push(tokenTwo.address);

  createFile(`${dirPath}/${network}/mockTokens.json`, JSON.stringify(tokens));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
