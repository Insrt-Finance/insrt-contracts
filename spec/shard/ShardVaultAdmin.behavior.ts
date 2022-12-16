import hre, { ethers } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { BigNumber } from 'ethers';
import { expect } from 'chai';
import {
  ICryptoPunkMarket,
  ICryptoPunkMarket__factory,
  IERC20,
  INFTVault,
  IShardVault,
  ICurveMetaPool,
  IMarketPlaceHelper,
  IERC721,
} from '../../typechain-types';
import {
  IJpegCardsCigStaking,
  ILPFarming,
  IVault,
} from '../../typechain-types/contracts/interfaces/jpegd';
import { IVault__factory } from '../../typechain-types/factories/contracts/interfaces/jpegd';

export interface ShardVaultAdminBehaviorArgs {
  getProtocolOwner: () => Promise<SignerWithAddress>;
}

export function describeBehaviorOfShardVaultAdmin(
  deploy: () => Promise<IShardVault>,
  secondDeploy: () => Promise<IShardVault>,
  pethDeploy: () => Promise<IShardVault>,
  args: ShardVaultAdminBehaviorArgs,
  skips?: string[],
) {
  describe('::ShardVaultAdmin', () => {
    let depositor: SignerWithAddress;
    let owner: SignerWithAddress;
    let nonOwner: SignerWithAddress;
    let cardOwner: SignerWithAddress;
    let instance: IShardVault;
    let secondInstance: IShardVault;
    let pethInstance: IShardVault;
    let cryptoPunkMarket: ICryptoPunkMarket;
    let pUSD: IERC20;
    let pETH: IERC20;
    let jpeg: IERC20;
    let jpegdVault: INFTVault;
    let pethJpegdVault: INFTVault;
    let jpegCardsCigStaking: IJpegCardsCigStaking;
    let jpegCards: IERC721;
    let lpFarm: ILPFarming;

    const punkId = BigNumber.from('2534');
    const CRYPTO_PUNKS_MARKET = '0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB';
    const PUSD = '0x466a756E9A7401B5e2444a3fCB3c2C12FBEa0a54';
    const PETH = '0x836A808d4828586A69364065A1e064609F5078c7';
    const JPEGD_VAULT = '0xD636a2fC1C18A54dB4442c3249D5e620cf8fE98F';
    const JPEG = '0xE80C0cd204D654CEbe8dd64A4857cAb6Be8345a3';
    const PETH_JPEGD_VAULT = '0x4e5F305bFCa77b17f804635A9bA669e187d51719';
    const PUSD_CITADEL = '0xF6Cbf5e56a8575797069c7A7FBED218aDF17e3b2';
    const PETH_CITADEL = '0x56D1b6Ac326e152C9fAad749F1F4f9737a049d46';
    const LP_FARM = '0xb271d2C9e693dde033d97f8A3C9911781329E4CA';
    const curvePUSDPoolAddress = '0x8EE017541375F6Bcd802ba119bdDC94dad6911A1';
    const curvePETHPoolAddress = '0x9848482da3Ee3076165ce6497eDA906E66bB85C5';
    const cardOwnerAddress = '0xeDE2a066F4aB9bB21D768aD0367F539978EE6f8c';
    const cardID = BigNumber.from('513');
    const JPEG_CARDS_CIG_STAKING = '0xFf9233825542977cd093E9Ffb8F0fC526164D3B7';
    const targetLTVBP = BigNumber.from('2800');
    const BASIS_POINTS = BigNumber.from('10000');
    const punkPurchaseCallsPETH: IMarketPlaceHelper.EncodedCallStruct[] = [];
    const punkPurchaseCallsPUSD: IMarketPlaceHelper.EncodedCallStruct[] = [];

    before(async () => {
      cryptoPunkMarket = await ethers.getContractAt(
        'ICryptoPunkMarket',
        CRYPTO_PUNKS_MARKET,
      );

      pUSD = <IERC20>(
        await ethers.getContractAt(
          '@solidstate/contracts/interfaces/IERC20.sol:IERC20',
          PUSD,
        )
      );

      pETH = <IERC20>(
        await ethers.getContractAt(
          '@solidstate/contracts/interfaces/IERC20.sol:IERC20',
          PETH,
        )
      );

      jpeg = <IERC20>(
        await ethers.getContractAt(
          '@solidstate/contracts/interfaces/IERC20.sol:IERC20',
          JPEG,
        )
      );

      jpegdVault = await ethers.getContractAt('INFTVault', JPEGD_VAULT);
      pethJpegdVault = await ethers.getContractAt(
        'INFTVault',
        PETH_JPEGD_VAULT,
      );

      jpegCardsCigStaking = <IJpegCardsCigStaking>(
        await ethers.getContractAt(
          'IJpegCardsCigStaking',
          JPEG_CARDS_CIG_STAKING,
        )
      );

      jpegCards = <IERC721>(
        await ethers.getContractAt(
          'IERC721',
          await jpegCardsCigStaking.callStatic['cards()'](),
        )
      );

      lpFarm = await ethers.getContractAt('ILPFarming', LP_FARM);
    });

    beforeEach(async () => {
      instance = await deploy();
      secondInstance = await secondDeploy();
      pethInstance = await pethDeploy();
      [depositor, nonOwner] = await ethers.getSigners();
      owner = await args.getProtocolOwner();

      cardOwner = await ethers.getSigner(cardOwnerAddress);

      await hre.network.provider.request({
        method: 'hardhat_impersonateAccount',
        params: [cardOwnerAddress],
      });

      await instance.connect(owner)['setIsEnabled(bool)'](true);
      await secondInstance.connect(owner)['setIsEnabled(bool)'](true);
      await pethInstance.connect(owner)['setIsEnabled(bool)'](true);

      await instance
        .connect(owner)
        ['setMaxUserShards(uint256)'](BigNumber.from('110'));
      await secondInstance
        .connect(owner)
        ['setMaxUserShards(uint256)'](BigNumber.from('110'));
      await pethInstance
        .connect(owner)
        ['setMaxUserShards(uint256)'](BigNumber.from('110'));

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
    });

    describe('#purchasePunk((bytes,uint256,address)[],uint256)', () => {
      it('purchases punk from CryptoPunkMarket', async () => {
        await instance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await instance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        await instance
          .connect(owner)
          ['purchasePunk((bytes,uint256,address)[],uint256)'](
            punkPurchaseCallsPUSD,
            punkId,
          );

        expect(
          await cryptoPunkMarket['punkIndexToAddress(uint256)'](punkId),
        ).to.eq(instance.address);
      });

      it('collects acquisition fee', async () => {
        await instance.connect(owner).setMaxUserShards(BigNumber.from('200'));
        await instance.connect(owner).setMaxSupply(BigNumber.from('200'));
        await instance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('200') });

        const price = (
          await cryptoPunkMarket['punksOfferedForSale(uint256)'](punkId)
        ).minValue;

        await instance
          .connect(owner)
          ['purchasePunk((bytes,uint256,address)[],uint256)'](
            punkPurchaseCallsPUSD,
            punkId,
          );

        expect(await instance.callStatic.accruedFees()).to.eq(
          price
            .mul(await instance.callStatic.acquisitionFeeBP())
            .div(BASIS_POINTS),
        );

        const secondPunkId = 3588;
        const secondPunkPurchaseData =
          cryptoPunkMarket.interface.encodeFunctionData('buyPunk', [
            secondPunkId,
          ]);
        const secondTransferData =
          cryptoPunkMarket.interface.encodeFunctionData('transferPunk', [
            instance.address,
            secondPunkId,
          ]);

        const secondPrice = (
          await cryptoPunkMarket['punksOfferedForSale(uint256)'](secondPunkId)
        ).minValue;

        const secondPunkPurchaseCallsPUSD: IMarketPlaceHelper.EncodedCallStruct[] =
          [
            {
              data: secondPunkPurchaseData,
              value: secondPrice,
              target: CRYPTO_PUNKS_MARKET,
            },
            {
              data: secondTransferData,
              value: 0,
              target: CRYPTO_PUNKS_MARKET,
            },
          ];

        await instance
          .connect(owner)
          ['purchasePunk((bytes,uint256,address)[],uint256)'](
            secondPunkPurchaseCallsPUSD,
            secondPunkId,
          );
        const firstFee = price
          .mul(await instance.callStatic.acquisitionFeeBP())
          .div(BASIS_POINTS);
        const secondFee = secondPrice
          .mul(await instance.callStatic.acquisitionFeeBP())
          .div(BASIS_POINTS);

        expect(await instance.callStatic.accruedFees()).to.eq(
          firstFee.add(secondFee),
        );
      });

      it('uses vault ETH for punk purchase', async () => {
        await instance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await instance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        const [, , , price] = await cryptoPunkMarket[
          'punksOfferedForSale(uint256)'
        ](punkId);

        await expect(() =>
          instance
            .connect(owner)
            .connect(owner)
            ['purchasePunk((bytes,uint256,address)[],uint256)'](
              punkPurchaseCallsPUSD,
              punkId,
            ),
        ).to.changeEtherBalances(
          [instance, cryptoPunkMarket],
          [price.mul(ethers.constants.NegativeOne), price],
        );
      });

      it('sets `invested` flag to true', async () => {
        await instance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await instance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        await instance
          .connect(owner)
          .connect(owner)
          ['purchasePunk((bytes,uint256,address)[],uint256)'](
            punkPurchaseCallsPUSD,
            punkId,
          );
        expect(await instance.isInvested()).to.be.true;
      });

      it('adds punkId to `ownedTokenIds`', async () => {
        await instance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await instance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        await instance
          .connect(owner)
          .connect(owner)
          ['purchasePunk((bytes,uint256,address)[],uint256)'](
            punkPurchaseCallsPUSD,
            punkId,
          );

        const [id] = await instance['ownedTokenIds()']();
        expect(id).to.eq(punkId);
      });

      describe('reverts if', () => {
        it('called by non-owner', async () => {
          await expect(
            instance
              .connect(nonOwner)
              ['purchasePunk((bytes,uint256,address)[],uint256)'](
                punkPurchaseCallsPUSD,
                punkId,
              ),
          ).to.be.revertedWithCustomError(
            instance,
            'ShardVault__NotProtocolOwner',
          );
        });
        it('collection is not punks', async () => {
          await expect(
            secondInstance
              .connect(owner)
              ['purchasePunk((bytes,uint256,address)[],uint256)'](
                punkPurchaseCallsPUSD,
                punkId,
              ),
          ).to.be.revertedWithCustomError(
            instance,
            'ShardVault__CollectionNotPunks',
          );
        });
      });
    });

    describe('#collateralizePunkPUSD(uint256,uint256,bool)', () => {
      it('borrows requested amount of pUSD', async () => {
        await instance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await instance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        await instance
          .connect(owner)
          ['purchasePunk((bytes,uint256,address)[],uint256)'](
            punkPurchaseCallsPUSD,
            punkId,
          );

        const requestedBorrow = (
          await jpegdVault.callStatic['getNFTValueUSD(uint256)'](punkId)
        )
          .mul(targetLTVBP)
          .div(BASIS_POINTS);

        const settings = await jpegdVault.callStatic['settings()']();
        const actualBorrow = requestedBorrow.sub(
          requestedBorrow
            .mul(settings.organizationFeeRate.numerator)
            .div(settings.organizationFeeRate.denominator),
        );

        await expect(() =>
          instance
            .connect(owner)
            ['collateralizePunkPUSD(uint256,uint256,bool)'](
              punkId,
              requestedBorrow,
              false,
            ),
        ).to.changeTokenBalance(pUSD, instance, actualBorrow);
      });

      it('borrows multiple times until target LTV is reached', async () => {
        await instance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await instance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        await instance
          .connect(owner)
          ['purchasePunk((bytes,uint256,address)[],uint256)'](
            punkPurchaseCallsPUSD,
            punkId,
          );

        const settings = await jpegdVault.callStatic['settings()']();
        let requestedBorrow = (
          await jpegdVault.callStatic['getNFTValueUSD(uint256)'](punkId)
        )
          .mul(BigNumber.from('2000'))
          .div(BASIS_POINTS);

        let actualBorrow = requestedBorrow.sub(
          requestedBorrow
            .mul(settings.organizationFeeRate.numerator)
            .div(settings.organizationFeeRate.denominator),
        );

        await expect(() =>
          instance
            .connect(owner)
            ['collateralizePunkPUSD(uint256,uint256,bool)'](
              punkId,
              requestedBorrow,
              false,
            ),
        ).to.changeTokenBalance(pUSD, instance, actualBorrow);

        const { timestamp: borrowTimeStamp } = await ethers.provider.getBlock(
          'latest',
        );

        const duration = 10;
        await hre.network.provider.send('evm_setNextBlockTimestamp', [
          borrowTimeStamp + duration,
        ]);

        requestedBorrow = (
          await jpegdVault.callStatic['getNFTValueUSD(uint256)'](punkId)
        )
          .mul(BigNumber.from('2000'))
          .div(BASIS_POINTS);

        const oldBalance = await pUSD['balanceOf(address)'](instance.address);

        await instance
          .connect(owner)
          ['collateralizePunkPUSD(uint256,uint256,bool)'](
            punkId,
            requestedBorrow,
            false,
          );

        const newBalance = await pUSD['balanceOf(address)'](instance.address);

        const debtInterest = await jpegdVault.callStatic[
          'getDebtInterest(uint256)'
        ](punkId);

        actualBorrow = requestedBorrow
          .mul(targetLTVBP.sub(BigNumber.from('2000')))
          .div(BigNumber.from('2000'));

        expect(newBalance.sub(oldBalance))
          .to.be.lte(actualBorrow.sub(debtInterest).add(ethers.constants.One))
          .gte(actualBorrow.sub(debtInterest).sub(ethers.constants.One));
      });

      describe('reverts if', () => {
        it('sum of requested borrow and total debt is larger than targetLTV', async () => {
          await instance.connect(owner).setMaxSupply(BigNumber.from('100'));
          await instance
            .connect(depositor)
            .deposit({ value: ethers.utils.parseEther('100') });

          await instance
            .connect(owner)
            ['purchasePunk((bytes,uint256,address)[],uint256)'](
              punkPurchaseCallsPUSD,
              punkId,
            );

          let requestedBorrow = (
            await jpegdVault.callStatic['getNFTValueUSD(uint256)'](punkId)
          )
            .mul(BigNumber.from('2000'))
            .div(BASIS_POINTS);

          await instance
            .connect(owner)
            ['collateralizePunkPUSD(uint256,uint256,bool)'](
              punkId,
              await jpegdVault.callStatic['getNFTValueUSD(uint256)'](punkId),
              false,
            );

          const { timestamp: borrowTimeStamp } = await ethers.provider.getBlock(
            'latest',
          );
          const duration = 10;
          await hre.network.provider.send('evm_setNextBlockTimestamp', [
            borrowTimeStamp + duration,
          ]);

          await expect(
            instance
              .connect(owner)
              ['collateralizePunkPUSD(uint256,uint256,bool)'](
                punkId,
                requestedBorrow,
                false,
              ),
          ).to.be.revertedWithCustomError(
            instance,
            'ShardVault__TargetLTVReached',
          );
        });

        it('vault is not PUSD vault', async () => {
          await expect(
            pethInstance
              .connect(owner)
              ['collateralizePunkPUSD(uint256,uint256,bool)'](
                punkId,
                ethers.constants.One,
                false,
              ),
          ).to.be.revertedWithCustomError(
            pethInstance,
            'ShardVault__CallTypeProhibited',
          );
        });
        it('called by non-owner', async () => {
          await expect(
            instance
              .connect(nonOwner)
              ['collateralizePunkPUSD(uint256,uint256,bool)'](
                punkId,
                ethers.constants.One,
                false,
              ),
          ).to.be.revertedWithCustomError(
            instance,
            'ShardVault__NotProtocolOwner',
          );
        });
      });
    });

    describe('#collateralizePunkPETH(uint256,uint256,bool)', () => {
      it('borrows requested amount of pETH', async () => {
        await pethInstance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await pethInstance
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

        await expect(() =>
          pethInstance
            .connect(owner)
            ['collateralizePunkPETH(uint256,uint256,bool)'](
              punkId,
              requestedBorrow,
              false,
            ),
        ).to.changeTokenBalance(pETH, pethInstance, actualBorrow);
      });

      it('borrows multiple times until target LTV is reached', async () => {
        await pethInstance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await pethInstance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        await pethInstance
          .connect(owner)
          ['purchasePunk((bytes,uint256,address)[],uint256)'](
            punkPurchaseCallsPETH,
            punkId,
          );

        const settings = await pethJpegdVault.callStatic['settings()']();
        let requestedBorrow = (
          await pethJpegdVault.callStatic['getNFTValueETH(uint256)'](punkId)
        )
          .mul(BigNumber.from('2000'))
          .div(BASIS_POINTS);

        let actualBorrow = requestedBorrow.sub(
          requestedBorrow
            .mul(settings.organizationFeeRate.numerator)
            .div(settings.organizationFeeRate.denominator),
        );

        await expect(() =>
          pethInstance
            .connect(owner)
            ['collateralizePunkPETH(uint256,uint256,bool)'](
              punkId,
              requestedBorrow,
              false,
            ),
        ).to.changeTokenBalance(pETH, pethInstance, actualBorrow);

        const { timestamp: borrowTimeStamp } = await ethers.provider.getBlock(
          'latest',
        );

        const duration = 10;
        await hre.network.provider.send('evm_setNextBlockTimestamp', [
          borrowTimeStamp + duration,
        ]);

        requestedBorrow = (
          await pethJpegdVault.callStatic['getNFTValueETH(uint256)'](punkId)
        )
          .mul(BigNumber.from('2000'))
          .div(BASIS_POINTS);

        const oldBalance = await pETH['balanceOf(address)'](
          pethInstance.address,
        );

        await pethInstance
          .connect(owner)
          ['collateralizePunkPETH(uint256,uint256,bool)'](
            punkId,
            requestedBorrow,
            false,
          );

        const newBalance = await pETH['balanceOf(address)'](
          pethInstance.address,
        );

        const debtInterest = await pethJpegdVault.callStatic[
          'getDebtInterest(uint256)'
        ](punkId);

        actualBorrow = requestedBorrow
          .mul(targetLTVBP.sub(BigNumber.from('2000')))
          .div(BigNumber.from('2000'));

        expect(newBalance.sub(oldBalance))
          .to.be.lte(actualBorrow.sub(debtInterest).add(ethers.constants.One))
          .gte(actualBorrow.sub(debtInterest).sub(ethers.constants.One));
      });

      describe('reverts if', () => {
        it('sum of requested borrow and total debt is larger than targetLTV', async () => {
          await pethInstance.connect(owner).setMaxSupply(BigNumber.from('100'));
          await pethInstance
            .connect(depositor)
            .deposit({ value: ethers.utils.parseEther('100') });

          await pethInstance
            .connect(owner)
            ['purchasePunk((bytes,uint256,address)[],uint256)'](
              punkPurchaseCallsPETH,
              punkId,
            );

          let requestedBorrow = (
            await pethJpegdVault.callStatic['getNFTValueETH(uint256)'](punkId)
          )
            .mul(BigNumber.from('2000'))
            .div(BASIS_POINTS);

          await pethInstance
            .connect(owner)
            ['collateralizePunkPETH(uint256,uint256,bool)'](
              punkId,
              await pethJpegdVault.callStatic['getNFTValueETH(uint256)'](
                punkId,
              ),
              false,
            );

          const { timestamp: borrowTimeStamp } = await ethers.provider.getBlock(
            'latest',
          );
          const duration = 10;
          await hre.network.provider.send('evm_setNextBlockTimestamp', [
            borrowTimeStamp + duration,
          ]);

          await expect(
            pethInstance
              .connect(owner)
              ['collateralizePunkPETH(uint256,uint256,bool)'](
                punkId,
                requestedBorrow,
                false,
              ),
          ).to.be.revertedWithCustomError(
            pethInstance,
            'ShardVault__TargetLTVReached',
          );
        });

        it('vault is not PETH vault', async () => {
          await expect(
            instance
              .connect(owner)
              ['collateralizePunkPETH(uint256,uint256,bool)'](
                punkId,
                ethers.constants.One,
                false,
              ),
          ).to.be.revertedWithCustomError(
            instance,
            'ShardVault__CallTypeProhibited',
          );
        });

        it('called by non-owner', async () => {
          await expect(
            pethInstance
              .connect(nonOwner)
              ['collateralizePunkPETH(uint256,uint256,bool)'](
                punkId,
                ethers.constants.One,
                false,
              ),
          ).to.be.revertedWithCustomError(
            pethInstance,
            'ShardVault__NotProtocolOwner',
          );
        });
      });
    });

    describe('#stakePUSD(uint256,uint256,uint256)', () => {
      it('completes three stages of staking', async () => {
        await instance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await instance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        await instance
          .connect(owner)
          ['purchasePunk((bytes,uint256,address)[],uint256)'](
            punkPurchaseCallsPUSD,
            punkId,
          );

        const requestedBorrow = (
          await jpegdVault.callStatic['getNFTValueUSD(uint256)'](punkId)
        )
          .mul(targetLTVBP)
          .div(BASIS_POINTS);

        const settings = await jpegdVault.callStatic['settings()']();
        const actualBorrow = requestedBorrow.sub(
          requestedBorrow
            .mul(settings.organizationFeeRate.numerator)
            .div(settings.organizationFeeRate.denominator),
        );

        await instance
          .connect(owner)
          ['collateralizePunkPUSD(uint256,uint256,bool)'](
            punkId,
            requestedBorrow,
            false,
          );

        const curvePUSDPool = <ICurveMetaPool>(
          await ethers.getContractAt('ICurveMetaPool', curvePUSDPoolAddress)
        );

        const minCurveLP = await curvePUSDPool.callStatic[
          'calc_token_amount(uint256[2],bool)'
        ]([actualBorrow, 0], true);

        const curveBasis = BigNumber.from('10000000000');
        const curveFee = BigNumber.from('4000000');
        const curveRemainder = curveBasis.sub(curveFee);

        const lpFarm = <ILPFarming>(
          await ethers.getContractAt('ILPFarming', LP_FARM)
        );

        const shares = await instance
          .connect(owner)
          .callStatic['stakePUSD(uint256,uint256,uint256)'](
            actualBorrow,
            minCurveLP.mul(curveRemainder).div(curveBasis),
            ethers.constants.One,
          );

        await instance
          .connect(owner)
          ['stakePUSD(uint256,uint256,uint256)'](
            actualBorrow,
            minCurveLP.mul(curveRemainder).div(curveBasis),
            ethers.constants.One,
          );

        const amount = (
          await lpFarm.callStatic['userInfo(uint256,address)'](
            ethers.constants.One,
            instance.address,
          )
        ).amount;

        expect(amount).to.eq(shares);
      });
      describe('reverts if', () => {
        it('vault is not PUSD vault', async () => {
          await expect(
            pethInstance
              .connect(owner)
              ['stakePUSD(uint256,uint256,uint256)'](
                ethers.constants.One,
                ethers.constants.One,
                ethers.constants.One,
              ),
          ).to.be.revertedWithCustomError(
            pethInstance,
            'ShardVault__CallTypeProhibited',
          );
        });

        it('called by non-owner', async () => {
          await expect(
            instance
              .connect(nonOwner)
              ['stakePUSD(uint256,uint256,uint256)'](
                ethers.constants.One,
                ethers.constants.One,
                ethers.constants.One,
              ),
          ).to.be.revertedWithCustomError(
            instance,
            'ShardVault__NotProtocolOwner',
          );
        });
      });
    });

    describe('#stakePETH(uint256,uint256,uint256)', () => {
      it('completes three stages of staking', async () => {
        await pethInstance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await pethInstance
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

        const lpFarm = <ILPFarming>(
          await ethers.getContractAt('ILPFarming', LP_FARM)
        );

        const shares = await pethInstance
          .connect(owner)
          .callStatic['stakePETH(uint256,uint256,uint256)'](
            actualBorrow,
            minCurveLP.mul(curveRemainder).div(curveBasis),
            ethers.constants.Two,
          );

        await pethInstance
          .connect(owner)
          ['stakePETH(uint256,uint256,uint256)'](
            actualBorrow,
            minCurveLP.mul(curveRemainder).div(curveBasis),
            ethers.constants.Two,
          );

        const amount = (
          await lpFarm.callStatic['userInfo(uint256,address)'](
            ethers.constants.Two,
            pethInstance.address,
          )
        ).amount;

        expect(amount).to.eq(shares);
      });
      describe('reverts if', () => {
        it('vault is not PETH vault', async () => {
          await expect(
            instance
              .connect(owner)
              ['stakePETH(uint256,uint256,uint256)'](
                ethers.constants.One,
                ethers.constants.One,
                ethers.constants.One,
              ),
          ).to.be.revertedWithCustomError(
            instance,
            'ShardVault__CallTypeProhibited',
          );
        });

        it('called by non-owner', async () => {
          await expect(
            pethInstance
              .connect(nonOwner)
              ['stakePETH(uint256,uint256,uint256)'](
                ethers.constants.One,
                ethers.constants.One,
                ethers.constants.One,
              ),
          ).to.be.revertedWithCustomError(
            pethInstance,
            'ShardVault__NotProtocolOwner',
          );
        });
      });
    });

    describe('#repayLoanPUSD(uint256,uint256,uint256,uint256)', () => {
      it('debt paid is approximately amount of debt reduction', async () => {
        await instance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await instance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });
        await instance
          .connect(owner)
          ['purchasePunk((bytes,uint256,address)[],uint256)'](
            punkPurchaseCallsPUSD,
            punkId,
          );

        const requestedBorrow = (
          await jpegdVault.callStatic['getNFTValueUSD(uint256)'](punkId)
        )
          .mul(targetLTVBP)
          .div(BASIS_POINTS);
        await instance
          .connect(owner)
          ['collateralizePunkPUSD(uint256,uint256,bool)'](
            punkId,
            requestedBorrow,
            false,
          );

        const settings = await jpegdVault.callStatic['settings()']();
        const actualBorrow = requestedBorrow.sub(
          requestedBorrow
            .mul(settings.organizationFeeRate.numerator)
            .div(settings.organizationFeeRate.denominator),
        );

        const { timestamp: borrowTimeStamp } = await ethers.provider.getBlock(
          'latest',
        );

        const curvePUSDPool = <ICurveMetaPool>(
          await ethers.getContractAt('ICurveMetaPool', curvePUSDPoolAddress)
        );

        const minCurveLP = await curvePUSDPool.callStatic[
          'calc_token_amount(uint256[2],bool)'
        ]([actualBorrow, 0], true);

        await instance.connect(owner)['stakePUSD(uint256,uint256,uint256)'](
          actualBorrow,
          minCurveLP.mul(9996).div(10000), //curve fee is 0.04% (unsure)
          ethers.constants.One,
        );

        const oldDebt = await instance.callStatic['totalDebt(uint256)'](punkId);
        const oldDebInterest = await jpegdVault.callStatic[
          'getDebtInterest(uint256)'
        ](punkId);

        const paymentAmount = BigNumber.from('100000000000000000');

        const duration = 100000;
        await hre.network.provider.send('evm_setNextBlockTimestamp', [
          borrowTimeStamp + duration,
        ]);

        const paidDebt = await instance
          .connect(owner)
          .callStatic['repayLoanPUSD(uint256,uint256,uint256,uint256)'](
            paymentAmount,
            0,
            1,
            punkId,
          );

        let tx = await instance
          .connect(owner)
          ['repayLoanPUSD(uint256,uint256,uint256,uint256)'](
            paymentAmount,
            0,
            1,
            punkId,
          );

        await tx.wait();

        const newDebt = await instance.callStatic['totalDebt(uint256)'](punkId);

        //remove one 'tick' since debt accrual occured right before read
        const accruedDebtInterest = oldDebInterest
          .mul(duration)
          .sub(oldDebInterest);
        //debt increased
        const debtDifference = newDebt.sub(oldDebt);

        //debtInterest calculations have rounding errors as per JPEG'd function
        //comments. Error boundary is chosen somewhat arbitrarily
        expect(accruedDebtInterest.sub(debtDifference)).to.closeTo(
          paidDebt,
          paidDebt.div(BigNumber.from('100000000000')),
        );
      });

      it('reduces debt owed at least by amount requested', async () => {
        await instance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await instance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });
        await instance
          .connect(owner)
          ['purchasePunk((bytes,uint256,address)[],uint256)'](
            punkPurchaseCallsPUSD,
            punkId,
          );
        const requestedBorrow = (
          await jpegdVault.callStatic['getNFTValueUSD(uint256)'](punkId)
        )
          .mul(targetLTVBP)
          .div(BASIS_POINTS);
        await instance
          .connect(owner)
          ['collateralizePunkPUSD(uint256,uint256,bool)'](
            punkId,
            requestedBorrow,
            false,
          );

        const settings = await jpegdVault.callStatic['settings()']();
        const actualBorrow = requestedBorrow.sub(
          requestedBorrow
            .mul(settings.organizationFeeRate.numerator)
            .div(settings.organizationFeeRate.denominator),
        );

        const { timestamp: borrowTimeStamp } = await ethers.provider.getBlock(
          'latest',
        );

        const curvePUSDPool = <ICurveMetaPool>(
          await ethers.getContractAt('ICurveMetaPool', curvePUSDPoolAddress)
        );

        const minCurveLP = await curvePUSDPool.callStatic[
          'calc_token_amount(uint256[2],bool)'
        ]([actualBorrow, 0], true);

        await instance.connect(owner)['stakePUSD(uint256,uint256,uint256)'](
          actualBorrow,
          minCurveLP.mul(9996).div(10000), //curve fee is 0.04% (unsure)
          ethers.constants.One,
        );

        const oldDebt = await instance.callStatic['totalDebt(uint256)'](punkId);
        const oldDebInterest = await jpegdVault.callStatic[
          'getDebtInterest(uint256)'
        ](punkId);

        const paymentAmount = BigNumber.from('100000000000000000');

        const duration = 100000;
        await hre.network.provider.send('evm_setNextBlockTimestamp', [
          borrowTimeStamp + duration,
        ]);

        await instance
          .connect(owner)
          ['repayLoanPUSD(uint256,uint256,uint256,uint256)'](
            paymentAmount,
            0,
            1,
            punkId,
          );

        const newDebt = await instance.callStatic['totalDebt(uint256)'](punkId);

        //remove one 'tick' since debt accrual occured right before read
        const accruedDebtInterest = oldDebInterest
          .mul(duration)
          .sub(oldDebInterest);
        //debt increased
        const debtDifference = newDebt.sub(oldDebt);

        expect(accruedDebtInterest.sub(debtDifference)).to.gt(paymentAmount);
      });

      describe('reverts if', () => {
        it('vault is not PUSD vault', async () => {
          await expect(
            pethInstance
              .connect(owner)
              ['repayLoanPUSD(uint256,uint256,uint256,uint256)'](
                ethers.constants.One,
                ethers.constants.One,
                ethers.constants.One,
                ethers.constants.One,
              ),
          ).to.be.revertedWithCustomError(
            pethInstance,
            'ShardVault__CallTypeProhibited',
          );
        });

        it('called by non-owner', async () => {
          await expect(
            instance
              .connect(nonOwner)
              ['repayLoanPUSD(uint256,uint256,uint256,uint256)'](
                ethers.constants.One,
                ethers.constants.One,
                ethers.constants.One,
                ethers.constants.One,
              ),
          ).to.be.revertedWithCustomError(
            instance,
            'ShardVault__NotProtocolOwner',
          );
        });
        it('paidDebt is less than requested amount', async () => {
          console.log('TODO');
        });
      });
    });

    describe('#repayLoanPETH(uint256,uint256,uint256,uint256)', () => {
      it('debt paid is approximately amount of debt reduction', async () => {
        await pethInstance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await pethInstance
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

        await pethInstance
          .connect(owner)
          ['collateralizePunkPETH(uint256,uint256,bool)'](
            punkId,
            requestedBorrow,
            false,
          );

        const settings = await pethJpegdVault.callStatic['settings()']();
        const actualBorrow = requestedBorrow.sub(
          requestedBorrow
            .mul(settings.organizationFeeRate.numerator)
            .div(settings.organizationFeeRate.denominator),
        );

        const { timestamp: borrowTimeStamp } = await ethers.provider.getBlock(
          'latest',
        );

        const curvePETHPool = <ICurveMetaPool>(
          await ethers.getContractAt('ICurveMetaPool', curvePETHPoolAddress)
        );

        const minCurveLP = await curvePETHPool.callStatic[
          'calc_token_amount(uint256[2],bool)'
        ]([actualBorrow, 0], true);

        await pethInstance.connect(owner)['stakePETH(uint256,uint256,uint256)'](
          actualBorrow,
          minCurveLP.mul(9996).div(10000), //curve fee is 0.04% (unsure)
          ethers.constants.Two,
        );

        const oldDebt = await pethInstance.callStatic['totalDebt(uint256)'](
          punkId,
        );
        const oldDebInterest = await pethJpegdVault.callStatic[
          'getDebtInterest(uint256)'
        ](punkId);

        const paymentAmount = BigNumber.from('100000000000000000');

        const duration = 100000;
        await hre.network.provider.send('evm_setNextBlockTimestamp', [
          borrowTimeStamp + duration,
        ]);

        const paidDebt = await pethInstance
          .connect(owner)
          .callStatic['repayLoanPETH(uint256,uint256,uint256,uint256)'](
            paymentAmount,
            0,
            2,
            punkId,
          );

        let tx = await pethInstance
          .connect(owner)
          ['repayLoanPETH(uint256,uint256,uint256,uint256)'](
            paymentAmount,
            0,
            2,
            punkId,
          );

        await tx.wait();

        const newDebt = await pethInstance.callStatic['totalDebt(uint256)'](
          punkId,
        );

        //remove one 'tick' since debt accrual occured right before read
        const accruedDebtInterest = oldDebInterest
          .mul(duration)
          .sub(oldDebInterest);
        ///debt increased
        const debtDifference = newDebt.sub(oldDebt);

        expect(accruedDebtInterest.sub(debtDifference)).to.closeTo(
          paidDebt,
          paidDebt.div(BigNumber.from('100000000000')),
        );
      });
      it('reduces debt owed by at least amount requested', async () => {
        await pethInstance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await pethInstance
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

        await pethInstance
          .connect(owner)
          ['collateralizePunkPETH(uint256,uint256,bool)'](
            punkId,
            requestedBorrow,
            false,
          );

        const settings = await pethJpegdVault.callStatic['settings()']();
        const actualBorrow = requestedBorrow.sub(
          requestedBorrow
            .mul(settings.organizationFeeRate.numerator)
            .div(settings.organizationFeeRate.denominator),
        );

        const { timestamp: borrowTimeStamp } = await ethers.provider.getBlock(
          'latest',
        );

        const curvePETHPool = <ICurveMetaPool>(
          await ethers.getContractAt('ICurveMetaPool', curvePETHPoolAddress)
        );

        const minCurveLP = await curvePETHPool.callStatic[
          'calc_token_amount(uint256[2],bool)'
        ]([actualBorrow, 0], true);

        await pethInstance.connect(owner)['stakePETH(uint256,uint256,uint256)'](
          actualBorrow,
          minCurveLP.mul(9996).div(10000), //curve fee is 0.04% (unsure)
          ethers.constants.Two,
        );

        const oldDebt = await pethInstance.callStatic['totalDebt(uint256)'](
          punkId,
        );
        const oldDebInterest = await pethJpegdVault.callStatic[
          'getDebtInterest(uint256)'
        ](punkId);

        const paymentAmount = BigNumber.from('100000000000000000');

        const duration = 100000;
        await hre.network.provider.send('evm_setNextBlockTimestamp', [
          borrowTimeStamp + duration,
        ]);

        await pethInstance
          .connect(owner)
          ['repayLoanPETH(uint256,uint256,uint256,uint256)'](
            paymentAmount,
            0,
            2,
            punkId,
          );

        const newDebt = await pethInstance.callStatic['totalDebt(uint256)'](
          punkId,
        );

        //remove one 'tick' since debt accrual occured right before read
        const accruedDebtInterest = oldDebInterest
          .mul(duration)
          .sub(oldDebInterest);
        ///debt increased
        const debtDifference = newDebt.sub(oldDebt);

        expect(accruedDebtInterest.sub(debtDifference)).to.gt(paymentAmount);
      });
      describe('reverts if', () => {
        it('vault is not PETH vault', async () => {
          await expect(
            instance
              .connect(owner)
              ['repayLoanPETH(uint256,uint256,uint256,uint256)'](
                ethers.constants.One,
                ethers.constants.One,
                ethers.constants.One,
                ethers.constants.One,
              ),
          ).to.be.revertedWithCustomError(
            instance,
            'ShardVault__CallTypeProhibited',
          );
        });

        it('called by non-owner', async () => {
          await expect(
            pethInstance
              .connect(nonOwner)
              ['repayLoanPETH(uint256,uint256,uint256,uint256)'](
                ethers.constants.One,
                ethers.constants.One,
                ethers.constants.One,
                ethers.constants.One,
              ),
          ).to.be.revertedWithCustomError(
            pethInstance,
            'ShardVault__NotProtocolOwner',
          );
        });
        it('paidDebt is less than requested amount', async () => {
          console.log('TODO');
        });
      });
    });

    describe('directRepayLoanPUSD(uint256 amount, uint256 punkId)', () => {
      it('uses vault PUSD to pay back debt, without unstaking', async () => {
        await instance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await instance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        await instance
          .connect(owner)
          ['purchasePunk((bytes,uint256,address)[],uint256)'](
            punkPurchaseCallsPUSD,
            punkId,
          );

        const requestedBorrow = (
          await jpegdVault.callStatic['getNFTValueUSD(uint256)'](punkId)
        )
          .mul(targetLTVBP)
          .div(BASIS_POINTS);

        await instance
          .connect(owner)
          ['collateralizePunkPUSD(uint256,uint256,bool)'](
            punkId,
            requestedBorrow,
            false,
          );

        const paybackAmount = ethers.utils.parseEther('2');

        await expect(() =>
          instance
            .connect(owner)
            ['directRepayLoanPUSD(uint256,uint256)'](
              ethers.utils.parseEther('2'),
              punkId,
            ),
        ).changeTokenBalance(
          pUSD,
          instance,
          paybackAmount.mul(ethers.constants.NegativeOne),
        );
      });

      describe('reverts if', () => {
        it('called by non-owner', async () => {
          await expect(
            instance
              .connect(nonOwner)
              ['directRepayLoanPUSD(uint256,uint256)'](
                ethers.constants.One,
                ethers.constants.One,
              ),
          ).to.be.revertedWithCustomError(
            instance,
            'ShardVault__NotProtocolOwner',
          );
        });
      });
    });

    describe('directRepayLoanPETH(uint256 amount, uint256 punkId)', () => {
      it('uses vault PETH to pay back debt, without unstaking', async () => {
        await pethInstance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await pethInstance
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

        await pethInstance
          .connect(owner)
          ['collateralizePunkPETH(uint256,uint256,bool)'](
            punkId,
            requestedBorrow,
            false,
          );

        const paybackAmount = ethers.utils.parseEther('2');

        await expect(() =>
          pethInstance
            .connect(owner)
            ['directRepayLoanPETH(uint256,uint256)'](
              ethers.utils.parseEther('2'),
              punkId,
            ),
        ).changeTokenBalance(
          pETH,
          pethInstance,
          paybackAmount.mul(ethers.constants.NegativeOne),
        );
      });

      describe('reverts if', () => {
        it('called by non-owner', async () => {
          await expect(
            pethInstance
              .connect(nonOwner)
              ['directRepayLoanPETH(uint256,uint256)'](
                ethers.constants.One,
                ethers.constants.One,
              ),
          ).to.be.revertedWithCustomError(
            pethInstance,
            'ShardVault__NotProtocolOwner',
          );
        });
      });
    });

    describe('#unstakePUSD(uint256,uint256,uint256)', () => {
      it('unstakes requested amount of autoComp shares from lpFarm and JPEG citadel', async () => {
        await instance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await instance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        await instance
          .connect(owner)
          ['purchasePunk((bytes,uint256,address)[],uint256)'](
            punkPurchaseCallsPUSD,
            punkId,
          );

        const requestedBorrow = (
          await jpegdVault.callStatic['getNFTValueUSD(uint256)'](punkId)
        )
          .mul(targetLTVBP)
          .div(BASIS_POINTS);

        const settings = await jpegdVault.callStatic['settings()']();
        const actualBorrow = requestedBorrow.sub(
          requestedBorrow
            .mul(settings.organizationFeeRate.numerator)
            .div(settings.organizationFeeRate.denominator),
        );

        await instance
          .connect(owner)
          ['collateralizePunkPUSD(uint256,uint256,bool)'](
            punkId,
            requestedBorrow,
            false,
          );

        const curvePUSDPool = <ICurveMetaPool>(
          await ethers.getContractAt('ICurveMetaPool', curvePUSDPoolAddress)
        );

        const minCurveLP = await curvePUSDPool.callStatic[
          'calc_token_amount(uint256[2],bool)'
        ]([actualBorrow, 0], true);

        const curveBasis = BigNumber.from('10000000000');
        const curveFee = BigNumber.from('4000000');
        const curveRemainder = curveBasis.sub(curveFee);

        const lpFarm = <ILPFarming>(
          await ethers.getContractAt('ILPFarming', LP_FARM)
        );

        const shares = await instance
          .connect(owner)
          .callStatic['stakePUSD(uint256,uint256,uint256)'](
            actualBorrow,
            minCurveLP.mul(curveRemainder).div(curveBasis),
            ethers.constants.One,
          );

        await instance
          .connect(owner)
          ['stakePUSD(uint256,uint256,uint256)'](
            actualBorrow,
            minCurveLP.mul(curveRemainder).div(curveBasis),
            ethers.constants.One,
          );

        const oldAmount = (
          await lpFarm.callStatic['userInfo(uint256,address)'](
            ethers.constants.One,
            instance.address,
          )
        ).amount;

        const unstakeAmount = ethers.utils.parseEther('2');

        await instance
          .connect(owner)
          ['unstakePUSD(uint256,uint256,uint256)'](unstakeAmount, 0, 1);

        const newAmount = (
          await lpFarm.callStatic['userInfo(uint256,address)'](
            ethers.constants.One,
            instance.address,
          )
        ).amount;

        expect(oldAmount.sub(newAmount)).to.eq(unstakeAmount);
      });
      it('converts withdrawn shares to pUSD', async () => {
        await instance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await instance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        await instance
          .connect(owner)
          ['purchasePunk((bytes,uint256,address)[],uint256)'](
            punkPurchaseCallsPUSD,
            punkId,
          );

        const requestedBorrow = (
          await jpegdVault.callStatic['getNFTValueUSD(uint256)'](punkId)
        )
          .mul(targetLTVBP)
          .div(BASIS_POINTS);

        const settings = await jpegdVault.callStatic['settings()']();
        const actualBorrow = requestedBorrow.sub(
          requestedBorrow
            .mul(settings.organizationFeeRate.numerator)
            .div(settings.organizationFeeRate.denominator),
        );

        await instance
          .connect(owner)
          ['collateralizePunkPUSD(uint256,uint256,bool)'](
            punkId,
            requestedBorrow,
            false,
          );

        const curvePUSDPool = <ICurveMetaPool>(
          await ethers.getContractAt('ICurveMetaPool', curvePUSDPoolAddress)
        );

        const minCurveLP = await curvePUSDPool.callStatic[
          'calc_token_amount(uint256[2],bool)'
        ]([actualBorrow, 0], true);

        const curveBasis = BigNumber.from('10000000000');
        const curveFee = BigNumber.from('4000000');
        const curveRemainder = curveBasis.sub(curveFee);

        await instance
          .connect(owner)
          ['stakePUSD(uint256,uint256,uint256)'](
            actualBorrow,
            minCurveLP.mul(curveRemainder).div(curveBasis),
            ethers.constants.One,
          );

        const unstakeAmount = ethers.utils.parseEther('2');

        const pUSD = await instance
          .connect(owner)
          .callStatic['unstakePUSD(uint256,uint256,uint256)'](
            unstakeAmount,
            0,
            1,
          );

        const pusdCitadel = IVault__factory.connect(PUSD_CITADEL, owner);

        const calcpUSD = await curvePUSDPool.callStatic[
          'calc_withdraw_one_coin(uint256,int128)'
        ](
          unstakeAmount
            .mul(await pusdCitadel['exchangeRate()']())
            .div(ethers.utils.parseEther('1')),
          0,
        );

        expect(pUSD).to.eq(calcpUSD);
      });

      describe('reverts if', async () => {
        it('called by non-owner', async () => {
          await expect(
            instance
              .connect(nonOwner)
              ['unstakePUSD(uint256,uint256,uint256)'](
                ethers.constants.One,
                ethers.constants.One,
                ethers.constants.One,
              ),
          ).to.be.revertedWithCustomError(
            instance,
            'ShardVault__NotProtocolOwner',
          );
        });
      });
    });

    describe('#unstakePETH(uint256,uint256,uint256)', () => {
      it('unstakes requested amount of autoComp shares from lpFarm and JPEG citadel', async () => {
        await pethInstance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await pethInstance
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

        const lpFarm = <ILPFarming>(
          await ethers.getContractAt('ILPFarming', LP_FARM)
        );

        await pethInstance
          .connect(owner)
          ['stakePETH(uint256,uint256,uint256)'](
            actualBorrow,
            minCurveLP.mul(curveRemainder).div(curveBasis),
            ethers.constants.Two,
          );

        const oldAmount = (
          await lpFarm.callStatic['userInfo(uint256,address)'](
            ethers.constants.Two,
            pethInstance.address,
          )
        ).amount;

        const unstakeAmount = ethers.utils.parseEther('2');

        await pethInstance
          .connect(owner)
          ['unstakePETH(uint256,uint256,uint256)'](unstakeAmount, 0, 2);

        const newAmount = (
          await lpFarm.callStatic['userInfo(uint256,address)'](
            ethers.constants.Two,
            pethInstance.address,
          )
        ).amount;

        expect(oldAmount.sub(newAmount)).to.eq(unstakeAmount);
      });

      it('converts withdrawn shares to pETH', async () => {
        await pethInstance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await pethInstance
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

        const unstakeAmount = ethers.utils.parseEther('2');

        const pethCitadel = IVault__factory.connect(PETH_CITADEL, owner);

        const pETH = await pethInstance
          .connect(owner)
          .callStatic['unstakePETH(uint256,uint256,uint256)'](
            unstakeAmount,
            0,
            2,
          );

        const calcPETH = await curvePETHPool.callStatic[
          'calc_withdraw_one_coin(uint256,int128)'
        ](
          unstakeAmount
            .mul(await pethCitadel['exchangeRate()']())
            .div(ethers.utils.parseEther('1')),
          ethers.constants.One,
        );

        expect(pETH).to.eq(calcPETH);
      });

      describe('reverts if', async () => {
        it('called by non-owner', async () => {
          await expect(
            pethInstance
              .connect(nonOwner)
              ['unstakePETH(uint256,uint256,uint256)'](
                ethers.constants.One,
                ethers.constants.One,
                ethers.constants.One,
              ),
          ).to.be.revertedWithCustomError(
            pethInstance,
            'ShardVault__NotProtocolOwner',
          );
        });
      });
    });

    describe('#closePunkPosition(uint256,uint256,uint256,bool)', () => {
      it('closes punk position', async () => {
        await pethInstance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await pethInstance
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

        const lpFarm = <ILPFarming>(
          await ethers.getContractAt('ILPFarming', LP_FARM)
        );

        await (
          await pethInstance
            .connect(owner)
            ['stakePETH(uint256,uint256,uint256)'](
              actualBorrow,
              minCurveLP.mul(curveRemainder).div(curveBasis),
              ethers.constants.Two,
            )
        ).wait();

        //provide pETH to pay back interest
        await curvePETHPool
          .connect(owner)
          .exchange(0, 1, ethers.utils.parseEther('20'), 1, {
            value: ethers.utils.parseEther('20'),
          });

        await pETH
          .connect(owner)
          ['transfer(address,uint256)'](
            pethInstance.address,
            ethers.utils.parseEther('10'),
          );

        await pethInstance
          .connect(owner)
          ['closePunkPosition(uint256,uint256,uint256,bool)'](
            punkId,
            0,
            2,
            false,
          );

        expect(
          (await jpegdVault['positions(uint256)'](punkId)).debtPrincipal,
        ).to.eq(ethers.constants.Zero);
        expect(await pethInstance['totalDebt(uint256)'](punkId)).to.eq(
          ethers.constants.Zero,
        );
      });

      describe('reverts if', () => {
        it('called by non-owner', async () => {
          await expect(
            pethInstance
              .connect(nonOwner)
              ['closePunkPosition(uint256,uint256,uint256,bool)'](
                ethers.constants.Zero,
                ethers.constants.Zero,
                ethers.constants.Zero,
                false,
              ),
          ).to.be.revertedWithCustomError(
            pethInstance,
            'ShardVault__NotProtocolOwner',
          );
        });
      });
    });

    describe('#provideYieldPETH(uint256,uint256,uin256)', () => {
      it('increases vault balance by JPEG provided', async () => {
        await pethInstance.connect(owner).setMaxSupply(BigNumber.from('200'));
        await pethInstance
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

        const oldJPEG = await jpeg['balanceOf(address)'](pethInstance.address);
        const revertId = await hre.network.provider.send('evm_snapshot');

        await pethInstance
          .connect(owner)
          ['provideYieldPETH(uint256,uint256,uint256)'](
            unstakeAmount,
            minETH,
            poolInfoIndex,
          );

        const newJPEG = await jpeg['balanceOf(address)'](pethInstance.address);

        await hre.network.provider.send('evm_revert', [revertId]);
        await pethInstance
          .connect(owner)
          .setAcquisitionFee(BigNumber.from('500'));
        const pendingJPEG = await lpFarm['pendingReward(uint256,address)'](
          poolInfoIndex,
          pethInstance.address,
        );

        expect(newJPEG.sub(oldJPEG)).to.eq(pendingJPEG);
      });

      it('returns the amount of ETH provided', async () => {
        await pethInstance.connect(owner).setMaxSupply(BigNumber.from('200'));
        await pethInstance
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

        const unstakeAmount = ethers.utils.parseEther('5');
        const minETH = ethers.utils.parseEther('4.5');
        const poolInfoIndex = ethers.constants.Two;

        const pethCitadel = IVault__factory.connect(PETH_CITADEL, owner);
        const curveLP = BigNumber.from(await pethCitadel['exchangeRate()']())
          .mul(unstakeAmount)
          .div(ethers.utils.parseEther('1'));

        const providedETH = await curvePETHPool.callStatic[
          'calc_withdraw_one_coin(uint256,int128)'
        ](curveLP, ethers.constants.Zero);

        const oldETH = await ethers.provider.getBalance(pethInstance.address);

        await pethInstance
          .connect(owner)
          ['provideYieldPETH(uint256,uint256,uint256)'](
            unstakeAmount,
            minETH,
            poolInfoIndex,
          );

        const newETH = await ethers.provider.getBalance(pethInstance.address);

        expect(providedETH).to.eq(newETH.sub(oldETH));
      });

      it('increases cumulativeJPEGPerShard', async () => {
        await pethInstance.connect(owner).setMaxSupply(BigNumber.from('200'));
        await pethInstance
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

        const oldJPEG = await jpeg['balanceOf(address)'](pethInstance.address);
        const oldJPS = await pethInstance['cumulativeJPEGPerShard()']();
        const totalSupply = await pethInstance.callStatic['totalSupply()']();
        await pethInstance
          .connect(owner)
          ['provideYieldPETH(uint256,uint256,uint256)'](
            unstakeAmount,
            minETH,
            poolInfoIndex,
          );

        const newJPEG = await jpeg['balanceOf(address)'](pethInstance.address);
        const newJPS = await pethInstance['cumulativeJPEGPerShard()']();
        expect(newJPEG.sub(oldJPEG).div(totalSupply)).to.eq(newJPS.sub(oldJPS));
      });

      it('increases cumulativeETHPerShard', async () => {
        await pethInstance.connect(owner).setMaxSupply(BigNumber.from('200'));
        await pethInstance
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

        const unstakeAmount = ethers.utils.parseEther('5');
        const minETH = ethers.utils.parseEther('4.5');
        const poolInfoIndex = ethers.constants.Two;

        const oldETH = await ethers.provider.getBalance(pethInstance.address);
        const oldEPS = await pethInstance.callStatic[
          'cumulativeETHPerShard()'
        ]();
        const totalSupply = await pethInstance.callStatic['totalSupply()']();
        await pethInstance
          .connect(owner)
          ['provideYieldPETH(uint256,uint256,uint256)'](
            unstakeAmount,
            minETH,
            poolInfoIndex,
          );

        const newETH = await ethers.provider.getBalance(pethInstance.address);
        const newEPS = await pethInstance.callStatic[
          'cumulativeETHPerShard()'
        ]();

        expect(newETH.sub(oldETH).div(totalSupply)).to.eq(newEPS.sub(oldEPS));
      });

      it('sets isYieldClaiming to true', async () => {
        await pethInstance.connect(owner).setMaxSupply(BigNumber.from('200'));
        await pethInstance
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

        expect(await pethInstance.callStatic['isYieldClaiming()']()).to.eq(
          true,
        );
      });

      describe('reverts if', () => {
        it('called by non-owner', async () => {
          await expect(
            pethInstance
              .connect(nonOwner)
              ['provideYieldPETH(uint256,uint256,uint256)'](
                ethers.constants.One,
                ethers.constants.One,
                ethers.constants.One,
              ),
          ).to.be.revertedWithCustomError(
            pethInstance,
            'ShardVault__NotProtocolOwner',
          );
        });
      });
    });

    describe('#withdrawFees()', () => {
      it('transfers accrued JPEG fees to treasury', async () => {
        await pethInstance.connect(owner).setMaxSupply(BigNumber.from('200'));
        await pethInstance
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

        const jpegFees = await pethInstance['accruedJPEG()']();

        await expect(() =>
          pethInstance.connect(owner)['withdrawFees()'](),
        ).to.changeTokenBalances(
          jpeg,
          [pethInstance, owner],
          [jpegFees.mul(ethers.constants.NegativeOne), jpegFees],
        );
      });
      it('transfers accrued ETH fees to treasury', async () => {
        await pethInstance.connect(owner).setMaxSupply(BigNumber.from('200'));
        await pethInstance
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

        const ethFees = await pethInstance['accruedFees()']();

        await expect(() =>
          pethInstance.connect(owner)['withdrawFees()'](),
        ).to.changeEtherBalances(
          [pethInstance, owner],
          [ethFees.mul(ethers.constants.NegativeOne), ethFees],
        );
      });
      it('sets accrued JPEG fees to zero', async () => {
        await pethInstance.connect(owner).setMaxSupply(BigNumber.from('200'));
        await pethInstance
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

        await pethInstance.connect(owner)['withdrawFees()']();

        expect(await pethInstance['accruedJPEG()']()).to.eq(
          ethers.constants.Zero,
        );
      });
      it('sets accrued ETH fees to zero', async () => {
        await pethInstance.connect(owner).setMaxSupply(BigNumber.from('200'));
        await pethInstance
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

        await pethInstance.connect(owner)['withdrawFees()']();

        expect(await pethInstance['accruedFees()']()).to.eq(
          ethers.constants.Zero,
        );
      });
      describe('reverts if', () => {
        it('called by non-owner', async () => {
          await expect(
            pethInstance.connect(nonOwner)['withdrawFees()'](),
          ).to.be.revertedWithCustomError(
            pethInstance,
            'ShardVault__NotProtocolOwner',
          );
        });
      });
    });

    describe('#listPunk((bytes,uint256,address)[])', () => {
      it('lists a punk on cryptoPunkMarket', async () => {
        await pethInstance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await pethInstance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        await pethInstance
          .connect(owner)
          ['purchasePunk((bytes,uint256,address)[],uint256)'](
            punkPurchaseCallsPETH,
            punkId,
          );

        expect(
          await cryptoPunkMarket['punkIndexToAddress(uint256)'](punkId),
        ).to.eq(pethInstance.address);

        const listPrice = ethers.utils.parseEther('100');
        const listPunkCalls = [];

        const encodedOfferPunkForSale =
          cryptoPunkMarket.interface.encodeFunctionData(
            'offerPunkForSale(uint256,uint256)',
            [punkId, listPrice],
          );

        const encodedListCall = {
          data: encodedOfferPunkForSale,
          target: CRYPTO_PUNKS_MARKET,
          value: ethers.constants.Zero,
        };

        listPunkCalls.push(encodedListCall);

        await pethInstance
          .connect(owner)
          ['listPunk((bytes,uint256,address)[],uint256)'](
            listPunkCalls,
            punkId,
          );

        expect(
          (await cryptoPunkMarket['punksOfferedForSale(uint256)'](punkId))
            .minValue,
        ).to.eq(listPrice);
      });
      describe('reverts if', () => {
        it('called by non-owner', async () => {
          await expect(
            pethInstance
              .connect(nonOwner)
              ['listPunk((bytes,uint256,address)[],uint256)'](
                [
                  {
                    data: '0x',
                    target: ethers.constants.AddressZero,
                    value: ethers.constants.Zero,
                  },
                ],
                ethers.constants.Zero,
              ),
          ).to.be.revertedWithCustomError(
            pethInstance,
            'ShardVault__NotProtocolOwner',
          );
        });
      });
    });

    describe('makeUnusedETHClaimable()', () => {
      it('increases cumulative ETH per shard', async () => {
        await pethInstance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await pethInstance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        const punkPrice = (
          await cryptoPunkMarket['punksOfferedForSale(uint256)'](punkId)
        ).minValue;

        await pethInstance
          .connect(owner)
          ['purchasePunk((bytes,uint256,address)[],uint256)'](
            punkPurchaseCallsPETH,
            punkId,
          );

        await pethInstance.connect(owner).makeUnusedETHClaimable();

        const acquisitionFee = punkPrice
          .mul(await pethInstance.acquisitionFeeBP())
          .div(BASIS_POINTS);
        const expectedCumulativeETHPerShard = ethers.utils
          .parseEther('100')
          .sub(punkPrice)
          .sub(acquisitionFee)
          .div(await pethInstance['totalSupply()']());

        expect(await pethInstance['cumulativeETHPerShard()']()).to.eq(
          expectedCumulativeETHPerShard,
        );
      });
      describe('reverts if', () => {
        it('called by non-owner', async () => {
          await expect(
            pethInstance.connect(nonOwner)['makeUnusedETHClaimable()'](),
          ).to.be.revertedWithCustomError(
            pethInstance,
            'ShardVault__NotProtocolOwner',
          );
        });
      });
    });

    describe('#setAcquisitionFee(uint16)', () => {
      it('sets acquisition fee value', async () => {
        const feeValue = BigNumber.from('1234');

        await instance.connect(owner)['setAcquisitionFee(uint16)'](feeValue);

        expect(await instance['acquisitionFeeBP()']()).to.eq(feeValue);
      });

      describe('reverts if', () => {
        it('called by non-owner', async () => {
          await expect(
            instance
              .connect(nonOwner)
              ['setAcquisitionFee(uint16)'](ethers.constants.Two),
          ).to.be.revertedWithCustomError(
            instance,
            'ShardVault__NotProtocolOwner',
          );
        });
        it('value exceeds BASIS_POINTS', async () => {
          await expect(
            instance
              .connect(owner)
              ['setAcquisitionFee(uint16)'](BigNumber.from('10001')),
          ).to.be.revertedWithCustomError(
            instance,
            'ShardVault__BasisExceeded',
          );
        });
      });
    });

    describe('#setSaleFee(uint16)', () => {
      it('sets sale fee value', async () => {
        const feeValue = BigNumber.from('1234');

        await instance.connect(owner)['setSaleFee(uint16)'](feeValue);

        expect(await instance['saleFeeBP()']()).to.eq(feeValue);
      });

      describe('reverts if', () => {
        it('called by non-owner', async () => {
          await expect(
            instance
              .connect(nonOwner)
              ['setSaleFee(uint16)'](ethers.constants.Two),
          ).to.be.revertedWithCustomError(
            instance,
            'ShardVault__NotProtocolOwner',
          );
        });
        it('value exceeds BASIS_POINTS', async () => {
          await expect(
            instance
              .connect(owner)
              ['setSaleFee(uint16)'](BigNumber.from('10001')),
          ).to.be.revertedWithCustomError(
            instance,
            'ShardVault__BasisExceeded',
          );
        });
      });
    });

    describe('#setYieldFee(uint16)', () => {
      it('sets yield fee value', async () => {
        const feeValue = BigNumber.from('1234');

        await instance.connect(owner)['setYieldFee(uint16)'](feeValue);

        expect(await instance['yieldFeeBP()']()).to.eq(feeValue);
      });
      describe('reverts if', () => {
        it('called by non-owner', async () => {
          await expect(
            instance
              .connect(nonOwner)
              ['setYieldFee(uint16)'](ethers.constants.Two),
          ).to.be.revertedWithCustomError(
            instance,
            'ShardVault__NotProtocolOwner',
          );
        });
        it('value exceeds BASIS_POINTS', async () => {
          await expect(
            instance
              .connect(owner)
              ['setYieldFee(uint16)'](BigNumber.from('10001')),
          ).to.be.revertedWithCustomError(
            instance,
            'ShardVault__BasisExceeded',
          );
        });
      });
    });

    describe('#setMaxSupply(uint256)', () => {
      it('sets maxSupply value', async () => {
        const newValue = BigNumber.from('1234');

        await instance.connect(owner)['setMaxSupply(uint256)'](newValue);

        expect(await instance['maxSupply()']()).to.eq(newValue);
      });
      describe('reverts if', () => {
        it('called by non-owner', async () => {
          await expect(
            instance
              .connect(nonOwner)
              ['setMaxSupply(uint256)'](ethers.constants.Two),
          ).to.be.revertedWithCustomError(
            instance,
            'ShardVault__NotProtocolOwner',
          );
        });
      });
    });

    describe('#setWhitelistEndsAt(uint64)', () => {
      it('sets whitelistEndsAt value', async () => {
        const whitelistEndsAt = BigNumber.from('123123123123');

        await instance
          .connect(owner)
          ['setWhitelistEndsAt(uint48)'](whitelistEndsAt);

        expect(whitelistEndsAt).to.eq(await instance['whitelistEndsAt()']());
      });

      describe('reverts if', () => {
        it('called by non-owner', async () => {
          await expect(
            instance
              .connect(nonOwner)
              ['setWhitelistEndsAt(uint48)'](BigNumber.from('1000')),
          ).to.be.revertedWithCustomError(
            instance,
            'ShardVault__NotProtocolOwner',
          );
        });
      });
    });

    describe('#setReservedShards(uint256)', () => {
      it('sets reservedShards value', async () => {
        const reservedShards = BigNumber.from('123');

        await instance
          .connect(owner)
          ['setReservedShards(uint256)'](reservedShards);

        expect(reservedShards).to.eq(await instance['reservedShards()']());
      });

      describe('reverts if', () => {
        it('called by non-owner', async () => {
          await expect(
            instance
              .connect(nonOwner)
              ['setReservedShards(uint256)'](BigNumber.from('1000')),
          ).to.be.revertedWithCustomError(
            instance,
            'ShardVault__NotProtocolOwner',
          );
        });
      });
    });

    describe('#stakeCard(uint256)', () => {
      it('stakes a jpeg cig card', async () => {
        await jpegCards
          .connect(cardOwner)
          ['transferFrom(address,address,uint256)'](
            cardOwner.address,
            instance.address,
            cardID,
          );

        await instance.connect(owner)['stakeCard(uint256)'](cardID);

        expect(
          await jpegCardsCigStaking['isUserStaking(address)'](instance.address),
        ).to.be.true;
      });
      describe('reverts if', () => {
        it('called by non-owner', async () => {
          await expect(
            instance
              .connect(nonOwner)
              ['stakeCard(uint256)'](ethers.constants.One),
          ).to.be.revertedWithCustomError(
            instance,
            'ShardVault__NotProtocolOwner',
          );
        });
      });
    });

    describe('#unstakeCard(uint256)', () => {
      it('unstakes a jpeg cig card', async () => {
        await jpegCards
          .connect(cardOwner)
          ['transferFrom(address,address,uint256)'](
            cardOwner.address,
            instance.address,
            cardID,
          );

        await instance.connect(owner)['stakeCard(uint256)'](cardID);

        expect(
          await jpegCardsCigStaking['isUserStaking(address)'](instance.address),
        ).to.be.true;

        await instance.connect(owner)['unstakeCard(uint256)'](cardID);
        expect(
          await jpegCardsCigStaking['isUserStaking(address)'](instance.address),
        ).to.be.false;
      });
      describe('reverts if', () => {
        it('called by non-owner', async () => {
          await expect(
            instance
              .connect(nonOwner)
              ['unstakeCard(uint256)'](ethers.constants.One),
          ).to.be.revertedWithCustomError(
            instance,
            'ShardVault__NotProtocolOwner',
          );
        });
      });
    });

    describe('#transferCard(uint256,address)', () => {
      it('transfers a card to a given address', async () => {
        await jpegCards
          .connect(cardOwner)
          ['transferFrom(address,address,uint256)'](
            cardOwner.address,
            instance.address,
            cardID,
          );

        expect(await jpegCards['ownerOf(uint256)'](cardID)).to.eq(
          instance.address,
        );

        await instance
          .connect(owner)
          ['transferCard(uint256,address)'](cardID, cardOwner.address);
        expect(await jpegCards['ownerOf(uint256)'](cardID)).to.eq(
          cardOwner.address,
        );
      });

      describe('reverts if', () => {
        it('called by non-owner', async () => {
          await expect(
            instance
              .connect(nonOwner)
              ['transferCard(uint256,address)'](
                ethers.constants.One,
                ethers.constants.AddressZero,
              ),
          ).to.be.revertedWithCustomError(
            instance,
            'ShardVault__NotProtocolOwner',
          );
        });
      });
    });
  });
}
