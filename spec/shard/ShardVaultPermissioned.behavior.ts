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

export interface ShardVaultPermissionedBehaviorArgs {
  getProtocolOwner: () => Promise<SignerWithAddress>;
}

export function describeBehaviorOfShardVaultPermissioned(
  deploy: () => Promise<IShardVault>,
  secondDeploy: () => Promise<IShardVault>,
  args: ShardVaultPermissionedBehaviorArgs,
  skips?: string[],
) {
  describe('::ShardVaultPermissioned', () => {
    let depositor: SignerWithAddress;
    let owner: SignerWithAddress;
    let nonOwner: SignerWithAddress;
    let instance: IShardVault;
    let secondInstance: IShardVault;
    let cryptoPunkMarket: ICryptoPunkMarket;
    let purchaseData: string;
    let pUSD: IERC20;
    let jpegdVault: INFTVault;

    const punkId = BigNumber.from('2534');
    const CRYPTO_PUNKS_MARKET = '0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB';
    const PUSD = '0x466a756E9A7401B5e2444a3fCB3c2C12FBEa0a54';
    const JPEGD_VAULT = '0xD636a2fC1C18A54dB4442c3249D5e620cf8fE98F';
    const curvePUSDPoolAddress = '0x8EE017541375F6Bcd802ba119bdDC94dad6911A1';
    const targetLTVBP = BigNumber.from('2800');
    const BASIS_POINTS = BigNumber.from('10000');

    before(async () => {
      cryptoPunkMarket = await ethers.getContractAt(
        'ICryptoPunkMarket',
        CRYPTO_PUNKS_MARKET,
      );

      purchaseData = cryptoPunkMarket.interface.encodeFunctionData('buyPunk', [
        punkId,
      ]);

      pUSD = <IERC20>(
        await ethers.getContractAt(
          '@solidstate/contracts/token/ERC20/IERC20.sol:IERC20',
          PUSD,
        )
      );

      jpegdVault = await ethers.getContractAt('INFTVault', JPEGD_VAULT);
    });

    beforeEach(async () => {
      instance = await deploy();
      secondInstance = await secondDeploy();
      [depositor, nonOwner] = await ethers.getSigners();
      owner = await args.getProtocolOwner();
    });

    describe('#purchasePunk(uint256)', () => {
      it('purchases punk from CryptoPunkMarket', async () => {
        await instance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await instance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        await instance
          .connect(owner)
          ['purchasePunk(bytes,uint256)'](purchaseData, punkId);

        expect(
          await cryptoPunkMarket['punkIndexToAddress(uint256)'](punkId),
        ).to.eq(instance.address);
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
            ['purchasePunk(bytes,uint256)'](purchaseData, punkId),
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
          ['purchasePunk(bytes,uint256)'](purchaseData, punkId);

        expect(await instance.invested()).to.be.true;
      });

      it('adds punkId to `ownedTokenIds`', async () => {
        await instance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await instance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        await instance
          .connect(owner)
          ['purchasePunk(bytes,uint256)'](purchaseData, punkId);

        const [id] = await instance['ownedTokenIds()']();
        expect(id).to.eq(punkId);
      });

      describe('reverts if', () => {
        it('called by non-owner', async () => {
          await expect(
            instance
              .connect(nonOwner)
              ['purchasePunk(bytes,uint256)'](purchaseData, punkId),
          ).to.be.revertedWith('ShardVault__NotProtocolOwner()');
        });
        it('collection is not punks', async () => {
          await expect(
            secondInstance
              .connect(owner)
              ['purchasePunk(bytes,uint256)'](purchaseData, punkId),
          ).to.be.revertedWith('ShardVault__CollectionNotPunks()');
        });
      });
    });

    describe('#collateralizePunk(uint256,uint256,bool)', () => {
      it('borrows requested amount of pUSD', async () => {
        await instance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await instance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        await instance
          .connect(owner)
          ['purchasePunk(bytes,uint256)'](purchaseData, punkId);

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
            .collateralizePunk(punkId, requestedBorrow, false),
        ).to.changeTokenBalance(pUSD, instance, actualBorrow);
      });

      it('borrows multiple times until target LTV is reached', async () => {
        await instance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await instance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        await instance
          .connect(owner)
          ['purchasePunk(bytes,uint256)'](purchaseData, punkId);

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
            .collateralizePunk(punkId, requestedBorrow, false),
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
          .collateralizePunk(punkId, requestedBorrow, false);

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
            ['purchasePunk(bytes,uint256)'](purchaseData, punkId);

          let requestedBorrow = (
            await jpegdVault.callStatic['getNFTValueUSD(uint256)'](punkId)
          )
            .mul(BigNumber.from('2000'))
            .div(BASIS_POINTS);

          await instance
            .connect(owner)
            .collateralizePunk(
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
              .collateralizePunk(punkId, requestedBorrow, false),
          ).to.be.revertedWith('ShardVault__TargetLTVReached()');
        });

        it('called by non-owner', async () => {
          await expect(
            instance
              .connect(nonOwner)
              .collateralizePunk(punkId, ethers.constants.One, false),
          ).to.be.revertedWith('ShardVault__NotProtocolOwner()');
        });
      });
    });

    describe('#stake(uint256,uint256,uint256)', () => {
      it('completes three stages of staking and receives LP_FARM shares', async () => {
        await instance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await instance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        await instance
          .connect(owner)
          ['purchasePunk(bytes,uint256)'](purchaseData, punkId);

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
          .collateralizePunk(punkId, requestedBorrow, false);

        const curvePUSDPool = <ICurveMetaPool>(
          await ethers.getContractAt('ICurveMetaPool', curvePUSDPoolAddress)
        );

        const minCurveLP = await curvePUSDPool.callStatic[
          'calc_token_amount(uint256[2],bool)'
        ]([actualBorrow, 0], true);

        await instance.connect(owner)['stake(uint256,uint256,uint256)'](
          actualBorrow,
          minCurveLP.mul(9996).div(10000), //curve fee is 0.04% (unsure)
          ethers.constants.One,
        );
      });
      describe('reverts if', () => {
        it('called by non-owner', async () => {
          await expect(
            instance
              .connect(nonOwner)
              ['stake(uint256,uint256,uint256)'](
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
