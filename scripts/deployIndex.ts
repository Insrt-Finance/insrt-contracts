import hre from 'hardhat';
import { createFile, Index, readFile } from './utils/utils';

async function main() {
  const ethers = hre.ethers;
  const [deployer] = await ethers.getSigners();
  const coreDiamondAddress = '0xFeC91feBEBB9fbb4D519137E2FE7B9a347666C2d';

  const dirPath = `data`;
  const network = `arbitrum`;
  const indexManager = await ethers.getContractAt(
    'IndexManager',
    coreDiamondAddress,
  );

  const tokens = [
    '0x72e1774f3bf4aE87226dB7DA6811C9e20947Ac7e',
    '0x81cD5D50f2C607aF4bF0b7dEF4f9c93B93E45b1A',
  ];
  const weights = [
    ethers.utils.parseEther('0.5'),
    ethers.utils.parseEther('0.5'),
  ];
  const amounts = [ethers.utils.parseEther('5'), ethers.utils.parseEther('5')];

  let token;

  for (let i = 0; i < tokens.length; i++) {
    token = await ethers.getContractAt('SolidStateERC20', tokens[i]);
    await token.connect(deployer).approve(indexManager.address, amounts[i]);
  }

  const exitFee = ethers.BigNumber.from('0');

  console.log('\n\nDeploying an index with params: ');
  console.log('----------------------------------------------');
  console.log(`Underlying Index Tokens: ${tokens}`);
  console.log(`Underlying Index Token Weights: ${weights}`);
  console.log(`Amounts expected from deployer for initialization: ${amounts}`);
  console.log(`Exit Fee: ${exitFee}`);
  console.log('----------------------------------------------');
  try {
    const deploymentTx = await indexManager
      .connect(deployer)
      .deployIndex(tokens, weights, amounts, exitFee);
    const receipt = await deploymentTx.wait();
    const { deployment } = receipt.events.find(
      (e) => e.event == 'IndexDeployed',
    ).args;

    console.log(`\n\nSuccessfully deployed the Index at: ${deployment} !`);
    let indexes: Index[] = [];
    indexes = readFile(`${dirPath}/${network}/Indexes.json`);

    console.log(`IndexProxy address: ${deployment}`);
    indexes.push({ Index: deployment });

    createFile(`${dirPath}/${network}/Indexes.json`, JSON.stringify(indexes));
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
