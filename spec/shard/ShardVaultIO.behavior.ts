import hre, { ethers } from 'hardhat';
import {
  IShardCollection,
  IShardVault,
  ShardCollection,
  ShardCollection__factory,
} from '../../typechain-types';

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { BigNumber } from 'ethers';
import { shard } from '../../typechain-types/contracts';

export interface ShardVaultIOBehaviorArgs {}

function formatTokenId(internalId: BigNumber, address: string): BigNumber {
  let tokenId: BigNumber;
  tokenId = BigNumber.from(address).shl(96).add(internalId);
  return tokenId;
}

export function describeBehaviorOfShardVaultIO(
  deploy: () => Promise<IShardVault>,
  args: ShardVaultIOBehaviorArgs,
  skips?: string[],
) {
  let depositor: SignerWithAddress;
  let secondDepositor: SignerWithAddress;
  let instance: IShardVault;
  let shardCollection: ShardCollection;

  before(async () => {
    [depositor, secondDepositor] = await ethers.getSigners();
  });

  beforeEach(async () => {
    instance = await deploy();
    shardCollection = ShardCollection__factory.connect(
      await instance['shardCollection()'](),
      depositor,
    );
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
    it('mintstokens from ShardCollection to depositor', async () => {
      await instance.connect(depositor)['deposit()']({ value: depositAmount });

      expect(await shardCollection.balanceOf(depositor.address)).to.eq(
        depositAmount.div(ethers.utils.parseEther('1.0')),
      );
    });
    it('increases total shard supply', async () => {
      await instance.connect(depositor)['deposit()']({ value: depositAmount });

      expect(await instance.totalSupply()).to.eq(
        depositAmount.div(ethers.utils.parseEther('1.0')),
      );
    });
    it('increases count', async () => {
      await instance.connect(depositor)['deposit()']({ value: depositAmount });

      expect(await instance['count()']()).to.eq(
        depositAmount.div(ethers.utils.parseEther('1.0')),
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
        ).to.be.revertedWith('ShardVault__InvalidDepositAmount()');
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
        ).to.be.revertedWith('ShardVault__DepositForbidden()');
      });

      it('shard vault has invested', async () => {
        //TODO
        console.log('TODO');
      });
    });
  });

  describe('#withdraw(uint256[])', () => {
    const depositAmount = ethers.utils.parseEther('10');

    it('returns ETH analogous to tokens burnt', async () => {
      await instance.connect(depositor)['deposit()']({ value: depositAmount });
      const withdrawTokens = 5;
      const tokens = [];
      for (let i = 0; i < withdrawTokens; i++) {
        tokens.push(
          await shardCollection.tokenOfOwnerByIndex(depositor.address, i),
        );
      }

      expect(() =>
        instance.connect(depositor)['withdraw(uint256[])'](tokens),
      ).to.changeEtherBalances(
        [instance, depositor],
        [
          ethers.utils
            .parseEther(withdrawTokens.toString())
            .mul(ethers.constants.NegativeOne),
          ethers.utils.parseEther(withdrawTokens.toString()),
        ],
      );
    });

    it('decreases total supply by tokens burnt', async () => {
      await instance.connect(depositor)['deposit()']({ value: depositAmount });
      const withdrawTokens = 5;
      const tokens = [];
      for (let i = 0; i < withdrawTokens; i++) {
        tokens.push(
          await shardCollection.tokenOfOwnerByIndex(depositor.address, i),
        );
      }

      expect(await instance.totalSupply()).to.eq(
        depositAmount.div(ethers.utils.parseEther('1.0')),
      );

      await instance.connect(depositor)['withdraw(uint256[])'](tokens);

      expect(await instance.totalSupply()).to.eq(
        depositAmount
          .sub(ethers.utils.parseEther(withdrawTokens.toString()))
          .div(ethers.utils.parseEther('1.0')),
      );
    });

    describe('reverts if', () => {
      it('caller does not have enough shards', async () => {
        await expect(
          instance.connect(depositor).withdraw([ethers.constants.Zero]),
        ).to.be.revertedWith('ShardVault__InsufficientShards()');
      });
      it('caller is not shard owner', async () => {
        await instance
          .connect(depositor)
          ['deposit()']({ value: depositAmount });
        await instance
          .connect(secondDepositor)
          ['deposit()']({ value: depositAmount.div(ethers.constants.Two) });

        const withdrawTokens = 5;
        const tokens = [];
        for (let i = 0; i < withdrawTokens; i++) {
          tokens.push(
            await shardCollection.tokenOfOwnerByIndex(depositor.address, i),
          );
        }

        await expect(
          instance.connect(secondDepositor)['withdraw(uint256[])'](tokens),
        ).to.be.revertedWith('ShardVault__OnlyShardOwner()');
      });
      it('owned shards correspond to different vault', async () => {
        console.log('TODO');
      });
      it('vault is full', async () => {
        await instance
          .connect(depositor)
          ['deposit()']({ value: depositAmount });
        await instance
          .connect(secondDepositor)
          ['deposit()']({ value: depositAmount });

        const withdrawTokens = 5;
        const tokens = [];
        for (let i = 0; i < withdrawTokens; i++) {
          tokens.push(
            await shardCollection.tokenOfOwnerByIndex(depositor.address, i),
          );
        }

        await expect(
          instance.connect(secondDepositor)['withdraw(uint256[])'](tokens),
        ).to.be.revertedWith('ShardVault__WithdrawalForbidden()');
      });
      it('vault is invested', async () => {
        console.log('TODO');
      });
    });
  });

  describe('#formatTokenId(uint256)', () => {
    it('generates a unique token id using the vault address as a seed', async () => {
      const tokenIds = [];
      const testIds = [];
      for (let i = 0; i < 10; i++) {
        tokenIds.push(await instance.formatTokenId(i));
        testIds.push(
          formatTokenId(BigNumber.from(i.toString()), instance.address),
        );
        expect(tokenIds[i]).to.eq(testIds[i]);
      }
    });
    it('generates incrementally increasing tokenIds', async () => {
      const initialId = await instance['formatTokenId(uint256)'](
        ethers.constants.One,
      );
      const finalId = await instance['formatTokenId(uint256)'](
        BigNumber.from('101'),
      );

      expect(finalId.sub(initialId)).to.eq(BigNumber.from('100'));
    });
  });
  describe('#parseTokenId(uint256)', () => {
    it('returns the seeded vault address', async () => {
      const tokenId = await instance['formatTokenId(uint256)'](
        ethers.constants.One,
      );
      const [address] = await instance['parseTokenId(uint256)'](tokenId);

      expect(address).to.eq(instance.address);
    });

    it('returns the internal id used to generate the tokenId', async () => {
      const maxUint96 = ethers.constants.Two.pow(BigNumber.from('96')).sub(
        ethers.constants.One,
      );
      const tokenId = await instance['formatTokenId(uint256)'](maxUint96);
      const [, internalId] = await instance['parseTokenId(uint256)'](tokenId);

      expect(internalId).to.eq(maxUint96);
    });

    it('should fail when input is larger than maxUint96', async () => {
      const maxUint96 = ethers.constants.Two.pow(BigNumber.from('96')).sub(
        ethers.constants.One,
      );
      const tokenId = await instance['formatTokenId(uint256)'](
        maxUint96.add(ethers.constants.One),
      );
      const [, internalId] = await instance['parseTokenId(uint256)'](tokenId);

      expect(internalId).to.not.eq(maxUint96.add(ethers.constants.One));
      expect(internalId).to.eq(ethers.constants.Zero);
    });
  });
}
