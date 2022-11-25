import hre, { ethers } from 'hardhat';
import {
  ICryptoPunkMarket,
  IMarketPlaceHelper,
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
  let thirdDepositor: SignerWithAddress;
  let instance: IShardVault;
  let secondInstance: IShardVault;
  let shardCollection: ShardCollection;
  let cryptoPunkMarket: ICryptoPunkMarket;
  let purchaseDataPUSD: string[];
  let targets: string[];

  const punkId = BigNumber.from('2534');
  const CRYPTO_PUNKS_MARKET = '0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB';
  const dawnOfInsrtID = BigNumber.from('111');
  const secondDawnOfInsrtID = BigNumber.from('654');
  const dawnOfInsrtOwnerAddress = '0x736011B7d04d8a014EFdAe6a653E3405f3CDC720';
  const secondDawnOfInsrtOwnerAddress =
    '0x0F4BC970e348A061B69D05B7e2E5c13EB687E5e3';
  const DAWN_OF_INSRT = '0x1522C79D2044BBC06f4368c07b88A32e9Cd64BD1';
  const punkPurchaseCallsPUSD: IMarketPlaceHelper.EncodedCallStruct[] = [];

  before(async () => {
    [depositor, secondDepositor, thirdDepositor] = await ethers.getSigners();
    owner = await args.getProtocolOwner();

    cryptoPunkMarket = await ethers.getContractAt(
      'ICryptoPunkMarket',
      CRYPTO_PUNKS_MARKET,
    );

    await hre.network.provider.request({
      method: 'hardhat_impersonateAccount',
      params: [dawnOfInsrtOwnerAddress],
    });

    await hre.network.provider.request({
      method: 'hardhat_impersonateAccount',
      params: [secondDawnOfInsrtOwnerAddress],
    });

    const dawnOfInsrtOwner = await ethers.getSigner(dawnOfInsrtOwnerAddress);

    const secondDawnOfInsrtOwner = await ethers.getSigner(
      secondDawnOfInsrtOwnerAddress,
    );

    const dawnOfInsrt = await ethers.getContractAt('IERC721', DAWN_OF_INSRT);

    await dawnOfInsrt
      .connect(dawnOfInsrtOwner)
      ['transferFrom(address,address,uint256)'](
        dawnOfInsrtOwner.address,
        depositor.address,
        dawnOfInsrtID,
      );

    await dawnOfInsrt
      .connect(secondDawnOfInsrtOwner)
      ['transferFrom(address,address,uint256)'](
        secondDawnOfInsrtOwner.address,
        secondDepositor.address,
        secondDawnOfInsrtID,
      );
  });

  beforeEach(async () => {
    instance = await deploy();
    secondInstance = await secondDeploy();
    shardCollection = ShardCollection__factory.connect(
      await instance['shardCollection()'](),
      depositor,
    );

    let punkPurchaseData = cryptoPunkMarket.interface.encodeFunctionData(
      'buyPunk',
      [punkId],
    );

    let transferDataPUSDVault = cryptoPunkMarket.interface.encodeFunctionData(
      'transferPunk',
      [instance.address, punkId],
    );

    const price = (
      await cryptoPunkMarket['punksOfferedForSale(uint256)'](punkId)
    ).minValue;

    punkPurchaseCallsPUSD[0] = {
      data: punkPurchaseData,
      value: price,
      target: CRYPTO_PUNKS_MARKET,
    };

    punkPurchaseCallsPUSD[1] = {
      data: transferDataPUSDVault,
      value: 0,
      target: CRYPTO_PUNKS_MARKET,
    };
  });

  describe('::ShardVaultIO', () => {
    describe('#deposit()', () => {
      const depositAmount = ethers.utils.parseEther('10');
      it('transfers ETH from depositor to vault', async () => {
        await instance.connect(owner)['setIsEnabled(bool)'](true);
        await expect(() =>
          instance.connect(depositor)['deposit()']({ value: depositAmount }),
        ).to.changeEtherBalances(
          [instance, depositor],
          [depositAmount, depositAmount.mul(ethers.constants.NegativeOne)],
        );
      });
      it('mints shards from ShardCollection to depositor', async () => {
        await instance.connect(owner)['setIsEnabled(bool)'](true);
        await instance
          .connect(depositor)
          ['deposit()']({ value: depositAmount });

        expect(await shardCollection.balanceOf(depositor.address)).to.eq(
          depositAmount.div(ethers.utils.parseEther('1.0')),
        );
      });
      it('increases total shard supply', async () => {
        await instance.connect(owner)['setIsEnabled(bool)'](true);
        await instance
          .connect(depositor)
          ['deposit()']({ value: depositAmount });

        expect(await instance.totalSupply()).to.eq(
          depositAmount.div(ethers.utils.parseEther('1.0')),
        );
      });
      it('increases count', async () => {
        await instance.connect(owner)['setIsEnabled(bool)'](true);
        await instance
          .connect(depositor)
          ['deposit()']({ value: depositAmount });

        expect(await instance['count()']()).to.eq(
          depositAmount.div(ethers.utils.parseEther('1.0')),
        );
      });
      it('increases userShards', async () => {
        await instance.connect(owner)['setIsEnabled(bool)'](true);
        await instance
          .connect(depositor)
          ['deposit()']({ value: depositAmount });

        expect(
          await instance['shardBalances(address)'](depositor.address),
        ).to.eq(depositAmount.div(ethers.utils.parseEther('1')));
      });
      it('returns any excess ETH after MaxUserShards is reached', async () => {
        await instance.connect(owner)['setIsEnabled(bool)'](true);
        const depositOneAmount = ethers.utils.parseEther('5');
        const depositTwoAmount = ethers.utils.parseEther('6');

        await expect(() =>
          instance.connect(depositor)['deposit()']({ value: depositOneAmount }),
        ).to.changeEtherBalances(
          [instance, depositor],
          [
            depositOneAmount,
            depositOneAmount.mul(ethers.constants.NegativeOne),
          ],
        );

        const excess = depositTwoAmount
          .add(depositOneAmount)
          .sub(
            BigNumber.from(
              (await instance['maxUserShards()']()).toString(),
            ).mul(ethers.utils.parseEther('1')),
          );
        const change = depositTwoAmount.sub(excess);

        await expect(() =>
          instance.connect(depositor)['deposit()']({ value: depositTwoAmount }),
        ).to.changeEtherBalances(
          [instance, depositor],
          [change, change.mul(ethers.constants.NegativeOne)],
        );
      });
      it('returns any excess ETH after maxSupply is reached, if depositor has not reached MaxUserShards', async () => {
        await instance.connect(owner)['setIsEnabled(bool)'](true);
        const depositOneAmount = ethers.utils.parseEther('5');
        const depositTwoAmount = ethers.utils.parseEther('6');

        await instance
          .connect(depositor)
          ['deposit()']({ value: depositAmount });
        await instance
          .connect(secondDepositor)
          ['deposit()']({ value: depositOneAmount });

        const excess = depositAmount
          .add(depositOneAmount)
          .add(depositTwoAmount)
          .sub(
            BigNumber.from((await instance['maxSupply()']()).toString()).mul(
              ethers.utils.parseEther('1'),
            ),
          );

        const change = depositTwoAmount.sub(excess);
        await expect(() =>
          instance
            .connect(thirdDepositor)
            ['deposit()']({ value: depositTwoAmount }),
        ).to.changeEtherBalances(
          [instance, thirdDepositor],
          [change, change.mul(ethers.constants.NegativeOne)],
        );
      });
      it('during whitelist, returns any excess ETH after whitelistShards is reached, if depositor has not reached MaxUserShards', async () => {
        const depositOneAmount = ethers.utils.parseEther('5');
        const depositTwoAmount = ethers.utils.parseEther('6');
        const { timestamp: latestTS } = await ethers.provider.getBlock(
          'latest',
        );
        const whitelistEndsAt = BigNumber.from(latestTS.toString()).add(
          BigNumber.from('10000'),
        );
        const whitelistShards = BigNumber.from('10');

        await instance
          .connect(owner)
          ['initiateWhitelistAndDeposits(uint64,uint16)'](
            whitelistEndsAt,
            whitelistShards,
          );

        await instance
          .connect(depositor)
          ['deposit()']({ value: depositOneAmount });

        const excess = depositOneAmount
          .add(depositTwoAmount)
          .sub(
            BigNumber.from(
              (await instance['reservedShards()']()).toString(),
            ).mul(await instance['shardValue()']()),
          );
        const change = depositTwoAmount.sub(excess);
        await expect(() =>
          instance
            .connect(secondDepositor)
            ['deposit()']({ value: depositTwoAmount }),
        ).to.changeEtherBalances(
          [instance, secondDepositor],
          [change, change.mul(ethers.constants.NegativeOne)],
        );
      });

      describe('reverts if', () => {
        it('deposits are not enabled', async () => {
          await expect(
            instance.connect(depositor)['deposit()']({ value: depositAmount }),
          ).to.be.revertedWithCustomError(instance, 'ShardVault__NotEnabled');
        });

        it('depositor already holds maximum allowed shards', async () => {
          await instance.connect(owner)['setIsEnabled(bool)'](true);
          await instance
            .connect(depositor)
            ['deposit()']({ value: depositAmount });
          await expect(
            instance.connect(depositor)['deposit()']({ value: depositAmount }),
          ).to.be.revertedWithCustomError(
            instance,
            'ShardVault__MaxUserShards',
          );
        });

        it('msg value is not a multiple of shard value', async () => {
          await instance.connect(owner)['setIsEnabled(bool)'](true);
          const invalidDepositAmount = ethers.utils.parseEther('1.5');
          await expect(
            instance
              .connect(depositor)
              ['deposit()']({ value: invalidDepositAmount }),
          ).to.be.revertedWithCustomError(
            instance,
            'ShardVault__InvalidDepositAmount',
          );
        });

        it('attempted deposit after maxSupply has been reached', async () => {
          await instance.connect(owner)['setIsEnabled(bool)'](true);
          await instance
            .connect(owner)
            ['setMaxUserShards(uint16)'](BigNumber.from('200'));
          await instance
            .connect(depositor)
            ['deposit()']({ value: depositAmount });
          await instance
            .connect(depositor)
            ['deposit()']({ value: depositAmount.mul(ethers.constants.Two) });
          await expect(
            instance.connect(depositor)['deposit()']({ value: depositAmount }),
          ).to.be.revertedWithCustomError(
            instance,
            'ShardVault__DepositForbidden',
          );
        });

        it('shard vault has invested', async () => {
          await instance.connect(owner)['setIsEnabled(bool)'](true);
          await instance
            .connect(owner)
            ['setMaxUserShards(uint16)'](BigNumber.from('200'));
          await instance.connect(owner).setMaxSupply(BigNumber.from('200'));
          await instance
            .connect(depositor)
            .deposit({ value: ethers.utils.parseEther('100') });

          await instance
            .connect(owner)
            ['purchasePunk((bytes,uint256,address)[],uint256)'](
              punkPurchaseCallsPUSD,
              punkId,
            );

          await expect(
            instance.connect(depositor)['deposit()']({ value: depositAmount }),
          ).to.be.revertedWithCustomError(
            instance,
            'ShardVault__DepositForbidden',
          );
        });

        it('during whitelist, depositor does not hold DAWN_OF_INSRT NFT', async () => {
          const { timestamp: latestTS } = await ethers.provider.getBlock(
            'latest',
          );

          const whitelistEndsAt = BigNumber.from(latestTS.toString()).add(
            BigNumber.from('10000'),
          );
          const whitelistShards = BigNumber.from('50');
          await instance
            .connect(owner)
            ['initiateWhitelistAndDeposits(uint64,uint16)'](
              whitelistEndsAt,
              whitelistShards,
            );

          await expect(
            instance.connect(thirdDepositor).deposit({ value: depositAmount }),
          ).to.be.revertedWithCustomError(
            instance,
            'ShardVault__NotWhitelisted',
          );
        });

        it('during whitelist, attempted deposit after whitelistShards have been reached', async () => {
          const { timestamp: latestTS } = await ethers.provider.getBlock(
            'latest',
          );

          const whitelistEndsAt = BigNumber.from(latestTS.toString()).add(
            BigNumber.from('10000'),
          );
          const whitelistShards = BigNumber.from('5');
          await instance
            .connect(owner)
            ['initiateWhitelistAndDeposits(uint64,uint16)'](
              whitelistEndsAt,
              whitelistShards,
            );

          await instance.connect(depositor).deposit({ value: depositAmount });

          await expect(
            instance.connect(depositor).deposit({ value: depositAmount }),
          ).to.be.revertedWithCustomError(
            instance,
            'ShardVault__DepositForbidden',
          );
        });
      });
    });

    describe('#withdraw(uint256[])', () => {
      const depositAmount = ethers.utils.parseEther('10');

      it('returns ETH analogous to shards burnt', async () => {
        await instance.connect(owner)['setIsEnabled(bool)'](true);
        await instance
          .connect(depositor)
          ['deposit()']({ value: depositAmount });
        const withdrawShards = 5;
        const shards = [];
        for (let i = 0; i < withdrawShards; i++) {
          shards.push(
            await shardCollection.tokenOfOwnerByIndex(depositor.address, i),
          );
        }

        expect(() =>
          instance.connect(depositor)['withdraw(uint256[])'](shards),
        ).to.changeEtherBalances(
          [instance, depositor],
          [
            ethers.utils
              .parseEther(withdrawShards.toString())
              .mul(ethers.constants.NegativeOne),
            ethers.utils.parseEther(withdrawShards.toString()),
          ],
        );
      });

      it('decreases total supply by shards burnt', async () => {
        await instance.connect(owner)['setIsEnabled(bool)'](true);
        await instance
          .connect(depositor)
          ['deposit()']({ value: depositAmount });
        const withdrawShards = 5;
        const shards = [];
        for (let i = 0; i < withdrawShards; i++) {
          shards.push(
            await shardCollection.tokenOfOwnerByIndex(depositor.address, i),
          );
        }

        expect(await instance.totalSupply()).to.eq(
          depositAmount.div(ethers.utils.parseEther('1.0')),
        );

        await instance.connect(depositor)['withdraw(uint256[])'](shards);

        expect(await instance.totalSupply()).to.eq(
          depositAmount
            .sub(ethers.utils.parseEther(withdrawShards.toString()))
            .div(ethers.utils.parseEther('1.0')),
        );
      });

      describe('reverts if', () => {
        it('caller does not have enough shards', async () => {
          await expect(
            instance.connect(depositor).withdraw([ethers.constants.Zero]),
          ).to.be.revertedWithCustomError(
            instance,
            'ShardVault__InsufficientShards',
          );
        });
        it('caller is not shard owner', async () => {
          await instance.connect(owner)['setIsEnabled(bool)'](true);
          await instance
            .connect(depositor)
            ['deposit()']({ value: depositAmount });
          await instance
            .connect(secondDepositor)
            ['deposit()']({ value: depositAmount.div(ethers.constants.Two) });

          const withdrawShards = 5;
          const shards = [];
          for (let i = 0; i < withdrawShards; i++) {
            shards.push(
              await shardCollection.tokenOfOwnerByIndex(depositor.address, i),
            );
          }

          await expect(
            instance.connect(secondDepositor)['withdraw(uint256[])'](shards),
          ).to.be.revertedWithCustomError(
            instance,
            'ShardVault__NotShardOwner',
          );
        });
        it('owned shards correspond to different vault', async () => {
          await instance.connect(owner)['setIsEnabled(bool)'](true);
          await secondInstance.connect(owner)['setIsEnabled(bool)'](true);
          await instance
            .connect(depositor)
            ['deposit()']({ value: depositAmount });
          await secondInstance
            .connect(depositor)
            ['deposit()']({ value: depositAmount });

          const withdrawShards = 5;
          const shards = [];
          for (let i = 0; i < withdrawShards; i++) {
            shards.push(
              await shardCollection.tokenOfOwnerByIndex(depositor.address, i),
            );
          }

          await expect(
            secondInstance.connect(depositor)['withdraw(uint256[])'](shards),
          ).to.be.revertedWithCustomError(
            instance,
            'ShardVault__VaultTokenIdMismatch',
          );
        });
        it('vault is full', async () => {
          await instance.connect(owner)['setIsEnabled(bool)'](true);
          await instance
            .connect(depositor)
            ['deposit()']({ value: depositAmount });
          await instance
            .connect(secondDepositor)
            ['deposit()']({ value: depositAmount });

          const withdrawShards = 5;
          const shards = [];
          for (let i = 0; i < withdrawShards; i++) {
            shards.push(
              await shardCollection.tokenOfOwnerByIndex(depositor.address, i),
            );
          }

          await expect(
            instance.connect(depositor)['withdraw(uint256[])'](shards),
          ).to.be.revertedWithCustomError(
            instance,
            'ShardVault__WithdrawalForbidden',
          );
        });
        it('vault is invested', async () => {
          await instance.connect(owner)['setIsEnabled(bool)'](true);
          await instance['setMaxUserShards(uint16)'](BigNumber.from('100'));
          await instance.connect(owner).setMaxSupply(BigNumber.from('200'));
          await instance
            .connect(depositor)
            .deposit({ value: ethers.utils.parseEther('100') });

          await instance
            .connect(owner)
            ['purchasePunk((bytes,uint256,address)[],uint256)'](
              punkPurchaseCallsPUSD,
              punkId,
            );

          const withdrawShards = 5;
          const shards = [];
          for (let i = 0; i < withdrawShards; i++) {
            shards.push(
              await shardCollection.tokenOfOwnerByIndex(depositor.address, i),
            );
          }

          await expect(
            instance.connect(depositor)['withdraw(uint256[])'](shards),
          ).to.be.revertedWithCustomError(
            instance,
            'ShardVault__WithdrawalForbidden',
          );
        });
      });
    });
  });
}
