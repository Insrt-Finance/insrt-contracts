import hre, { ethers } from 'hardhat';
import {
  ICryptoPunkMarket,
  IShardCollection,
  IShardVault,
  ShardCollection,
  ShardCollection__factory,
} from '../../typechain-types';

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { BigNumber } from 'ethers';
import { formatTokenId } from './ShardVaultView.behavior';

export interface ShardVaultIOBehaviorArgs {
  getProtocolOwner: () => Promise<SignerWithAddress>;
}

export function describeBehaviorOfShardVaultIO(
  deploy: () => Promise<IShardVault>,
  secondDeploy: () => Promise<IShardVault>,
  args: ShardVaultIOBehaviorArgs,
  skips?: string[],
) {
  let owner: SignerWithAddress;
  let depositor: SignerWithAddress;
  let secondDepositor: SignerWithAddress;
  let instance: IShardVault;
  let secondInstance: IShardVault;
  let shardCollection: ShardCollection;
  let cryptoPunkMarket: ICryptoPunkMarket;
  let purchaseData: string;

  const punkId = BigNumber.from('2534');
  const CRYPTO_PUNKS_MARKET = '0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB';

  before(async () => {
    [depositor, secondDepositor] = await ethers.getSigners();
    owner = await args.getProtocolOwner();

    cryptoPunkMarket = await ethers.getContractAt(
      'ICryptoPunkMarket',
      CRYPTO_PUNKS_MARKET,
    );

    purchaseData = cryptoPunkMarket.interface.encodeFunctionData('buyPunk', [
      punkId,
    ]);
  });

  beforeEach(async () => {
    instance = await deploy();
    secondInstance = await secondDeploy();
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
    it('mints tokens from ShardCollection to depositor', async () => {
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
          ['deposit()']({ value: depositAmount.mul(ethers.constants.Two) });
        await expect(
          instance.connect(depositor)['deposit()']({ value: depositAmount }),
        ).to.be.revertedWith('ShardVault__DepositForbidden()');
      });

      it('vault is invested', async () => {
        await instance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await instance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('90') });

        await instance
          .connect(owner)
          ['purchasePunk(bytes,uint256)'](purchaseData, punkId);

        await expect(
          instance
            .connect(depositor)
            .deposit({ value: ethers.utils.parseEther('5') }),
        ).to.be.revertedWith('ShardVault__DepositForbidden()');
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
        await secondInstance
          .connect(depositor)
          .deposit({ value: depositAmount });
        const withdrawTokenId = formatTokenId(
          ethers.constants.One,
          secondInstance.address,
        );

        await expect(
          instance.connect(depositor)['withdraw(uint256[])']([withdrawTokenId]),
        ).to.be.revertedWith('ShardVault__VaultTokenIdMismatch()');
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
          instance.connect(depositor)['withdraw(uint256[])'](tokens),
        ).to.be.revertedWith('ShardVault__WithdrawalForbidden()');
      });
      it('vault is invested', async () => {
        await instance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await instance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('90') });

        await instance
          .connect(owner)
          ['purchasePunk(bytes,uint256)'](purchaseData, punkId);

        const withdrawTokenId = formatTokenId(
          ethers.constants.One,
          instance.address,
        );

        await expect(
          instance.connect(depositor)['withdraw(uint256[])']([withdrawTokenId]),
        ).to.be.revertedWith('ShardVault__WithdrawalForbidden()');
      });
    });
  });
}
