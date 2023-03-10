import hre, { ethers } from 'hardhat';
import {
  ICryptoPunkMarket,
  ICurveMetaPool,
  ILPFarming,
  IMarketPlaceHelper,
  INFTValueProvider,
  INFTValueProvider__factory,
  INFTVault,
  IShardVault,
  IShardVaultInternal__factory,
} from '../../typechain-types';

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { BigNumber } from 'ethers';
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
  let cryptoPunkMarket: ICryptoPunkMarket;
  let pethJpegdVault: INFTVault;
  let pETH: IERC20;
  let jpeg: IERC20;
  let lpFarm: ILPFarming;
  let purchaseDataPUSD: string[];
  let targets: string[];

  const punkId = BigNumber.from('1621');
  const CRYPTO_PUNKS_MARKET = '0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB';
  const dawnOfInsrtID = BigNumber.from('567');
  const secondDawnOfInsrtID = BigNumber.from('654');
  const dawnOfInsrtOwnerAddress = '0x62E4db9D13E7B8DB18266CF0f89b923d6C65e0ab';
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
  const TIER0_FEE_COEFFICIENT = BigNumber.from('9000');
  const TIER1_FEE_COEFFICIENT = BigNumber.from('7500');
  const TIER2_FEE_COEFFICIENT = BigNumber.from('6000');
  const TIER3_FEE_COEFFICIENT = BigNumber.from('4000');
  const TIER4_FEE_COEFFICIENT = BigNumber.from('2000');
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

    await depositor.sendTransaction({
      to: dawnOfInsrtOwnerAddress,
      value: ethers.utils.parseEther('1'),
    });

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
      ['setMaxMintBalance(uint64)'](BigNumber.from('110'));
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
      it('mints shards from ShardVault to depositor', async () => {
        await instance.connect(owner)['setIsEnabled(bool)'](true);
        await instance
          .connect(depositor)
          ['deposit()']({ value: depositAmount });

        const shards = depositAmount.div(
          await instance.callStatic['shardValue()'](),
        );
        expect(await instance.balanceOf(depositor.address)).to.eq(shards);
        expect(
          await instance.callStatic['balanceOf(address)'](depositor.address),
        ).to.eq(shards);
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
              (await instance['maxMintBalance()']()).toString(),
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
          ['initiateWhitelistAndDeposits(uint48,uint64)'](
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
              (await instance['reservedSupply()']()).toString(),
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
            'ShardVault__MaxMintBalance',
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
            ['setMaxMintBalance(uint64)'](BigNumber.from('200'));
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
            ['setMaxMintBalance(uint64)'](BigNumber.from('200'));
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
          const whitelistShards = BigNumber.from('15');
          await instance
            .connect(owner)
            ['initiateWhitelistAndDeposits(uint48,uint64)'](
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
            ['initiateWhitelistAndDeposits(uint48,uint64)'](
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
          shards.push(await instance.tokenOfOwnerByIndex(depositor.address, i));
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
          shards.push(await instance.tokenOfOwnerByIndex(depositor.address, i));
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

      it('CERTIK: able to mint after withdrawing', async () => {
        await instance.connect(owner)['setIsEnabled(bool)'](true);
        await instance
          .connect(depositor)
          ['deposit()']({ value: depositAmount });

        const withdrawShards = 5;
        const shards = [];
        for (let i = 0; i < withdrawShards; i++) {
          shards.push(await instance.tokenOfOwnerByIndex(depositor.address, i));
        }
        await instance.connect(depositor)['withdraw(uint256[])'](shards);

        const newDepositAmount = ethers.utils.parseEther('1');
        await instance
          .connect(depositor)
          ['deposit()']({ value: newDepositAmount });
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
              await instance.tokenOfOwnerByIndex(depositor.address, i),
            );
          }

          await expect(
            instance.connect(secondDepositor)['withdraw(uint256[])'](shards),
          ).to.be.revertedWithCustomError(
            instance,
            'ShardVault__NotShardOwner',
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
              await instance.tokenOfOwnerByIndex(depositor.address, i),
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
          await instance['setMaxMintBalance(uint64)'](BigNumber.from('100'));
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
              await instance.tokenOfOwnerByIndex(depositor.address, i),
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

    describe('#claimYield(uint256[], uint256)', () => {
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
          await pethJpegdVault['getCreditLimit(address,uint256)'](
            pethInstance.address,
            punkId,
          )
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
        const shardIds = [];
        const oldclaimedJPEGPerShard = [];
        for (let i = 1; i < 51; i++) {
          let shardId = BigNumber.from(i.toString());
          shardIds.push(shardId);
          oldclaimedJPEGPerShard.push(
            await pethInstance['claimedJPEGPerShard(uint256)'](shardId),
          );
        }

        await pethInstance
          .connect(depositor)
          ['claimYield(uint256[],uint256)'](
            shardIds,
            ethers.constants.MaxUint256,
          );

        const newclaimedJPEGPerShard = [];
        for (let i = 0; i < shardIds.length; i++) {
          newclaimedJPEGPerShard.push(
            cumulativeJPEGPerShard.sub(oldclaimedJPEGPerShard[i]),
          );
        }

        for (let i = 0; i < shardIds.length; i++) {
          expect(
            await pethInstance['claimedJPEGPerShard(uint256)'](shardIds[i]),
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
          await pethJpegdVault['getCreditLimit(address,uint256)'](
            pethInstance.address,
            punkId,
          )
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
        const shardIds = [];
        const oldclaimedETHPerShard = [];
        for (let i = 1; i < 51; i++) {
          let shardId = BigNumber.from(i.toString());
          shardIds.push(shardId);
          oldclaimedETHPerShard.push(
            await pethInstance['claimedETHPerShard(uint256)'](shardId),
          );
        }

        await pethInstance
          .connect(depositor)
          ['claimYield(uint256[],uint256)'](
            shardIds,
            ethers.constants.MaxUint256,
          );

        const newclaimedETHPerShard = [];
        for (let i = 0; i < shardIds.length; i++) {
          newclaimedETHPerShard.push(
            cumulativeETHPerShard.sub(oldclaimedETHPerShard[i]),
          );
        }

        for (let i = 0; i < shardIds.length; i++) {
          expect(
            await pethInstance['claimedETHPerShard(uint256)'](shardIds[i]),
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
          await pethJpegdVault['getCreditLimit(address,uint256)'](
            pethInstance.address,
            punkId,
          )
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
        const shardIds = [];
        let claimedETH = BigNumber.from('0');
        for (let i = 1; i < 51; i++) {
          let shardId = BigNumber.from(i.toString());
          shardIds.push(shardId);
          claimedETH = claimedETH.add(
            cumulativeETHPerShard.sub(
              await pethInstance.callStatic['claimedETHPerShard(uint256)'](
                shardId,
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
          ['claimYield(uint256[],uint256)'](
            shardIds,
            ethers.constants.MaxUint256,
          );

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
          await pethJpegdVault['getCreditLimit(address,uint256)'](
            pethInstance.address,
            punkId,
          )
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
        const shardIds = [];
        let claimedJPEG = BigNumber.from(0);

        for (let i = 1; i < 51; i++) {
          let shardId = BigNumber.from(i.toString());
          shardIds.push(shardId);
          claimedJPEG = claimedJPEG.add(
            cumulativeJPEGPerShard.sub(
              await pethInstance.callStatic['claimedJPEGPerShard(uint256)'](
                shardId,
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
          ['claimYield(uint256[],uint256)'](
            shardIds,
            ethers.constants.MaxUint256,
          );

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
          await pethJpegdVault['getCreditLimit(address,uint256)'](
            pethInstance.address,
            punkId,
          )
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

        const shardIds = [];
        let claimedJPEG = BigNumber.from('0');
        for (let i = 1; i < 51; i++) {
          let shardId = BigNumber.from(i.toString());
          shardIds.push(shardId);
          claimedJPEG = claimedJPEG.add(
            cumulativeJPEGPerShard.sub(
              await pethInstance.callStatic['claimedJPEGPerShard(uint256)'](
                shardId,
              ),
            ),
          );
        }

        const jpegFee = claimedJPEG
          .mul(await pethInstance['yieldFeeBP()']())
          .div(BASIS_POINTS);

        const claimedJPEGMinusFee = claimedJPEG.sub(jpegFee);

        await expect(() =>
          pethInstance
            .connect(depositor)
            ['claimYield(uint256[],uint256)'](
              shardIds,
              ethers.constants.MaxUint256,
            ),
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
          await pethJpegdVault['getCreditLimit(address,uint256)'](
            pethInstance.address,
            punkId,
          )
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
        const shardIds = [];
        let claimedETH = BigNumber.from('0');
        for (let i = 1; i < 51; i++) {
          let shardId = BigNumber.from(i.toString());
          shardIds.push(shardId);
          claimedETH = claimedETH.add(
            cumulativeETHPerShard.sub(
              await pethInstance.callStatic['claimedETHPerShard(uint256)'](
                shardId,
              ),
            ),
          );
        }

        const ETHFee = claimedETH
          .mul(await pethInstance['yieldFeeBP()']())
          .div(BASIS_POINTS);

        const claimedETHMinusFee = claimedETH.sub(ETHFee);

        await expect(() =>
          pethInstance
            .connect(depositor)
            ['claimYield(uint256[],uint256)'](
              shardIds,
              ethers.constants.MaxUint256,
            ),
        ).to.changeEtherBalances(
          [depositor, pethInstance],
          [
            claimedETHMinusFee,
            claimedETHMinusFee.mul(ethers.constants.NegativeOne),
          ],
        );
      });
      it('applies yield fee discount corresponding to DAWN_OF_INSRT token provided', async () => {
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
          await pethJpegdVault['getCreditLimit(address,uint256)'](
            pethInstance.address,
            punkId,
          )
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
        const shardIds = [];
        let claimedETH = BigNumber.from('0');
        for (let i = 1; i < 51; i++) {
          let shardId = BigNumber.from(i.toString());
          shardIds.push(shardId);
          claimedETH = claimedETH.add(
            cumulativeETHPerShard.sub(
              await pethInstance.callStatic['claimedETHPerShard(uint256)'](
                shardId,
              ),
            ),
          );
        }

        const discountedYieldFee = BigNumber.from(
          (await pethInstance['yieldFeeBP()']()).toString(),
        )
          .mul(TIER4_FEE_COEFFICIENT)
          .div(BASIS_POINTS);
        const ETHFee = claimedETH.mul(discountedYieldFee).div(BASIS_POINTS);

        const oldAccruedFees = await pethInstance.callStatic['accruedFees()']();

        await pethInstance
          .connect(depositor)
          ['claimYield(uint256[],uint256)'](shardIds, dawnOfInsrtID);

        const newAccruedFees = await pethInstance.callStatic['accruedFees()']();
        expect(ETHFee).to.eq(newAccruedFees.sub(oldAccruedFees));
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
            await pethJpegdVault['getCreditLimit(address,uint256)'](
              pethInstance.address,
              punkId,
            )
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

          const shardIds = [];
          for (let i = 1; i < 51; i++) {
            let shardId = BigNumber.from(i.toString());
            shardIds.push(shardId);
          }

          await expect(
            pethInstance
              .connect(depositor)
              ['claimYield(uint256[],uint256)'](
                shardIds,
                ethers.constants.MaxUint256,
              ),
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
            await pethJpegdVault['getCreditLimit(address,uint256)'](
              pethInstance.address,
              punkId,
            )
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

          const shardIds = [];
          for (let i = 1; i < 111; i++) {
            let shardId = BigNumber.from(i.toString());
            shardIds.push(shardId);
          }

          await expect(
            pethInstance
              .connect(depositor)
              ['claimYield(uint256[],uint256)'](
                shardIds,
                ethers.constants.MaxUint256,
              ),
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
            await pethJpegdVault['getCreditLimit(address,uint256)'](
              pethInstance.address,
              punkId,
            )
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

          const shardIds = [];
          for (let i = 1; i < 51; i++) {
            let shardId = BigNumber.from(i.toString());
            shardIds.push(shardId);
          }

          await expect(
            pethInstance
              .connect(secondDepositor)
              ['claimYield(uint256[],uint256)'](
                shardIds,
                ethers.constants.MaxUint256,
              ),
          ).to.be.revertedWithCustomError(
            pethInstance,
            'ShardVault__NotShardOwner',
          );
        });
        it('claimer is not DAWN_OF_INSRT token owner', async () => {
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
            await pethJpegdVault['getCreditLimit(address,uint256)'](
              pethInstance.address,
              punkId,
            )
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

          const shardIds = [];
          for (let i = 1; i < 51; i++) {
            let shardId = BigNumber.from(i.toString());
            shardIds.push(shardId);
          }

          await expect(
            pethInstance
              .connect(depositor)
              ['claimYield(uint256[],uint256)'](
                shardIds,
                ethers.constants.Zero,
              ),
          ).to.be.revertedWithCustomError(
            pethInstance,
            'ShardVault__NotDawnOfInsrtTokenOwner',
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
        const shardIds = [];
        const oldclaimedETHPerShard = [];
        for (let i = 1; i < 51; i++) {
          let shardId = BigNumber.from(i.toString());
          shardIds.push(shardId);
          oldclaimedETHPerShard.push(
            await pethInstance['claimedETHPerShard(uint256)'](shardId),
          );
        }

        await pethInstance
          .connect(depositor)
          ['claimExcessETH(uint256[])'](shardIds);

        const newclaimedETHPerShard = [];
        for (let i = 0; i < shardIds.length; i++) {
          newclaimedETHPerShard.push(
            cumulativeETHPerShard.sub(oldclaimedETHPerShard[i]),
          );
        }

        for (let i = 0; i < shardIds.length; i++) {
          expect(
            await pethInstance['claimedETHPerShard(uint256)'](shardIds[i]),
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
        const shardIds = [];
        let claimedETH = BigNumber.from('0');
        for (let i = 1; i < 51; i++) {
          let shardId = BigNumber.from(i.toString());
          shardIds.push(shardId);
          claimedETH = claimedETH.add(
            cumulativeETHPerShard.sub(
              await pethInstance.callStatic['claimedETHPerShard(uint256)'](
                shardId,
              ),
            ),
          );
        }

        await expect(() =>
          pethInstance
            .connect(depositor)
            ['claimExcessETH(uint256[])'](shardIds),
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

        const shardIds = [];
        for (let i = 1; i < 51; i++) {
          let shardId = BigNumber.from(i.toString());
          shardIds.push(shardId);
        }

        await expect(() =>
          pethInstance
            .connect(depositor)
            ['claimExcessETH(uint256[])'](shardIds),
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

          const shardIds = [];
          for (let i = 1; i < 51; i++) {
            let shardId = BigNumber.from(i.toString());
            shardIds.push(shardId);
          }

          await expect(
            pethInstance
              .connect(depositor)
              ['claimExcessETH(uint256[])'](shardIds),
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
            await pethJpegdVault['getCreditLimit(address,uint256)'](
              pethInstance.address,
              punkId,
            )
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
          const shardIds = [];
          for (let i = 1; i < 51; i++) {
            let shardId = BigNumber.from(i.toString());
            shardIds.push(shardId);
          }

          await expect(
            pethInstance
              .connect(depositor)
              ['claimExcessETH(uint256[])'](shardIds),
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

          const shardIds = [];
          for (let i = 1; i < 111; i++) {
            let shardId = BigNumber.from(i.toString());
            shardIds.push(shardId);
          }

          await expect(
            pethInstance
              .connect(depositor)
              ['claimExcessETH(uint256[])'](shardIds),
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

          const shardIds = [];
          for (let i = 1; i < 51; i++) {
            let shardId = BigNumber.from(i.toString());
            shardIds.push(shardId);
          }

          await expect(
            pethInstance
              .connect(secondDepositor)
              ['claimExcessETH(uint256[])'](shardIds),
          ).to.be.revertedWithCustomError(
            pethInstance,
            'ShardVault__NotShardOwner',
          );
        });
      });
    });
  });
}
