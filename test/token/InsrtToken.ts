import { InsrtTokenMock, InsrtTokenMock__factory } from '../../typechain-types';
import { describeBehaviorOfSolidStateERC20 } from '@solidstate/spec';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers } from 'hardhat';
import { BigNumber } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

describe('InsrtToken', () => {
  let instance: InsrtTokenMock;
  let deployer: SignerWithAddress;

  const name: string = 'INSRT';
  const symbol: string = 'INSRT';
  const decimals: BigNumber = BigNumber.from('18');

  beforeEach(async () => {
    [deployer] = await ethers.getSigners();

    instance = await new InsrtTokenMock__factory(deployer).deploy(
      deployer.address,
    );
  });

  describeBehaviorOfSolidStateERC20(async () => instance, {
    mint: async (recipient, amount) =>
      await instance['__mint(address,uint256)'](recipient, amount),
    burn: async (recipient, amount) =>
      await instance['__burn(address,uint256)'](recipient, amount),
    allowance: (holder, spender) =>
      instance.callStatic.allowance(holder, spender),
    name,
    symbol,
    decimals,
    supply: ethers.utils.parseEther('100000000'),
  });
});
