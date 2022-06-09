import hre from 'hardhat';
import { createFile, Index, readFile } from './utils/utils';

async function main() {
  const ethers = hre.ethers;
  const [deployer] = await ethers.getSigners();
  const coreDiamondAddress = '';

  const dirPath = `data`;
  const network = `arbitrum`;
  const indexManager = await ethers.getContractAt(
    'IndexManager',
    coreDiamondAddress,
  );

  const tokens = [];
  const weights = [];
  const amounts = [];
  const exitFee = ethers.BigNumber.from('0');

  const deploymentTx = await indexManager
    .connect(deployer)
    .deployIndex(tokens, weights, amounts, exitFee);

  const receipt = await deploymentTx.wait();
  const { deployment } = receipt.events.find(
    (e) => e.event == 'IndexDeployed',
  ).args;

  let indexes: Index[] = [];
  indexes = readFile(`${dirPath}/${network}/Indexes.json`);

  console.log(`IndexProxy address: ${deployment}`);
  indexes.push({ Index: deployment });

  createFile(`${dirPath}/${network}/Indexes.json`, JSON.stringify(indexes));
}
