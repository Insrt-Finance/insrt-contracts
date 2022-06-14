import hre from 'hardhat';
import {
  SolidStateERC20Mock,
  SolidStateERC20Mock__factory,
} from '../typechain-types';
import { createDir, createFile, MockToken } from './utils/utils';

async function tokensToMockTokens(
  tokens: SolidStateERC20Mock[],
): Promise<MockToken[]> {
  const MockTokens: MockToken[] = [];

  for (let i = 0; i < tokens.length; i++) {
    let MockToken = {
      name: await tokens[i].name(),
      symbol: await tokens[i].symbol(),
      address: tokens[i].address,
    };
    MockTokens.push(MockToken);
  }

  return MockTokens;
}

async function main() {
  const ethers = hre.ethers;
  const [deployer] = await ethers.getSigners();
  let tokens: MockToken[];

  const dirPath = `data`;
  const network = hre.network.name;
  createDir(`/${dirPath}/${network}`);

  const mockNFTX: SolidStateERC20Mock = await new SolidStateERC20Mock__factory(
    deployer,
  ).deploy('MockNFTX', 'MNFTX');
  const mockApe: SolidStateERC20Mock = await new SolidStateERC20Mock__factory(
    deployer,
  ).deploy('MockApe', 'MAPE');
  const mockSand: SolidStateERC20Mock = await new SolidStateERC20Mock__factory(
    deployer,
  ).deploy('MockSand', 'MSand');
  const mockJpegd: SolidStateERC20Mock = await new SolidStateERC20Mock__factory(
    deployer,
  ).deploy('MockJpegd', 'MJPEGD');
  const mockAaveGotchi: SolidStateERC20Mock =
    await new SolidStateERC20Mock__factory(deployer).deploy(
      'MockAaveGotchi',
      'MAVG',
    );
  const mockAudio: SolidStateERC20Mock = await new SolidStateERC20Mock__factory(
    deployer,
  ).deploy('MockAudio', 'MAUD');
  const mockETH: SolidStateERC20Mock = await new SolidStateERC20Mock__factory(
    deployer,
  ).deploy('MockETH', 'METH');
  const mockRare: SolidStateERC20Mock = await new SolidStateERC20Mock__factory(
    deployer,
  ).deploy('MockRare', 'MRARE');

  tokens = await tokensToMockTokens([
    mockNFTX,
    mockApe,
    mockSand,
    mockJpegd,
    mockAaveGotchi,
    mockAudio,
    mockETH,
    mockRare,
  ]);

  createFile(`${dirPath}/${network}/mockTokens.json`, JSON.stringify(tokens));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.log('An unexpected error has occurred: ');
    console.error(error);
    process.exit(1);
  });
