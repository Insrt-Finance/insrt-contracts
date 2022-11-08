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
} from '../../typechain-types';
import { ILPFarming, IVault } from '../../typechain-types/contracts/jpegd';

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
    let instance: IShardVault;
    let secondInstance: IShardVault;
    let pethInstance: IShardVault;
    let cryptoPunkMarket: ICryptoPunkMarket;
    let purchaseDataPUSD: string[];
    let purchaseDataPETH: string[];
    let targets: string[];
    let pUSD: IERC20;
    let pETH: IERC20;
    let jpegdVault: INFTVault;
    let pethJpegdVault: INFTVault;

    const punkId = BigNumber.from('2534');
    const CRYPTO_PUNKS_MARKET = '0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB';
    const PUSD = '0x466a756E9A7401B5e2444a3fCB3c2C12FBEa0a54';
    const PETH = '0x836A808d4828586A69364065A1e064609F5078c7';
    const JPEGD_VAULT = '0xD636a2fC1C18A54dB4442c3249D5e620cf8fE98F';
    const PETH_JPEGD_VAULT = '0x4e5F305bFCa77b17f804635A9bA669e187d51719';
    const PUSD_CITADEL = '0xF6Cbf5e56a8575797069c7A7FBED218aDF17e3b2';
    const PETH_CITADEL = '0x56D1b6Ac326e152C9fAad749F1F4f9737a049d46';
    const LP_FARM = '0xb271d2C9e693dde033d97f8A3C9911781329E4CA';
    const curvePUSDPoolAddress = '0x8EE017541375F6Bcd802ba119bdDC94dad6911A1';
    const curvePETHPoolAddress = '0x9848482da3Ee3076165ce6497eDA906E66bB85C5';
    const targetLTVBP = BigNumber.from('2800');
    const BASIS_POINTS = BigNumber.from('10000');

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

      jpegdVault = await ethers.getContractAt('INFTVault', JPEGD_VAULT);
      pethJpegdVault = await ethers.getContractAt(
        'INFTVault',
        PETH_JPEGD_VAULT,
      );
    });

    beforeEach(async () => {
      instance = await deploy();
      secondInstance = await secondDeploy();
      pethInstance = await pethDeploy();
      [depositor, nonOwner] = await ethers.getSigners();
      owner = await args.getProtocolOwner();

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

      purchaseDataPETH = [punkPurchaseData, transferDataPETHVault];
      purchaseDataPUSD = [punkPurchaseData, transferDataPUSDVault];
      targets = [CRYPTO_PUNKS_MARKET, CRYPTO_PUNKS_MARKET];
    });

    describe('#purchasePunk(uint256)', () => {
      it('purchases punk from CryptoPunkMarket', async () => {
        await instance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await instance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });
        const price = (
          await cryptoPunkMarket['punksOfferedForSale(uint256)'](punkId)
        ).minValue;

        await instance
          .connect(owner)
          ['purchasePunk(bytes[],address[],uint256[],uint256)'](
            purchaseDataPUSD,
            targets,
            [price, 0],
            punkId,
          );

        expect(
          await cryptoPunkMarket['punkIndexToAddress(uint256)'](punkId),
        ).to.eq(instance.address);
      });

      it('collects acquisition fee if first purchase', async () => {
        await instance.connect(owner).setMaxSupply(BigNumber.from('200'));
        await instance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('200') });

        const price = (
          await cryptoPunkMarket['punksOfferedForSale(uint256)'](punkId)
        ).minValue;

        await instance
          .connect(owner)
          ['purchasePunk(bytes[],address[],uint256[],uint256)'](
            purchaseDataPUSD,
            targets,
            [price, 0],
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

        const secondPurchaseData = [secondPunkPurchaseData, secondTransferData];

        const secondPrice = (
          await cryptoPunkMarket['punksOfferedForSale(uint256)'](secondPunkId)
        ).minValue;

        await instance
          .connect(owner)
          ['purchasePunk(bytes[],address[],uint256[],uint256)'](
            secondPurchaseData,
            targets,
            [secondPrice, 0],
            secondPunkId,
          );

        expect(await instance.callStatic.accruedFees()).to.eq(
          price
            .mul(await instance.callStatic.acquisitionFeeBP())
            .div(BASIS_POINTS),
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
            ['purchasePunk(bytes[],address[],uint256[],uint256)'](
              purchaseDataPUSD,
              targets,
              [price, 0],
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

        const price = (
          await cryptoPunkMarket['punksOfferedForSale(uint256)'](punkId)
        ).minValue;

        await instance
          .connect(owner)
          ['purchasePunk(bytes[],address[],uint256[],uint256)'](
            purchaseDataPUSD,
            targets,
            [price, 0],
            punkId,
          );
        expect(await instance.invested()).to.be.true;
      });

      it('adds punkId to `ownedTokenIds`', async () => {
        await instance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await instance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        const price = (
          await cryptoPunkMarket['punksOfferedForSale(uint256)'](punkId)
        ).minValue;

        await instance
          .connect(owner)
          ['purchasePunk(bytes[],address[],uint256[],uint256)'](
            purchaseDataPUSD,
            targets,
            [price, 0],
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
              ['purchasePunk(bytes[],address[],uint256[],uint256)'](
                purchaseDataPUSD,
                targets,
                [0, 0],
                punkId,
              ),
          ).to.be.revertedWith('ShardVault__NotProtocolOwner()');
        });
        it('collection is not punks', async () => {
          await expect(
            secondInstance
              .connect(owner)
              ['purchasePunk(bytes[],address[],uint256[],uint256)'](
                purchaseDataPUSD,
                targets,
                [0, 0],
                punkId,
              ),
          ).to.be.revertedWith('ShardVault__CollectionNotPunks()');
        });
      });
    });

    describe('#collateralizePunkPUSD(uint256,uint256,bool)', () => {
      it('borrows requested amount of pUSD', async () => {
        await instance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await instance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        const price = (
          await cryptoPunkMarket['punksOfferedForSale(uint256)'](punkId)
        ).minValue;

        await instance
          .connect(owner)
          ['purchasePunk(bytes[],address[],uint256[],uint256)'](
            purchaseDataPUSD,
            targets,
            [price, 0],
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

        const price = (
          await cryptoPunkMarket['punksOfferedForSale(uint256)'](punkId)
        ).minValue;

        await instance
          .connect(owner)
          ['purchasePunk(bytes[],address[],uint256[],uint256)'](
            purchaseDataPUSD,
            targets,
            [price, 0],
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

          const price = (
            await cryptoPunkMarket['punksOfferedForSale(uint256)'](punkId)
          ).minValue;

          await instance
            .connect(owner)
            ['purchasePunk(bytes[],address[],uint256[],uint256)'](
              purchaseDataPUSD,
              targets,
              [price, 0],
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
          ).to.be.revertedWith('ShardVault__TargetLTVReached()');
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
          ).to.be.revertedWith('ShardVault__NotProtocolOwner()');
        });
      });
    });

    describe('#collateralizePunkPETH(uint256,uint256,bool)', () => {
      it('borrows requested amount of pETH', async () => {
        await pethInstance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await pethInstance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        const price = (
          await cryptoPunkMarket['punksOfferedForSale(uint256)'](punkId)
        ).minValue;

        await pethInstance
          .connect(owner)
          ['purchasePunk(bytes[],address[],uint256[],uint256)'](
            purchaseDataPETH,
            targets,
            [price, 0],
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

        const price = (
          await cryptoPunkMarket['punksOfferedForSale(uint256)'](punkId)
        ).minValue;

        await pethInstance
          .connect(owner)
          ['purchasePunk(bytes[],address[],uint256[],uint256)'](
            purchaseDataPETH,
            targets,
            [price, 0],
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

          const price = (
            await cryptoPunkMarket['punksOfferedForSale(uint256)'](punkId)
          ).minValue;

          await pethInstance
            .connect(owner)
            ['purchasePunk(bytes[],address[],uint256[],uint256)'](
              purchaseDataPETH,
              targets,
              [price, 0],
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
          ).to.be.revertedWith('ShardVault__TargetLTVReached()');
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
          ).to.be.revertedWith('ShardVault__NotProtocolOwner()');
        });
      });
    });

    describe('#stakePUSD(uint256,uint256,uint256)', () => {
      it('completes three stages of staking', async () => {
        await instance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await instance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        const price = (
          await cryptoPunkMarket['punksOfferedForSale(uint256)'](punkId)
        ).minValue;

        await instance
          .connect(owner)
          ['purchasePunk(bytes[],address[],uint256[],uint256)'](
            purchaseDataPUSD,
            targets,
            [price, 0],
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
        it('called by non-owner', async () => {
          await expect(
            instance
              .connect(nonOwner)
              ['stakePUSD(uint256,uint256,uint256)'](
                ethers.constants.One,
                ethers.constants.One,
                ethers.constants.One,
              ),
          ).to.be.revertedWith('ShardVault__NotProtocolOwner()');
        });
      });
    });

    describe('#stakePETH(uint256,uint256,uint256)', () => {
      it('completes three stages of staking', async () => {
        await pethInstance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await pethInstance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        const price = (
          await cryptoPunkMarket['punksOfferedForSale(uint256)'](punkId)
        ).minValue;

        await pethInstance
          .connect(owner)
          ['purchasePunk(bytes[],address[],uint256[],uint256)'](
            purchaseDataPETH,
            targets,
            [price, 0],
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
        it('called by non-owner', async () => {
          await expect(
            pethInstance
              .connect(nonOwner)
              ['stakePETH(uint256,uint256,uint256)'](
                ethers.constants.One,
                ethers.constants.One,
                ethers.constants.One,
              ),
          ).to.be.revertedWith('ShardVault__NotProtocolOwner()');
        });
      });
    });
  });
}
