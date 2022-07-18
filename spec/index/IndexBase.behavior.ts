import hre, { ethers } from 'hardhat';
import { IIndex, SolidStateERC20Mock } from '../../typechain-types';

import { BigNumber, BigNumberish, ContractTransaction, Signer } from 'ethers';
import {
  describeBehaviorOfSolidStateERC4626,
  SolidStateERC4626BehaviorArgs,
} from '@solidstate/spec';
import { expect } from 'chai';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { SolidStateERC20Mock__factory } from '../../typechain-types';

export interface IndexBaseBehaviorArgs extends SolidStateERC4626BehaviorArgs {
  getProtocolOwner: () => Promise<SignerWithAddress>;
  weights: BigNumber[];
  streamingFeeBP: BigNumber;
  exitFeeBP: BigNumber;
  tokens: string[];
}

export function describeBehaviorOfIndexBase(
  deploy: () => Promise<IIndex>,
  args: IndexBaseBehaviorArgs,
  skips?: string[],
) {
  describe('::IndexBase', () => {
    let instance: IIndex;
    let protocolOwner: SignerWithAddress;
    let nonProtocolOwner: SignerWithAddress;
    let receiver: SignerWithAddress;

    const BASIS = ethers.utils.parseUnits('1', 4);
    const EXIT_FEE_FACTOR_BP = BASIS.sub(args.exitFeeBP);
    const STREAMING_FEE_FACTOR_PER_SECOND_64x64 = ethers.constants.One.shl(
      64,
    ).sub(
      args.streamingFeeBP
        .shl(64)
        .div(365.25 * 86400)
        .div(BASIS),
    );

    const assetAmount = ethers.utils.parseUnits('1', 5);
    const assets: SolidStateERC20Mock[] = [];
    const poolTokenAmounts: BigNumber[] = [];

    before(async () => {
      instance = await deploy();
      protocolOwner = await args.getProtocolOwner();
      [, nonProtocolOwner, receiver] = await ethers.getSigners();
      let totalWeight: BigNumber = BigNumber.from('0');

      const mintAmount = ethers.utils.parseEther('10000'); //large value to suffice for all tests
      const tokensLength = args.tokens.length;
      for (let i = 0; i < tokensLength; i++) {
        let asset = SolidStateERC20Mock__factory.connect(
          args.tokens[i],
          nonProtocolOwner,
        );

        await asset
          .connect(nonProtocolOwner)
          ['__mint(address,uint256)'](nonProtocolOwner.address, mintAmount);
        totalWeight = totalWeight.add(args.weights[i]);
        assets.push(asset);
      }

      for (let i = 0; i < tokensLength; i++) {
        let unweightedAmount = ethers.utils.parseEther('0.01');
        let depositAmount = unweightedAmount
          .mul(args.weights[i])
          .div(totalWeight);
        poolTokenAmounts.push(depositAmount);
      }
    });

    describe('overriden ERC4626 internal functions', () => {
      const minBptOut = ethers.utils.parseUnits('1', 'gwei');
      const timeStep = 100;
      let depositTimeStamp;
      let laterTimestamp;
      let duration;
      let transferAmount;

      beforeEach(async () => {
        for (let i = 0; i < assets.length; i++) {
          await assets[i]
            .connect(nonProtocolOwner)
            ['increaseAllowance(address,uint256)'](
              instance.address,
              poolTokenAmounts[i],
            );
        }

        const tx = await instance
          .connect(nonProtocolOwner)
          ['deposit(uint256[],uint256,address)'](
            poolTokenAmounts,
            minBptOut,
            nonProtocolOwner.address,
          );

        const { blockNumber } = await tx.wait();
        const { timestamp: first } = await ethers.provider.getBlock(
          blockNumber,
        );
        depositTimeStamp = first;

        await hre.network.provider.send('evm_setNextBlockTimestamp', [
          depositTimeStamp + timeStep,
        ]);

        await hre.network.provider.send('evm_mine', []);

        const { timestamp: second } = await ethers.provider.getBlock('latest');
        laterTimestamp = second;

        duration = laterTimestamp - depositTimeStamp;

        transferAmount = await instance.balanceOf(nonProtocolOwner.address);
      });

      describe('previewRedeem(uint256)', () => {
        it('returns the correct amount of BPT for a given amount of IIT for a nonProtocolOwner', async () => {
          const shareAmount = await instance
            .connect(nonProtocolOwner)
            .callStatic['previewWithdraw(uint256)'](assetAmount);
          const amountOutAfterFee = assetAmount
            .mul(STREAMING_FEE_FACTOR_PER_SECOND_64x64.pow(duration))
            .shr(64 * duration)
            .mul(EXIT_FEE_FACTOR_BP)
            .div(BASIS);

          expect(shareAmount).to.eq(amountOutAfterFee);
        });

        it('returns the same amount of BPT for a given amount of IIT for the protocolOwner', async () => {
          const shareAmount = await instance
            .connect(protocolOwner)
            .callStatic['previewWithdraw(uint256)'](assetAmount);
          expect(shareAmount).to.equal(assetAmount);
        });
      });

      describe('transfer(address,address,amount)', () => {
        let snapshotId;
        let fee;
        beforeEach(async () => {
          snapshotId = await ethers.provider.send('evm_snapshot', []);

          await hre.network.provider.send('evm_setNextBlockTimestamp', [
            depositTimeStamp + timeStep * 2,
          ]);

          fee = transferAmount.sub(
            transferAmount
              .mul(
                STREAMING_FEE_FACTOR_PER_SECOND_64x64.pow(duration + timeStep),
              )
              .shr(64 * (duration + timeStep)),
          );
        });

        afterEach(async () => {
          await ethers.provider.send('evm_revert', [snapshotId]);
        });
        it('emits StreamingFeePaid event for nonProtocolOwner and receiver', async () => {
          await expect(
            await instance
              .connect(nonProtocolOwner)
              .transfer(receiver.address, transferAmount),
          )
            .to.emit(instance, 'StreamingFeePaid')
            .withArgs(nonProtocolOwner.address, fee)
            .to.emit(instance, 'StreamingFeePaid')
            .withArgs(receiver.address, 0);
        });
      });
      describe('_beforeWithdraw(address,uint256,uint256)', () => {});
      describe('_afterDeposit(address,uint256,uint256)', () => {});
    });

    describeBehaviorOfSolidStateERC4626(deploy, args, skips);
  });
}
