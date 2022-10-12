import hre, { ethers } from 'hardhat';
import { IShardVault } from '../../typechain-types';

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { BigNumber } from 'ethers';

export interface ShardVaultIOBehaviorArgs {}

export function describeBehaviorOfShardVaultIO(
  deploy: () => Promise<IShardVault>,
  args: ShardVaultIOBehaviorArgs,
  skips?: string[],
) {
  let depositor: SignerWithAddress;
  let instance: IShardVault;

  const shardValue = ethers.utils.parseEther('1.0');

  before(async () => {
    [depositor] = await ethers.getSigners();
  });

  beforeEach(async () => {
    instance = await deploy();
  });

  describe('#deposit()', () => {
    const depositAmount = ethers.utils.parseEther('10');
    it('transfers ETH from depositor to vault', async () => {
      await expect(() =>
        instance.connect(depositor)['deposit()']({ value: depositAmount }),
      ).to.changeEtherBalances(
        [instance, depositor],
        [depositAmount, depositAmount.mul(ethers.constants.NegativeOne)],
      );
    });
    it('tracks shards owed to depositor', async () => {
      await instance.connect(depositor)['deposit()']({ value: depositAmount });

      expect(await instance.depositorShards(depositor.address)).to.eq(
        depositAmount.div(shardValue),
      );
    });
    it('tracks total shards owed', async () => {
      await instance.connect(depositor)['deposit()']({ value: depositAmount });
      await instance.connect(depositor)['deposit()']({ value: depositAmount });

      expect(await instance.depositorShards(depositor.address)).to.eq(
        depositAmount.div(shardValue).mul(ethers.constants.Two),
      );
    });
    it('returns any excess ETH sent past maximum fundraise target', async () => {
      expect(() =>
        instance
          .connect(depositor)
          ['deposit()']({ value: depositAmount.mul(BigNumber.from('3')) }),
      ).to.changeEtherBalances(
        [instance, depositor],
        [
          depositAmount.mul(ethers.constants.Two),
          depositAmount
            .mul(ethers.constants.Two)
            .mul(ethers.constants.NegativeOne),
        ],
      );
    });

    describe('reverts if', () => {
      it('msg value is not a multiple of shard value', async () => {
        const invalidDepositAmount = ethers.utils.parseEther('1.5');
        await expect(
          instance
            .connect(depositor)
            ['deposit()']({ value: invalidDepositAmount }),
        ).to.be.revertedWith('InvalidDepositAmount()');
      });

      it('vault is full', async () => {
        await instance
          .connect(depositor)
          ['deposit()']({ value: depositAmount });
        await instance
          .connect(depositor)
          ['deposit()']({ value: depositAmount });
        await expect(
          instance.connect(depositor)['deposit()']({ value: depositAmount }),
        ).to.be.revertedWith('DepositForbidden()');
      });

      it('shard vault has invested', async () => {
        //TODO
        console.log('TODO');
      });
    });
  });
}
