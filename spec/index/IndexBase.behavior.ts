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

    describeBehaviorOfSolidStateERC4626(deploy, args, [
      '#previewWithdraw(uint256)',
      '#previewRedeem(uint256)',
      ...(skips ?? []),
    ]);

    describe('overridden ERC4626 functions', () => {
      beforeEach(async () => {
        for (let i = 0; i < assets.length; i++) {
          await assets[i]
            .connect(nonProtocolOwner)
            ['increaseAllowance(address,uint256)'](
              instance.address,
              poolTokenAmounts[i],
            );
        }
      });

      describe('#previewWithdraw(uint256)', () => {
        it('todo');
      });

      describe('#previewRedeem(uint256)', () => {
        it('returns the correct amount of BPT for a given amount of IIT', async () => {
          const minBptOut = ethers.utils.parseUnits('1', 'gwei');

          const tx = await instance
            .connect(nonProtocolOwner)
            ['deposit(uint256[],uint256,address)'](
              poolTokenAmounts,
              minBptOut,
              nonProtocolOwner.address,
            );

          const { blockNumber } = await tx.wait();
          const { timestamp: depositTimestamp } =
            await ethers.provider.getBlock(blockNumber);

          const duration = 100;
          const previewTimestamp = depositTimestamp + duration;

          await hre.network.provider.send('evm_mine', [previewTimestamp]);

          const shareAmount = await instance.balanceOf(
            nonProtocolOwner.address,
          );

          const amountOutAfterFee = shareAmount
            .mul(STREAMING_FEE_FACTOR_PER_SECOND_64x64.pow(duration))
            .shr(64 * duration)
            .mul(EXIT_FEE_FACTOR_BP)
            .div(BASIS);

          const assetAmount = await instance
            .connect(nonProtocolOwner)
            .callStatic.previewRedeem(shareAmount);

          expect(assetAmount).to.eq(amountOutAfterFee);
        });
      });

      describe('#transfer(address,address,amount)', () => {
        it('emits StreamingFeePaid event', async () => {
          const minBptOut = ethers.utils.parseUnits('1', 'gwei');

          const tx = await instance
            .connect(nonProtocolOwner)
            ['deposit(uint256[],uint256,address)'](
              poolTokenAmounts,
              minBptOut,
              nonProtocolOwner.address,
            );

          const { blockNumber } = await tx.wait();
          const { timestamp: depositTimestamp } =
            await ethers.provider.getBlock(blockNumber);

          const amount = await instance.balanceOf(nonProtocolOwner.address);

          const duration = 100;
          const transferTimestamp = depositTimestamp + duration;

          await hre.network.provider.send('evm_setNextBlockTimestamp', [
            transferTimestamp,
          ]);

          const amountOutAfterFee = amount
            .mul(STREAMING_FEE_FACTOR_PER_SECOND_64x64.pow(duration))
            .shr(64 * duration);

          const fee = amount.sub(amountOutAfterFee);

          await expect(
            instance
              .connect(nonProtocolOwner)
              .transfer(receiver.address, amount),
          )
            .to.emit(instance, 'StreamingFeePaid')
            .withArgs(nonProtocolOwner.address, fee);

          // TODO: no event emitted for receiver if receiver balance is 0
        });
      });
    });
  });
}
