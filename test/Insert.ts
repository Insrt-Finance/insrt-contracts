import { InsertMock, InsertMock__factory } from '../typechain-types';
import { describeBehaviorOfERC20 } from '@solidstate/spec';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers } from 'hardhat';
import { BigNumber } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

describe('Insert', () => {
  let instance: InsertMock;
  let deployer: SignerWithAddress;

  const name: string = 'Insert';
  const symbol: string = 'INSRT';
  const decimals: BigNumber = BigNumber.from('18');

  beforeEach(async () => {
    [deployer] = await ethers.getSigners();

    instance = await new InsertMock__factory(deployer).deploy();
  });

  describeBehaviorOfERC20({
    deploy: async () => instance,
    mint: async (recipient, amount) =>
      await instance['__mint(address,uint256)'](recipient, amount),
    burn: async (recipient, amount) =>
      await instance['__burn(address,uint256)'](recipient, amount),
    name,
    symbol,
    decimals,
    supply: ethers.constants.Zero,
  });
});
