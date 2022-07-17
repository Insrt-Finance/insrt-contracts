import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import hre from 'hardhat';
import { BigNumber } from 'ethers';
import { ethers } from 'hardhat';
import {
  IERC20__factory,
  IIndex,
  IInvestmentPool__factory,
} from '../../typechain-types';
import { expect } from 'chai';

export interface IndexSettingsBehaviorArgs {
  getProtocolOwner: () => Promise<SignerWithAddress>;
  tokens: string[];
  weights: BigNumber[];
}

export function describeBehaviorOfIndexSettings(
  deploy: () => Promise<IIndex>,
  args: IndexSettingsBehaviorArgs,
  skips?: string[],
) {
  let protocolOwner: SignerWithAddress;
  let nonOwner: SignerWithAddress;
  let instance: IIndex;

  beforeEach(async () => {
    instance = await deploy();
    [nonOwner] = await ethers.getSigners();
    protocolOwner = await args.getProtocolOwner();
  });

  describe('#updateWeights(uint256[],uint256)', () => {
    it('sets the weights to the updated values', async () => {
      const newWeights = [
        ethers.utils.parseEther('0.4'),
        ethers.utils.parseEther('0.6'),
      ];
      const endTime = BigNumber.from('86460'); //1 day + 1 minute in seconds
      const { timestamp } = await ethers.provider.getBlock('latest');

      const investmentPool = IInvestmentPool__factory.connect(
        await instance.asset(),
        protocolOwner,
      );

      await instance
        .connect(protocolOwner)
        .updateWeights(
          newWeights,
          BigNumber.from(timestamp.toString()).add(endTime),
        );

      await hre.network.provider.send('evm_setNextBlockTimestamp', [
        BigNumber.from(timestamp.toString())
          .add(endTime.div(ethers.constants.Two))
          .toNumber(),
      ]);
      await hre.network.provider.send('evm_mine');

      let currentWeights: BigNumber[] =
        await investmentPool.getNormalizedWeights();
      for (let i = 0; i < args.weights.length; i++) {
        expect(args.weights[i]).to.not.eq(currentWeights[i]);
      }

      await hre.network.provider.send('evm_setNextBlockTimestamp', [
        BigNumber.from(timestamp.toString()).add(endTime).toNumber(),
      ]);
      await hre.network.provider.send('evm_mine');

      currentWeights = await investmentPool.getNormalizedWeights();

      for (let i = 0; i < args.weights.length; i++) {
        expect(newWeights[i]).to.eq(currentWeights[i]);
      }
    });

    describe('reverts if', () => {
      it('caller is not protocol owner', async () => {
        const newWeights = [
          ethers.utils.parseEther('0.4'),
          ethers.utils.parseEther('0.6'),
        ];
        const endTime = BigNumber.from('86460'); //1 day + 1 minute in seconds
        await expect(
          instance.connect(nonOwner).updateWeights(newWeights, endTime),
        ).to.be.revertedWith('Not protocol owner');
      });
    });
  });

  describe('#setSwapEnabled(bool)', () => {
    it('pauses swaps', async () => {
      await instance.connect(protocolOwner).setSwapEnabled(false);

      const investmentPool = IInvestmentPool__factory.connect(
        await instance.asset(),
        protocolOwner,
      );

      expect(await investmentPool.getSwapEnabled()).to.eq(false);
    });

    it('allows proportional exits whilst swaps are paused', async () => {
      await instance.connect(protocolOwner).setSwapEnabled(false);
      const minPoolTokenAmounts = [
        ethers.constants.Zero,
        ethers.constants.Zero,
      ];
      const shareAmount = ethers.constants.One;
      await expect(
        instance
          .connect(protocolOwner)
          ['redeem(uint256,uint256[],address)'](
            shareAmount,
            minPoolTokenAmounts,
            protocolOwner.address,
          ),
      ).to.not.be.reverted;
    });

    it('forbids non-proportional exits', async () => {
      await instance.connect(protocolOwner).setSwapEnabled(false);
      const minPoolTokenAmounts = [
        ethers.constants.Zero,
        ethers.constants.Zero,
      ];
      const shareAmount = ethers.constants.One;
      const tokenIndex = ethers.constants.Zero;
      await expect(
        instance
          .connect(protocolOwner)
          ['redeem(uint256,uint256[],uint256,address)'](
            shareAmount,
            minPoolTokenAmounts,
            tokenIndex,
            protocolOwner.address,
          ),
      ).to.be.revertedWith('BAL#330'); //refers to balancer error: INVALID_JOIN_EXIT_KIND_WHILE_SWAPS_DISABLED
    });

    describe('reverts if', () => {
      it('caller is not protocol owner', async () => {
        await expect(
          instance.connect(nonOwner).setSwapEnabled(false),
        ).to.be.revertedWith('Not protocol owner');
      });
    });
  });

  describe('#withdrawAllLiquidity()', () => {
    it('withdraws all BPT and assets in Insrt-Index and sends them to protocol owner', async () => {
      //pool initialized, so BPT already in Index => can avoid deposit
      const bpt = IERC20__factory.connect(
        await instance.asset(),
        protocolOwner,
      );
      const indexBPT = await bpt.balanceOf(instance.address);
      await expect(() =>
        instance.connect(protocolOwner).withdrawAllLiquidity(),
      ).changeTokenBalance(bpt, protocolOwner, indexBPT);
    });

    describe('reverts if', () => {
      it('caller is not protocol owner', async () => {
        await expect(
          instance.connect(nonOwner)['withdrawAllLiquidity()'](),
        ).to.be.revertedWith('Not protocol owner');
      });
    });
  });
}
