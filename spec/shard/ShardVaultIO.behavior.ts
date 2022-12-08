import hre, { ethers } from 'hardhat';
import {
  ICryptoPunkMarket,
  ICurveMetaPool,
  ILPFarming,
  IMarketPlaceHelper,
  INFTVault,
  IShardCollection,
  IShardVault,
  IShardVaultInternal__factory,
  ShardCollection,
  ShardCollection__factory,
} from '../../typechain-types';

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { BigNumber } from 'ethers';
import { formatTokenId } from './ShardVaultView.behavior';
import { IERC20 } from '../../typechain-types/@solidstate/contracts/interfaces/IERC20';

export interface ShardVaultIOBehaviorArgs {
  getProtocolOwner: () => Promise<SignerWithAddress>;
}

export function describeBehaviorOfShardVaultIO(
  deploy: () => Promise<IShardVault>,
  secondDeploy: () => Promise<IShardVault>,
  pethDeploy: () => Promise<IShardVault>,
  args: ShardVaultIOBehaviorArgs,
  skips?: string[],
) {
  let owner: SignerWithAddress;
  let depositor: SignerWithAddress;
  let secondDepositor: SignerWithAddress;
  let thirdDepositor: SignerWithAddress;
  let instance: IShardVault;
  let secondInstance: IShardVault;
  let pethInstance: IShardVault;
  let shardCollection: ShardCollection;
  let cryptoPunkMarket: ICryptoPunkMarket;
  let pethJpegdVault: INFTVault;
  let pETH: IERC20;
  let jpeg: IERC20;
  let lpFarm: ILPFarming;
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
  const PETH_JPEGD_VAULT = '0x4e5F305bFCa77b17f804635A9bA669e187d51719';
  const PETH_CITADEL = '0x56D1b6Ac326e152C9fAad749F1F4f9737a049d46';
  const LP_FARM = '0xb271d2C9e693dde033d97f8A3C9911781329E4CA';
  const PETH = '0x836A808d4828586A69364065A1e064609F5078c7';
  const JPEG = '0xE80C0cd204D654CEbe8dd64A4857cAb6Be8345a3';
  const curvePETHPoolAddress = '0x9848482da3Ee3076165ce6497eDA906E66bB85C5';
  const targetLTVBP = BigNumber.from('2800');
  const BASIS_POINTS = BigNumber.from('10000');
  const punkPurchaseCallsPUSD: IMarketPlaceHelper.EncodedCallStruct[] = [];
  const punkPurchaseCallsPETH: IMarketPlaceHelper.EncodedCallStruct[] = [];

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

    pethJpegdVault = await ethers.getContractAt('INFTVault', PETH_JPEGD_VAULT);
    lpFarm = await ethers.getContractAt('ILPFarming', LP_FARM);

    jpeg = <IERC20>(
      await ethers.getContractAt(
        '@solidstate/contracts/interfaces/IERC20.sol:IERC20',
        JPEG,
      )
    );
  });

  beforeEach(async () => {
    instance = await deploy();
    secondInstance = await secondDeploy();
    pethInstance = await pethDeploy();
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

    let transferDataPETHVault = cryptoPunkMarket.interface.encodeFunctionData(
      'transferPunk',
      [pethInstance.address, punkId],
    );

    const price = (
      await cryptoPunkMarket['punksOfferedForSale(uint256)'](punkId)
    ).minValue;

    punkPurchaseCallsPETH[0] = {
      data: punkPurchaseData,
      value: price,
      target: CRYPTO_PUNKS_MARKET,
    };

    punkPurchaseCallsPETH[1] = {
      data: transferDataPETHVault,
      value: 0,
      target: CRYPTO_PUNKS_MARKET,
    };

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

    await pethInstance.connect(owner)['setIsEnabled(bool)'](true);
    await pethInstance
      .connect(owner)
      ['setMaxUserShards(uint16)'](BigNumber.from('110'));
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

        const shards = depositAmount.div(
          await instance.callStatic['shardValue()'](),
        );
        expect(await shardCollection.balanceOf(depositor.address)).to.eq(
          shards,
        );
        expect(
          await instance.callStatic['userShards(address)'](depositor.address),
        ).to.eq(shards);
      });
      it('increases total shard supply', async () => {
        await instance.connect(owner)['setIsEnabled(bool)'](true);
        await instance
          .connect(depositor)
          ['deposit()']({ value: depositAmount });

        const shards = depositAmount.div(
          await instance.callStatic['shardValue()'](),
        );
        expect(await instance.totalSupply()).to.eq(shards);
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

        const shards = depositAmount.div(
          await instance.callStatic['shardValue()'](),
        );
        expect(await instance['userShards(address)'](depositor.address)).to.eq(
          shards,
        );
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

    describe('#claimYield(uint256[])', () => {
      it('increases claimedJPEGPerShard for each shard used to claim', async () => {
        await pethInstance.connect(owner).setMaxSupply(BigNumber.from('200'));
        await pethInstance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });
        await pethInstance
          .connect(secondDepositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        await pethInstance
          .connect(owner)
          ['purchasePunk((bytes,uint256,address)[],uint256)'](
            punkPurchaseCallsPETH,
            punkId,
          );

        const requestedBorrow = (
          await pethJpegdVault.callStatic['getNFTValueETH(uint256)'](punkId)
        )
          .mul(targetLTVBP)
          .div(BASIS_POINTS);

        const settings = await pethJpegdVault.callStatic['settings()']();
        const actualBorrow = requestedBorrow.sub(
          requestedBorrow
            .mul(settings.organizationFeeRate.numerator)
            .div(settings.organizationFeeRate.denominator),
        );

        await pethInstance
          .connect(owner)
          ['collateralizePunkPETH(uint256,uint256,bool)'](
            punkId,
            requestedBorrow,
            false,
          );

        const curvePETHPool = <ICurveMetaPool>(
          await ethers.getContractAt('ICurveMetaPool', curvePETHPoolAddress)
        );

        const minCurveLP = await curvePETHPool.callStatic[
          'calc_token_amount(uint256[2],bool)'
        ]([0, actualBorrow], true);

        const curveBasis = BigNumber.from('10000000000');
        const curveFee = BigNumber.from('4000000');
        const curveRemainder = curveBasis.sub(curveFee);

        await pethInstance
          .connect(owner)
          ['stakePETH(uint256,uint256,uint256)'](
            actualBorrow,
            minCurveLP.mul(curveRemainder).div(curveBasis),
            ethers.constants.Two,
          );

        const { timestamp: stakeTimeStamp } = await ethers.provider.getBlock(
          'latest',
        );

        const duration = 1000;
        await hre.network.provider.send('evm_setNextBlockTimestamp', [
          stakeTimeStamp + duration,
        ]);

        const unstakeAmount = ethers.utils.parseEther('5');
        const minETH = ethers.utils.parseEther('4.5');
        const poolInfoIndex = ethers.constants.Two;

        await pethInstance
          .connect(owner)
          ['provideYieldPETH(uint256,uint256,uint256)'](
            unstakeAmount,
            minETH,
            poolInfoIndex,
          );

        const cumulativeJPEGPerShard = await pethInstance[
          'cumulativeJPEGPerShard()'
        ]();
        const tokenIds = [];
        const oldclaimedJPEGPerShard = [];
        for (let i = 1; i < 51; i++) {
          let tokenId = formatTokenId(
            BigNumber.from(i.toString()),
            pethInstance.address,
          );
          tokenIds.push(tokenId);
          oldclaimedJPEGPerShard.push(
            await pethInstance['claimedJPEGPerShard(uint256)'](tokenId),
          );
        }

        await pethInstance
          .connect(depositor)
          ['claimYield(uint256[])'](tokenIds);

        const newclaimedJPEGPerShard = [];
        for (let i = 0; i < tokenIds.length; i++) {
          newclaimedJPEGPerShard.push(
            cumulativeJPEGPerShard.sub(oldclaimedJPEGPerShard[i]),
          );
        }

        for (let i = 0; i < tokenIds.length; i++) {
          expect(
            await pethInstance['claimedJPEGPerShard(uint256)'](tokenIds[i]),
          ).to.eq(oldclaimedJPEGPerShard[i].add(newclaimedJPEGPerShard[i]));
        }
      });
      it('increases claimedETHPerShard for each shard used to claim', async () => {
        await pethInstance.connect(owner).setMaxSupply(BigNumber.from('200'));
        await pethInstance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });
        await pethInstance
          .connect(secondDepositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        await pethInstance
          .connect(owner)
          ['purchasePunk((bytes,uint256,address)[],uint256)'](
            punkPurchaseCallsPETH,
            punkId,
          );

        const requestedBorrow = (
          await pethJpegdVault.callStatic['getNFTValueETH(uint256)'](punkId)
        )
          .mul(targetLTVBP)
          .div(BASIS_POINTS);

        const settings = await pethJpegdVault.callStatic['settings()']();
        const actualBorrow = requestedBorrow.sub(
          requestedBorrow
            .mul(settings.organizationFeeRate.numerator)
            .div(settings.organizationFeeRate.denominator),
        );

        await pethInstance
          .connect(owner)
          ['collateralizePunkPETH(uint256,uint256,bool)'](
            punkId,
            requestedBorrow,
            false,
          );

        const curvePETHPool = <ICurveMetaPool>(
          await ethers.getContractAt('ICurveMetaPool', curvePETHPoolAddress)
        );

        const minCurveLP = await curvePETHPool.callStatic[
          'calc_token_amount(uint256[2],bool)'
        ]([0, actualBorrow], true);

        const curveBasis = BigNumber.from('10000000000');
        const curveFee = BigNumber.from('4000000');
        const curveRemainder = curveBasis.sub(curveFee);

        await pethInstance
          .connect(owner)
          ['stakePETH(uint256,uint256,uint256)'](
            actualBorrow,
            minCurveLP.mul(curveRemainder).div(curveBasis),
            ethers.constants.Two,
          );

        const { timestamp: stakeTimeStamp } = await ethers.provider.getBlock(
          'latest',
        );

        const duration = 1000;
        await hre.network.provider.send('evm_setNextBlockTimestamp', [
          stakeTimeStamp + duration,
        ]);

        const unstakeAmount = ethers.utils.parseEther('5');
        const minETH = ethers.utils.parseEther('4.5');
        const poolInfoIndex = ethers.constants.Two;

        await pethInstance
          .connect(owner)
          ['provideYieldPETH(uint256,uint256,uint256)'](
            unstakeAmount,
            minETH,
            poolInfoIndex,
          );

        const cumulativeETHPerShard = await pethInstance[
          'cumulativeETHPerShard()'
        ]();
        const tokenIds = [];
        const oldclaimedETHPerShard = [];
        for (let i = 1; i < 51; i++) {
          let tokenId = formatTokenId(
            BigNumber.from(i.toString()),
            pethInstance.address,
          );
          tokenIds.push(tokenId);
          oldclaimedETHPerShard.push(
            await pethInstance['claimedETHPerShard(uint256)'](tokenId),
          );
        }

        await pethInstance
          .connect(depositor)
          ['claimYield(uint256[])'](tokenIds);

        const newclaimedETHPerShard = [];
        for (let i = 0; i < tokenIds.length; i++) {
          newclaimedETHPerShard.push(
            cumulativeETHPerShard.sub(oldclaimedETHPerShard[i]),
          );
        }

        for (let i = 0; i < tokenIds.length; i++) {
          expect(
            await pethInstance['claimedETHPerShard(uint256)'](tokenIds[i]),
          ).to.eq(oldclaimedETHPerShard[i].add(newclaimedETHPerShard[i]));
        }
      });
      it('increases accruedFees', async () => {
        await pethInstance.connect(owner).setMaxSupply(BigNumber.from('200'));
        await pethInstance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });
        await pethInstance
          .connect(secondDepositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        await pethInstance
          .connect(owner)
          ['purchasePunk((bytes,uint256,address)[],uint256)'](
            punkPurchaseCallsPETH,
            punkId,
          );

        const requestedBorrow = (
          await pethJpegdVault.callStatic['getNFTValueETH(uint256)'](punkId)
        )
          .mul(targetLTVBP)
          .div(BASIS_POINTS);

        const settings = await pethJpegdVault.callStatic['settings()']();
        const actualBorrow = requestedBorrow.sub(
          requestedBorrow
            .mul(settings.organizationFeeRate.numerator)
            .div(settings.organizationFeeRate.denominator),
        );

        await pethInstance
          .connect(owner)
          ['collateralizePunkPETH(uint256,uint256,bool)'](
            punkId,
            requestedBorrow,
            false,
          );

        const curvePETHPool = <ICurveMetaPool>(
          await ethers.getContractAt('ICurveMetaPool', curvePETHPoolAddress)
        );

        const minCurveLP = await curvePETHPool.callStatic[
          'calc_token_amount(uint256[2],bool)'
        ]([0, actualBorrow], true);

        const curveBasis = BigNumber.from('10000000000');
        const curveFee = BigNumber.from('4000000');
        const curveRemainder = curveBasis.sub(curveFee);

        await pethInstance
          .connect(owner)
          ['stakePETH(uint256,uint256,uint256)'](
            actualBorrow,
            minCurveLP.mul(curveRemainder).div(curveBasis),
            ethers.constants.Two,
          );

        const { timestamp: stakeTimeStamp } = await ethers.provider.getBlock(
          'latest',
        );

        const duration = 1000;
        await hre.network.provider.send('evm_setNextBlockTimestamp', [
          stakeTimeStamp + duration,
        ]);

        const unstakeAmount = ethers.utils.parseEther('5');
        const minETH = ethers.utils.parseEther('4.5');
        const poolInfoIndex = ethers.constants.Two;

        await pethInstance
          .connect(owner)
          ['provideYieldPETH(uint256,uint256,uint256)'](
            unstakeAmount,
            minETH,
            poolInfoIndex,
          );

        const cumulativeETHPerShard = await pethInstance[
          'cumulativeETHPerShard()'
        ]();
        const tokenIds = [];
        let claimedETH = BigNumber.from('0');
        for (let i = 1; i < 51; i++) {
          let tokenId = formatTokenId(
            BigNumber.from(i.toString()),
            pethInstance.address,
          );
          tokenIds.push(tokenId);
          claimedETH = claimedETH.add(
            cumulativeETHPerShard.sub(
              await pethInstance.callStatic['claimedETHPerShard(uint256)'](
                tokenId,
              ),
            ),
          );
        }

        const ETHFee = claimedETH
          .mul(await pethInstance['yieldFeeBP()']())
          .div(BASIS_POINTS);

        const oldAccruedFees = await pethInstance.callStatic['accruedFees()']();

        await pethInstance
          .connect(depositor)
          ['claimYield(uint256[])'](tokenIds);

        const newAccruedFees = await pethInstance.callStatic['accruedFees()']();

        expect(ETHFee).to.eq(newAccruedFees.sub(oldAccruedFees));
      });
      it('increases accruedJPEG', async () => {
        await pethInstance.connect(owner).setMaxSupply(BigNumber.from('200'));
        await pethInstance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });
        await pethInstance
          .connect(secondDepositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        await pethInstance
          .connect(owner)
          ['purchasePunk((bytes,uint256,address)[],uint256)'](
            punkPurchaseCallsPETH,
            punkId,
          );

        const requestedBorrow = (
          await pethJpegdVault.callStatic['getNFTValueETH(uint256)'](punkId)
        )
          .mul(targetLTVBP)
          .div(BASIS_POINTS);

        const settings = await pethJpegdVault.callStatic['settings()']();
        const actualBorrow = requestedBorrow.sub(
          requestedBorrow
            .mul(settings.organizationFeeRate.numerator)
            .div(settings.organizationFeeRate.denominator),
        );

        await pethInstance
          .connect(owner)
          ['collateralizePunkPETH(uint256,uint256,bool)'](
            punkId,
            requestedBorrow,
            false,
          );

        const curvePETHPool = <ICurveMetaPool>(
          await ethers.getContractAt('ICurveMetaPool', curvePETHPoolAddress)
        );

        const minCurveLP = await curvePETHPool.callStatic[
          'calc_token_amount(uint256[2],bool)'
        ]([0, actualBorrow], true);

        const curveBasis = BigNumber.from('10000000000');
        const curveFee = BigNumber.from('4000000');
        const curveRemainder = curveBasis.sub(curveFee);

        await pethInstance
          .connect(owner)
          ['stakePETH(uint256,uint256,uint256)'](
            actualBorrow,
            minCurveLP.mul(curveRemainder).div(curveBasis),
            ethers.constants.Two,
          );

        const { timestamp: stakeTimeStamp } = await ethers.provider.getBlock(
          'latest',
        );

        const duration = 1000;
        await hre.network.provider.send('evm_setNextBlockTimestamp', [
          stakeTimeStamp + duration,
        ]);

        const unstakeAmount = ethers.utils.parseEther('5');
        const minETH = ethers.utils.parseEther('4.5');
        const poolInfoIndex = ethers.constants.Two;

        await pethInstance
          .connect(owner)
          ['provideYieldPETH(uint256,uint256,uint256)'](
            unstakeAmount,
            minETH,
            poolInfoIndex,
          );

        const cumulativeJPEGPerShard = await pethInstance[
          'cumulativeJPEGPerShard()'
        ]();
        const tokenIds = [];
        let claimedJPEG = BigNumber.from(0);

        for (let i = 1; i < 51; i++) {
          let tokenId = formatTokenId(
            BigNumber.from(i.toString()),
            pethInstance.address,
          );
          tokenIds.push(tokenId);
          claimedJPEG = claimedJPEG.add(
            cumulativeJPEGPerShard.sub(
              await pethInstance.callStatic['claimedJPEGPerShard(uint256)'](
                tokenId,
              ),
            ),
          );
        }

        const jpegFee = claimedJPEG
          .mul(await pethInstance['yieldFeeBP()']())
          .div(BASIS_POINTS);

        const oldAccruedJPEG = await pethInstance['accruedJPEG()']();

        await pethInstance
          .connect(depositor)
          ['claimYield(uint256[])'](tokenIds);

        const newAccruedJPEG = await pethInstance['accruedJPEG()']();

        expect(jpegFee).to.eq(newAccruedJPEG.sub(oldAccruedJPEG));
      });
      it('transfers JPEG to claimer', async () => {
        await pethInstance.connect(owner).setMaxSupply(BigNumber.from('200'));
        await pethInstance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });
        await pethInstance
          .connect(secondDepositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        await pethInstance
          .connect(owner)
          ['purchasePunk((bytes,uint256,address)[],uint256)'](
            punkPurchaseCallsPETH,
            punkId,
          );

        const requestedBorrow = (
          await pethJpegdVault.callStatic['getNFTValueETH(uint256)'](punkId)
        )
          .mul(targetLTVBP)
          .div(BASIS_POINTS);

        const settings = await pethJpegdVault.callStatic['settings()']();
        const actualBorrow = requestedBorrow.sub(
          requestedBorrow
            .mul(settings.organizationFeeRate.numerator)
            .div(settings.organizationFeeRate.denominator),
        );

        await pethInstance
          .connect(owner)
          ['collateralizePunkPETH(uint256,uint256,bool)'](
            punkId,
            requestedBorrow,
            false,
          );

        const curvePETHPool = <ICurveMetaPool>(
          await ethers.getContractAt('ICurveMetaPool', curvePETHPoolAddress)
        );

        const minCurveLP = await curvePETHPool.callStatic[
          'calc_token_amount(uint256[2],bool)'
        ]([0, actualBorrow], true);

        const curveBasis = BigNumber.from('10000000000');
        const curveFee = BigNumber.from('4000000');
        const curveRemainder = curveBasis.sub(curveFee);

        await pethInstance
          .connect(owner)
          ['stakePETH(uint256,uint256,uint256)'](
            actualBorrow,
            minCurveLP.mul(curveRemainder).div(curveBasis),
            ethers.constants.Two,
          );

        const { timestamp: stakeTimeStamp } = await ethers.provider.getBlock(
          'latest',
        );

        const duration = 1000;
        await hre.network.provider.send('evm_setNextBlockTimestamp', [
          stakeTimeStamp + duration,
        ]);

        const unstakeAmount = ethers.utils.parseEther('5');
        const minETH = ethers.utils.parseEther('4.5');
        const poolInfoIndex = ethers.constants.Two;

        await pethInstance
          .connect(owner)
          ['provideYieldPETH(uint256,uint256,uint256)'](
            unstakeAmount,
            minETH,
            poolInfoIndex,
          );
        const cumulativeJPEGPerShard = await pethInstance[
          'cumulativeJPEGPerShard()'
        ]();

        const tokenIds = [];
        let claimedJPEG = BigNumber.from('0');
        for (let i = 1; i < 51; i++) {
          let tokenId = formatTokenId(
            BigNumber.from(i.toString()),
            pethInstance.address,
          );
          tokenIds.push(tokenId);
          claimedJPEG = claimedJPEG.add(
            cumulativeJPEGPerShard.sub(
              await pethInstance.callStatic['claimedJPEGPerShard(uint256)'](
                tokenId,
              ),
            ),
          );
        }

        const jpegFee = claimedJPEG
          .mul(await pethInstance['yieldFeeBP()']())
          .div(BASIS_POINTS);

        const claimedJPEGMinusFee = claimedJPEG.sub(jpegFee);

        await expect(() =>
          pethInstance.connect(depositor)['claimYield(uint256[])'](tokenIds),
        ).to.changeTokenBalances(
          jpeg,
          [depositor, pethInstance],
          [
            claimedJPEGMinusFee,
            claimedJPEGMinusFee.mul(ethers.constants.NegativeOne),
          ],
        );
      });
      it('transfers ETH to claimer', async () => {
        await pethInstance.connect(owner).setMaxSupply(BigNumber.from('200'));
        await pethInstance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });
        await pethInstance
          .connect(secondDepositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        await pethInstance
          .connect(owner)
          ['purchasePunk((bytes,uint256,address)[],uint256)'](
            punkPurchaseCallsPETH,
            punkId,
          );

        const requestedBorrow = (
          await pethJpegdVault.callStatic['getNFTValueETH(uint256)'](punkId)
        )
          .mul(targetLTVBP)
          .div(BASIS_POINTS);

        const settings = await pethJpegdVault.callStatic['settings()']();
        const actualBorrow = requestedBorrow.sub(
          requestedBorrow
            .mul(settings.organizationFeeRate.numerator)
            .div(settings.organizationFeeRate.denominator),
        );

        await pethInstance
          .connect(owner)
          ['collateralizePunkPETH(uint256,uint256,bool)'](
            punkId,
            requestedBorrow,
            false,
          );

        const curvePETHPool = <ICurveMetaPool>(
          await ethers.getContractAt('ICurveMetaPool', curvePETHPoolAddress)
        );

        const minCurveLP = await curvePETHPool.callStatic[
          'calc_token_amount(uint256[2],bool)'
        ]([0, actualBorrow], true);

        const curveBasis = BigNumber.from('10000000000');
        const curveFee = BigNumber.from('4000000');
        const curveRemainder = curveBasis.sub(curveFee);

        await pethInstance
          .connect(owner)
          ['stakePETH(uint256,uint256,uint256)'](
            actualBorrow,
            minCurveLP.mul(curveRemainder).div(curveBasis),
            ethers.constants.Two,
          );

        const { timestamp: stakeTimeStamp } = await ethers.provider.getBlock(
          'latest',
        );

        const duration = 1000;
        await hre.network.provider.send('evm_setNextBlockTimestamp', [
          stakeTimeStamp + duration,
        ]);

        const unstakeAmount = ethers.utils.parseEther('5');
        const minETH = ethers.utils.parseEther('4.5');
        const poolInfoIndex = ethers.constants.Two;

        await pethInstance
          .connect(owner)
          ['provideYieldPETH(uint256,uint256,uint256)'](
            unstakeAmount,
            minETH,
            poolInfoIndex,
          );

        const cumulativeETHPerShard = await pethInstance[
          'cumulativeETHPerShard()'
        ]();
        const tokenIds = [];
        let claimedETH = BigNumber.from('0');
        for (let i = 1; i < 51; i++) {
          let tokenId = formatTokenId(
            BigNumber.from(i.toString()),
            pethInstance.address,
          );
          tokenIds.push(tokenId);
          claimedETH = claimedETH.add(
            cumulativeETHPerShard.sub(
              await pethInstance.callStatic['claimedETHPerShard(uint256)'](
                tokenId,
              ),
            ),
          );
        }

        const ETHFee = claimedETH
          .mul(await pethInstance['yieldFeeBP()']())
          .div(BASIS_POINTS);

        const claimedETHMinusFee = claimedETH.sub(ETHFee);

        await expect(() =>
          pethInstance.connect(depositor)['claimYield(uint256[])'](tokenIds),
        ).to.changeEtherBalances(
          [depositor, pethInstance],
          [
            claimedETHMinusFee,
            claimedETHMinusFee.mul(ethers.constants.NegativeOne),
          ],
        );
      });

      describe('reverts if', async () => {
        it('isYieldClaiming is false', async () => {
          await pethInstance.connect(owner).setMaxSupply(BigNumber.from('200'));
          await pethInstance
            .connect(depositor)
            .deposit({ value: ethers.utils.parseEther('100') });
          await pethInstance
            .connect(secondDepositor)
            .deposit({ value: ethers.utils.parseEther('100') });

          await pethInstance
            .connect(owner)
            ['purchasePunk((bytes,uint256,address)[],uint256)'](
              punkPurchaseCallsPETH,
              punkId,
            );

          const requestedBorrow = (
            await pethJpegdVault.callStatic['getNFTValueETH(uint256)'](punkId)
          )
            .mul(targetLTVBP)
            .div(BASIS_POINTS);

          const settings = await pethJpegdVault.callStatic['settings()']();
          const actualBorrow = requestedBorrow.sub(
            requestedBorrow
              .mul(settings.organizationFeeRate.numerator)
              .div(settings.organizationFeeRate.denominator),
          );

          await pethInstance
            .connect(owner)
            ['collateralizePunkPETH(uint256,uint256,bool)'](
              punkId,
              requestedBorrow,
              false,
            );

          const curvePETHPool = <ICurveMetaPool>(
            await ethers.getContractAt('ICurveMetaPool', curvePETHPoolAddress)
          );

          const minCurveLP = await curvePETHPool.callStatic[
            'calc_token_amount(uint256[2],bool)'
          ]([0, actualBorrow], true);

          const curveBasis = BigNumber.from('10000000000');
          const curveFee = BigNumber.from('4000000');
          const curveRemainder = curveBasis.sub(curveFee);

          await pethInstance
            .connect(owner)
            ['stakePETH(uint256,uint256,uint256)'](
              actualBorrow,
              minCurveLP.mul(curveRemainder).div(curveBasis),
              ethers.constants.Two,
            );

          const { timestamp: stakeTimeStamp } = await ethers.provider.getBlock(
            'latest',
          );

          const duration = 1000;
          await hre.network.provider.send('evm_setNextBlockTimestamp', [
            stakeTimeStamp + duration,
          ]);

          const tokenIds = [];
          for (let i = 1; i < 51; i++) {
            let tokenId = formatTokenId(
              BigNumber.from(i.toString()),
              pethInstance.address,
            );
            tokenIds.push(tokenId);
          }

          await expect(
            pethInstance.connect(depositor)['claimYield(uint256[])'](tokenIds),
          ).to.be.revertedWithCustomError(
            pethInstance,
            'ShardVault__YieldClaimingForbidden',
          );
        });
        it('claimer has insufficient shards', async () => {
          await pethInstance.connect(owner).setMaxSupply(BigNumber.from('200'));
          await pethInstance
            .connect(depositor)
            .deposit({ value: ethers.utils.parseEther('100') });
          await pethInstance
            .connect(secondDepositor)
            .deposit({ value: ethers.utils.parseEther('100') });

          await pethInstance
            .connect(owner)
            ['purchasePunk((bytes,uint256,address)[],uint256)'](
              punkPurchaseCallsPETH,
              punkId,
            );

          const requestedBorrow = (
            await pethJpegdVault.callStatic['getNFTValueETH(uint256)'](punkId)
          )
            .mul(targetLTVBP)
            .div(BASIS_POINTS);

          const settings = await pethJpegdVault.callStatic['settings()']();
          const actualBorrow = requestedBorrow.sub(
            requestedBorrow
              .mul(settings.organizationFeeRate.numerator)
              .div(settings.organizationFeeRate.denominator),
          );

          await pethInstance
            .connect(owner)
            ['collateralizePunkPETH(uint256,uint256,bool)'](
              punkId,
              requestedBorrow,
              false,
            );

          const curvePETHPool = <ICurveMetaPool>(
            await ethers.getContractAt('ICurveMetaPool', curvePETHPoolAddress)
          );

          const minCurveLP = await curvePETHPool.callStatic[
            'calc_token_amount(uint256[2],bool)'
          ]([0, actualBorrow], true);

          const curveBasis = BigNumber.from('10000000000');
          const curveFee = BigNumber.from('4000000');
          const curveRemainder = curveBasis.sub(curveFee);

          await pethInstance
            .connect(owner)
            ['stakePETH(uint256,uint256,uint256)'](
              actualBorrow,
              minCurveLP.mul(curveRemainder).div(curveBasis),
              ethers.constants.Two,
            );

          const { timestamp: stakeTimeStamp } = await ethers.provider.getBlock(
            'latest',
          );

          const duration = 1000;
          await hre.network.provider.send('evm_setNextBlockTimestamp', [
            stakeTimeStamp + duration,
          ]);

          const unstakeAmount = ethers.utils.parseEther('5');
          const minETH = ethers.utils.parseEther('4.5');
          const poolInfoIndex = ethers.constants.Two;

          await pethInstance
            .connect(owner)
            ['provideYieldPETH(uint256,uint256,uint256)'](
              unstakeAmount,
              minETH,
              poolInfoIndex,
            );

          const tokenIds = [];
          for (let i = 1; i < 111; i++) {
            let tokenId = formatTokenId(
              BigNumber.from(i.toString()),
              pethInstance.address,
            );
            tokenIds.push(tokenId);
          }

          await expect(
            pethInstance.connect(depositor)['claimYield(uint256[])'](tokenIds),
          ).to.be.revertedWithCustomError(
            pethInstance,
            'ShardVault__InsufficientShards',
          );
        });
        it('claimer is not shard owner', async () => {
          await pethInstance.connect(owner).setMaxSupply(BigNumber.from('200'));
          await pethInstance
            .connect(depositor)
            .deposit({ value: ethers.utils.parseEther('100') });
          await pethInstance
            .connect(secondDepositor)
            .deposit({ value: ethers.utils.parseEther('100') });

          await pethInstance
            .connect(owner)
            ['purchasePunk((bytes,uint256,address)[],uint256)'](
              punkPurchaseCallsPETH,
              punkId,
            );

          const requestedBorrow = (
            await pethJpegdVault.callStatic['getNFTValueETH(uint256)'](punkId)
          )
            .mul(targetLTVBP)
            .div(BASIS_POINTS);

          const settings = await pethJpegdVault.callStatic['settings()']();
          const actualBorrow = requestedBorrow.sub(
            requestedBorrow
              .mul(settings.organizationFeeRate.numerator)
              .div(settings.organizationFeeRate.denominator),
          );

          await pethInstance
            .connect(owner)
            ['collateralizePunkPETH(uint256,uint256,bool)'](
              punkId,
              requestedBorrow,
              false,
            );

          const curvePETHPool = <ICurveMetaPool>(
            await ethers.getContractAt('ICurveMetaPool', curvePETHPoolAddress)
          );

          const minCurveLP = await curvePETHPool.callStatic[
            'calc_token_amount(uint256[2],bool)'
          ]([0, actualBorrow], true);

          const curveBasis = BigNumber.from('10000000000');
          const curveFee = BigNumber.from('4000000');
          const curveRemainder = curveBasis.sub(curveFee);

          await pethInstance
            .connect(owner)
            ['stakePETH(uint256,uint256,uint256)'](
              actualBorrow,
              minCurveLP.mul(curveRemainder).div(curveBasis),
              ethers.constants.Two,
            );

          const { timestamp: stakeTimeStamp } = await ethers.provider.getBlock(
            'latest',
          );

          const duration = 1000;
          await hre.network.provider.send('evm_setNextBlockTimestamp', [
            stakeTimeStamp + duration,
          ]);

          const unstakeAmount = ethers.utils.parseEther('5');
          const minETH = ethers.utils.parseEther('4.5');
          const poolInfoIndex = ethers.constants.Two;

          await pethInstance
            .connect(owner)
            ['provideYieldPETH(uint256,uint256,uint256)'](
              unstakeAmount,
              minETH,
              poolInfoIndex,
            );

          const tokenIds = [];
          for (let i = 1; i < 51; i++) {
            let tokenId = formatTokenId(
              BigNumber.from(i.toString()),
              pethInstance.address,
            );
            tokenIds.push(tokenId);
          }

          await expect(
            pethInstance
              .connect(secondDepositor)
              ['claimYield(uint256[])'](tokenIds),
          ).to.be.revertedWithCustomError(
            pethInstance,
            'ShardVault__NotShardOwner',
          );
        });
        it('shards used to claim match different vault', async () => {
          await pethInstance.connect(owner).setMaxSupply(BigNumber.from('200'));
          await pethInstance
            .connect(depositor)
            .deposit({ value: ethers.utils.parseEther('100') });
          await pethInstance
            .connect(secondDepositor)
            .deposit({ value: ethers.utils.parseEther('100') });

          await instance.connect(owner)['setIsEnabled(bool)'](true);
          await instance
            .connect(depositor)
            .deposit({ value: ethers.utils.parseEther('100') });

          await pethInstance
            .connect(owner)
            ['purchasePunk((bytes,uint256,address)[],uint256)'](
              punkPurchaseCallsPETH,
              punkId,
            );

          const requestedBorrow = (
            await pethJpegdVault.callStatic['getNFTValueETH(uint256)'](punkId)
          )
            .mul(targetLTVBP)
            .div(BASIS_POINTS);

          const settings = await pethJpegdVault.callStatic['settings()']();
          const actualBorrow = requestedBorrow.sub(
            requestedBorrow
              .mul(settings.organizationFeeRate.numerator)
              .div(settings.organizationFeeRate.denominator),
          );

          await pethInstance
            .connect(owner)
            ['collateralizePunkPETH(uint256,uint256,bool)'](
              punkId,
              requestedBorrow,
              false,
            );

          const curvePETHPool = <ICurveMetaPool>(
            await ethers.getContractAt('ICurveMetaPool', curvePETHPoolAddress)
          );

          const minCurveLP = await curvePETHPool.callStatic[
            'calc_token_amount(uint256[2],bool)'
          ]([0, actualBorrow], true);

          const curveBasis = BigNumber.from('10000000000');
          const curveFee = BigNumber.from('4000000');
          const curveRemainder = curveBasis.sub(curveFee);

          await pethInstance
            .connect(owner)
            ['stakePETH(uint256,uint256,uint256)'](
              actualBorrow,
              minCurveLP.mul(curveRemainder).div(curveBasis),
              ethers.constants.Two,
            );

          const { timestamp: stakeTimeStamp } = await ethers.provider.getBlock(
            'latest',
          );

          const duration = 1000;
          await hre.network.provider.send('evm_setNextBlockTimestamp', [
            stakeTimeStamp + duration,
          ]);

          const unstakeAmount = ethers.utils.parseEther('5');
          const minETH = ethers.utils.parseEther('4.5');
          const poolInfoIndex = ethers.constants.Two;

          await pethInstance
            .connect(owner)
            ['provideYieldPETH(uint256,uint256,uint256)'](
              unstakeAmount,
              minETH,
              poolInfoIndex,
            );

          const tokenIds = [];
          for (let i = 1; i < 51; i++) {
            let tokenId = formatTokenId(
              BigNumber.from(i.toString()),
              instance.address,
            );
            tokenIds.push(tokenId);
          }

          await expect(
            pethInstance.connect(depositor)['claimYield(uint256[])'](tokenIds),
          ).to.be.revertedWithCustomError(
            pethInstance,
            'ShardVault__VaultTokenIdMismatch',
          );
        });
      });
    });

    describe('#claimExcessETH(uint256[])', () => {
      it('increases claimedETHPerShard for each shard used to claim', async () => {
        await pethInstance.connect(owner).setMaxSupply(BigNumber.from('200'));
        await pethInstance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });
        await pethInstance
          .connect(secondDepositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        await pethInstance
          .connect(owner)
          ['purchasePunk((bytes,uint256,address)[],uint256)'](
            punkPurchaseCallsPETH,
            punkId,
          );

        const cumulativeETHPerShard = await pethInstance[
          'cumulativeETHPerShard()'
        ]();
        const tokenIds = [];
        const oldclaimedETHPerShard = [];
        for (let i = 1; i < 51; i++) {
          let tokenId = formatTokenId(
            BigNumber.from(i.toString()),
            pethInstance.address,
          );
          tokenIds.push(tokenId);
          oldclaimedETHPerShard.push(
            await pethInstance['claimedETHPerShard(uint256)'](tokenId),
          );
        }

        await pethInstance
          .connect(depositor)
          ['claimExcessETH(uint256[])'](tokenIds);

        const newclaimedETHPerShard = [];
        for (let i = 0; i < tokenIds.length; i++) {
          newclaimedETHPerShard.push(
            cumulativeETHPerShard.sub(oldclaimedETHPerShard[i]),
          );
        }

        for (let i = 0; i < tokenIds.length; i++) {
          expect(
            await pethInstance['claimedETHPerShard(uint256)'](tokenIds[i]),
          ).to.eq(oldclaimedETHPerShard[i].add(newclaimedETHPerShard[i]));
        }
      });
      it('transfers ETH to claimer', async () => {
        await pethInstance.connect(owner).setMaxSupply(BigNumber.from('200'));
        await pethInstance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });
        await pethInstance
          .connect(secondDepositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        await pethInstance
          .connect(owner)
          ['purchasePunk((bytes,uint256,address)[],uint256)'](
            punkPurchaseCallsPETH,
            punkId,
          );
        const cumulativeETHPerShard = await pethInstance[
          'cumulativeETHPerShard()'
        ]();
        const tokenIds = [];
        let claimedETH = BigNumber.from('0');
        for (let i = 1; i < 51; i++) {
          let tokenId = formatTokenId(
            BigNumber.from(i.toString()),
            pethInstance.address,
          );
          tokenIds.push(tokenId);
          claimedETH = claimedETH.add(
            cumulativeETHPerShard.sub(
              await pethInstance.callStatic['claimedETHPerShard(uint256)'](
                tokenId,
              ),
            ),
          );
        }

        await expect(() =>
          pethInstance
            .connect(depositor)
            ['claimExcessETH(uint256[])'](tokenIds),
        ).to.changeEtherBalances(
          [depositor, pethInstance],
          [claimedETH, claimedETH.mul(ethers.constants.NegativeOne)],
        );
      });
      it('transfer 0 ETH to claimer if final purchase has not been made', async () => {
        await pethInstance.connect(owner).setMaxSupply(BigNumber.from('200'));
        await pethInstance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });
        await pethInstance
          .connect(secondDepositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        await pethInstance
          .connect(owner)
          ['purchasePunk((bytes,uint256,address)[],uint256)'](
            punkPurchaseCallsPETH,
            punkId,
          );

        const tokenIds = [];
        for (let i = 1; i < 51; i++) {
          let tokenId = formatTokenId(
            BigNumber.from(i.toString()),
            pethInstance.address,
          );
          tokenIds.push(tokenId);
        }

        await expect(() =>
          pethInstance
            .connect(depositor)
            ['claimExcessETH(uint256[])'](tokenIds),
        ).to.changeEtherBalances(
          [depositor, pethInstance],
          [ethers.constants.Zero, ethers.constants.Zero],
        );
      });

      describe('reverts if', () => {
        it('isInvested is false', async () => {
          await pethInstance.connect(owner).setMaxSupply(BigNumber.from('200'));
          await pethInstance
            .connect(depositor)
            .deposit({ value: ethers.utils.parseEther('100') });
          await pethInstance
            .connect(secondDepositor)
            .deposit({ value: ethers.utils.parseEther('100') });

          const tokenIds = [];
          for (let i = 1; i < 51; i++) {
            let tokenId = formatTokenId(
              BigNumber.from(i.toString()),
              pethInstance.address,
            );
            tokenIds.push(tokenId);
          }

          await expect(
            pethInstance
              .connect(depositor)
              ['claimExcessETH(uint256[])'](tokenIds),
          ).to.be.revertedWithCustomError(
            pethInstance,
            'ShardVault__ClaimingExcessETHForbidden',
          );
        });
        it('isYieldClaiming is true', async () => {
          await pethInstance.connect(owner).setMaxSupply(BigNumber.from('200'));
          await pethInstance
            .connect(depositor)
            .deposit({ value: ethers.utils.parseEther('100') });
          await pethInstance
            .connect(secondDepositor)
            .deposit({ value: ethers.utils.parseEther('100') });

          await pethInstance
            .connect(owner)
            ['purchasePunk((bytes,uint256,address)[],uint256)'](
              punkPurchaseCallsPETH,
              punkId,
            );

          const requestedBorrow = (
            await pethJpegdVault.callStatic['getNFTValueETH(uint256)'](punkId)
          )
            .mul(targetLTVBP)
            .div(BASIS_POINTS);

          const settings = await pethJpegdVault.callStatic['settings()']();
          const actualBorrow = requestedBorrow.sub(
            requestedBorrow
              .mul(settings.organizationFeeRate.numerator)
              .div(settings.organizationFeeRate.denominator),
          );

          await pethInstance
            .connect(owner)
            ['collateralizePunkPETH(uint256,uint256,bool)'](
              punkId,
              requestedBorrow,
              false,
            );

          const curvePETHPool = <ICurveMetaPool>(
            await ethers.getContractAt('ICurveMetaPool', curvePETHPoolAddress)
          );

          const minCurveLP = await curvePETHPool.callStatic[
            'calc_token_amount(uint256[2],bool)'
          ]([0, actualBorrow], true);

          const curveBasis = BigNumber.from('10000000000');
          const curveFee = BigNumber.from('4000000');
          const curveRemainder = curveBasis.sub(curveFee);

          await pethInstance
            .connect(owner)
            ['stakePETH(uint256,uint256,uint256)'](
              actualBorrow,
              minCurveLP.mul(curveRemainder).div(curveBasis),
              ethers.constants.Two,
            );

          const { timestamp: stakeTimeStamp } = await ethers.provider.getBlock(
            'latest',
          );

          const duration = 1000;
          await hre.network.provider.send('evm_setNextBlockTimestamp', [
            stakeTimeStamp + duration,
          ]);

          const unstakeAmount = ethers.utils.parseEther('5');
          const minETH = ethers.utils.parseEther('4.5');
          const poolInfoIndex = ethers.constants.Two;

          await pethInstance
            .connect(owner)
            ['provideYieldPETH(uint256,uint256,uint256)'](
              unstakeAmount,
              minETH,
              poolInfoIndex,
            );
          const tokenIds = [];
          for (let i = 1; i < 51; i++) {
            let tokenId = formatTokenId(
              BigNumber.from(i.toString()),
              pethInstance.address,
            );
            tokenIds.push(tokenId);
          }

          await expect(
            pethInstance
              .connect(depositor)
              ['claimExcessETH(uint256[])'](tokenIds),
          ).to.be.revertedWithCustomError(
            pethInstance,
            'ShardVault__ClaimingExcessETHForbidden',
          );
        });
        it('claimer has insufficient shards', async () => {
          await pethInstance.connect(owner).setMaxSupply(BigNumber.from('200'));
          await pethInstance
            .connect(depositor)
            .deposit({ value: ethers.utils.parseEther('100') });
          await pethInstance
            .connect(secondDepositor)
            .deposit({ value: ethers.utils.parseEther('100') });

          await pethInstance
            .connect(owner)
            ['purchasePunk((bytes,uint256,address)[],uint256)'](
              punkPurchaseCallsPETH,
              punkId,
            );

          const tokenIds = [];
          for (let i = 1; i < 111; i++) {
            let tokenId = formatTokenId(
              BigNumber.from(i.toString()),
              pethInstance.address,
            );
            tokenIds.push(tokenId);
          }

          await expect(
            pethInstance
              .connect(depositor)
              ['claimExcessETH(uint256[])'](tokenIds),
          ).to.be.revertedWithCustomError(
            pethInstance,
            'ShardVault__InsufficientShards',
          );
        });
        it('claimer is not shard owner', async () => {
          await pethInstance.connect(owner).setMaxSupply(BigNumber.from('200'));
          await pethInstance
            .connect(depositor)
            .deposit({ value: ethers.utils.parseEther('100') });
          await pethInstance
            .connect(secondDepositor)
            .deposit({ value: ethers.utils.parseEther('100') });

          await pethInstance
            .connect(owner)
            ['purchasePunk((bytes,uint256,address)[],uint256)'](
              punkPurchaseCallsPETH,
              punkId,
            );

          const tokenIds = [];
          for (let i = 1; i < 51; i++) {
            let tokenId = formatTokenId(
              BigNumber.from(i.toString()),
              pethInstance.address,
            );
            tokenIds.push(tokenId);
          }

          await expect(
            pethInstance
              .connect(secondDepositor)
              ['claimExcessETH(uint256[])'](tokenIds),
          ).to.be.revertedWithCustomError(
            pethInstance,
            'ShardVault__NotShardOwner',
          );
        });
        it('shards used to claim match different vault', async () => {
          await pethInstance.connect(owner).setMaxSupply(BigNumber.from('200'));
          await pethInstance
            .connect(depositor)
            .deposit({ value: ethers.utils.parseEther('100') });
          await instance.connect(owner)['setIsEnabled(bool)'](true);
          await instance
            .connect(depositor)
            .deposit({ value: ethers.utils.parseEther('100') });

          await pethInstance
            .connect(owner)
            ['purchasePunk((bytes,uint256,address)[],uint256)'](
              punkPurchaseCallsPETH,
              punkId,
            );

          const tokenIds = [];
          for (let i = 1; i < 51; i++) {
            let tokenId = formatTokenId(
              BigNumber.from(i.toString()),
              instance.address,
            );
            tokenIds.push(tokenId);
          }

          await expect(
            pethInstance
              .connect(depositor)
              ['claimExcessETH(uint256[])'](tokenIds),
          ).to.be.revertedWithCustomError(
            pethInstance,
            'ShardVault__VaultTokenIdMismatch',
          );
        });
      });
    });
  });
}
