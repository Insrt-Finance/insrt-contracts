import hre, { ethers } from 'hardhat';
import {
  ICryptoPunkMarket,
  ICurveMetaPool,
  IMarketPlaceHelper,
  INFTVault,
  IShardVault,
  ShardCollection,
  ShardCollection__factory,
} from '../../typechain-types';

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { BigNumber } from 'ethers';
import { expect } from 'chai';

export interface ShardVaultViewBehaviorArgs {
  getProtocolOwner: () => Promise<SignerWithAddress>;
}

export function formatTokenId(
  internalId: BigNumber,
  address: string,
): BigNumber {
  let tokenId: BigNumber;
  tokenId = BigNumber.from(address).shl(96).add(internalId);
  return tokenId;
}

export function describeBehaviorOfShardVaultView(
  deploy: () => Promise<IShardVault>,
  pethDeploy: () => Promise<IShardVault>,
  args: ShardVaultViewBehaviorArgs,
  skips?: string[],
) {
  let depositor: SignerWithAddress;
  let owner: SignerWithAddress;
  let instance: IShardVault;
  let pethInstance: IShardVault;
  let shardCollection: ShardCollection;
  let cryptoPunkMarket: ICryptoPunkMarket;
  let purchaseData: string;
  let pethJpegdVault: INFTVault;
  let jpegdVault: INFTVault;

  const punkId = BigNumber.from('2534');
  const CRYPTO_PUNKS_MARKET = '0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB';
  const PETH_JPEGD_VAULT = '0x4e5F305bFCa77b17f804635A9bA669e187d51719';
  const JPEGD_VAULT = '0xD636a2fC1C18A54dB4442c3249D5e620cf8fE98F';
  const curvePUSDPoolAddress = '0x8EE017541375F6Bcd802ba119bdDC94dad6911A1';
  const curvePETHPoolAddress = '0x9848482da3Ee3076165ce6497eDA906E66bB85C5';
  const targetLTVBP = BigNumber.from('2800');
  const BASIS_POINTS = BigNumber.from('10000');
  const punkPurchaseCallsPETH: IMarketPlaceHelper.EncodedCallStruct[] = [];
  const punkPurchaseCallsPUSD: IMarketPlaceHelper.EncodedCallStruct[] = [];

  before(async () => {
    [depositor] = await ethers.getSigners();
    owner = await args.getProtocolOwner();

    cryptoPunkMarket = await ethers.getContractAt(
      'ICryptoPunkMarket',
      CRYPTO_PUNKS_MARKET,
    );

    jpegdVault = await ethers.getContractAt('INFTVault', JPEGD_VAULT);

    pethJpegdVault = await ethers.getContractAt('INFTVault', PETH_JPEGD_VAULT);
  });

  beforeEach(async () => {
    instance = await deploy();
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
  });

  describe('#totalSupply()', () => {
    it('TODO');
  });

  describe('#maxSupply()', () => {
    it('TODO');
  });

  describe('#shardCollection()', () => {
    it('TODO');
  });

  describe('#count()', () => {
    it('TODO');
  });

  describe('#formatTokenId(uint96)', () => {
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
      const initialId = await instance['formatTokenId(uint96)'](
        ethers.constants.One,
      );
      const finalId = await instance['formatTokenId(uint96)'](
        BigNumber.from('101'),
      );

      expect(finalId.sub(initialId)).to.eq(BigNumber.from('100'));
    });
  });
  describe('#parseTokenId(uint256)', () => {
    it('returns the seeded vault address', async () => {
      const tokenId = await instance['formatTokenId(uint96)'](
        ethers.constants.One,
      );
      const [address] = await instance['parseTokenId(uint256)'](tokenId);

      expect(address).to.eq(instance.address);
    });

    it('returns the internal id used to generate the tokenId', async () => {
      const maxUint96 = ethers.constants.Two.pow(BigNumber.from('96')).sub(
        ethers.constants.One,
      );
      const tokenId = await instance['formatTokenId(uint96)'](maxUint96);
      const [, internalId] = await instance['parseTokenId(uint256)'](tokenId);

      expect(internalId).to.eq(maxUint96);
    });
  });
  describe('#queryAutoCompForPETH(uint256)', () => {
    it('returns autocomp amount resulting in at least amount of PETH requested after unstaking', async () => {
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

      const pETHAmounts = [
        ethers.utils.parseEther('0.01'),
        ethers.utils.parseEther('0.1'),
        ethers.utils.parseEther('1'),
        ethers.utils.parseEther('10'),
      ];

      for (let i = 0; i < pETHAmounts.length; i++) {
        const autoComp = await pethInstance['queryAutoCompForPETH(uint256)'](
          pETHAmounts[i],
        );
        const pETH = await pethInstance
          .connect(owner)
          .callStatic['unstakePETH(uint256,uint256,uint256)'](autoComp, 0, 2);

        expect(pETH).to.gte(pETHAmounts[i]);
      }
    });
    it('returns autocomp amount resulting in at most 1/1000000000 surplus of PETH requested after unstaking', async () => {
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

      const pETHAmounts = [
        ethers.utils.parseEther('0.01'),
        ethers.utils.parseEther('0.1'),
        ethers.utils.parseEther('1'),
        ethers.utils.parseEther('10'),
      ];

      for (let i = 0; i < pETHAmounts.length; i++) {
        const autoComp = await pethInstance['queryAutoCompForPETH(uint256)'](
          pETHAmounts[i],
        );
        const pETH = await pethInstance
          .connect(owner)
          .callStatic['unstakePETH(uint256,uint256,uint256)'](autoComp, 0, 2);

        expect(pETH.sub(pETHAmounts[i])).to.gte(ethers.constants.Zero);
        expect(pETHAmounts[i].sub(pETH)).to.lte(
          pETHAmounts[i].div(BigNumber.from('1000000000')),
        );
      }
    });
  });
  describe('#queryAutoCompforPUSD(uint256)', async () => {
    it('returns autoComp amount resulting in at least amount of PUSD requested after unstaking', async () => {
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

      const pUSDAmounts = [
        ethers.utils.parseEther('1'),
        ethers.utils.parseEther('10'),
        ethers.utils.parseEther('100'),
        ethers.utils.parseEther('1000'),
        ethers.utils.parseEther('10000'),
      ];

      for (let i = 0; i < pUSDAmounts.length; i++) {
        const autoComp = await instance.queryAutoCompForPUSD(pUSDAmounts[i]);
        const pUSD = await instance
          .connect(owner)
          .callStatic['unstakePUSD(uint256,uint256,uint256)'](autoComp, 0, 1);

        expect(pUSD).to.gte(pUSDAmounts[i]);
      }
    });
    it('returns amout resulting in at most 1/1000000 surplus of PUSD requested after unstaking', async () => {
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

      const pUSDAmounts = [
        ethers.utils.parseEther('1'),
        ethers.utils.parseEther('10'),
        ethers.utils.parseEther('100'),
        ethers.utils.parseEther('1000'),
        ethers.utils.parseEther('10000'),
      ];

      for (let i = 0; i < pUSDAmounts.length; i++) {
        const autoComp = await instance.queryAutoCompForPUSD(pUSDAmounts[i]);
        const pUSD = await instance
          .connect(owner)
          .callStatic['unstakePUSD(uint256,uint256,uint256)'](autoComp, 0, 1);

        expect(pUSD.sub(pUSDAmounts[i])).to.gte(ethers.constants.Zero);
        expect(pUSD.sub(pUSDAmounts[i])).to.lte(
          pUSDAmounts[i].div(BigNumber.from('1000000')),
        );
      }
    });
  });
}
