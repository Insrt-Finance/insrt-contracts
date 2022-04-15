import {
  InsertMock,
  InsertMock__factory,
  XInsertMock,
  XInsertMock__factory,
} from '../typechain-types';
import { describeBehaviorOfERC20 } from '@solidstate/spec';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers } from 'hardhat';
import { BigNumber } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

describe('XInsert', () => {
  let instance: XInsertMock;
  let insertToken: InsertMock;
  let deployer: SignerWithAddress;

  const name: string = 'xInsert';
  const symbol: string = 'xINSRT';
  const decimals: BigNumber = BigNumber.from('18');

  beforeEach(async () => {
    [deployer] = await ethers.getSigners();

    insertToken = await new InsertMock__factory(deployer).deploy(
      deployer.address,
    );

    instance = await new XInsertMock__factory(deployer).deploy(
      insertToken.address,
    );
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

  describe('#deposit(uint256)', () => {
    it('mints tokens at 1:1 if supply is 0', async () => {});

    it('mints tokens with correct rate', async () => {});
  });

  describe('#withdraw(uint256)', () => {
    it('sends correct corresponding amount of Insert tokens', async () => {});
  });
});
