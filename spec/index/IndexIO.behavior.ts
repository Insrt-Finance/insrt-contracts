import { ethers } from 'hardhat';
import {
  IIndex,
  IVault,
  IVault__factory,
  SolidStateERC20Mock,
  SolidStateERC20Mock__factory,
} from '../../typechain-types';
import { BigNumber } from 'ethers';
import {
  describeBehaviorOfSolidStateERC4626,
  SolidStateERC4626BehaviorArgs,
} from '@solidstate/spec';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { getBalancerContractAddress } from '@balancer-labs/v2-deployments';

export interface IndexIOBehaviorArgs {
  tokens: string[];
  weights: BigNumber[];
}

export function describeBehaviorOfIndexIO(
  deploy: () => Promise<IIndex>,
  args: IndexIOBehaviorArgs,
  skips?: string[],
) {
  let depositor: SignerWithAddress;
  let instance: IIndex;
  let investmentPoolToken: SolidStateERC20Mock;
  const assets: SolidStateERC20Mock[] = [];
  const amountsIn: BigNumber[] = [];
  let BALANCER_VAULT = '';
  let balVaultInstance: IVault;

  before(async () => {
    [depositor] = await ethers.getSigners();
    let totalWeight: BigNumber = BigNumber.from('0');
    const mintAmount = ethers.utils.parseEther('10000'); //large value to suffice for all tests
    const tokensLength = args.tokens.length;
    //giving balance to depositor, calculation of totalWeights for deposit amounts
    //note: assumption is that tokens are already deployed, and weights.length == tokens.length
    for (let i = 0; i < tokensLength; i++) {
      let asset = SolidStateERC20Mock__factory.connect(
        args.tokens[i],
        depositor,
      );

      await asset
        .connect(depositor)
        ['__mint(address,uint256)'](depositor.address, mintAmount);
      totalWeight = totalWeight.add(args.weights[i]);
      assets.push(asset);
    }

    //tokens and weights must be ordered so that weight position matches token position
    for (let i = 0; i < tokensLength; i++) {
      let depositAmount = mintAmount.mul(args.weights[i]).div(totalWeight);
      amountsIn.push(depositAmount);
    }
  });

  beforeEach(async () => {
    instance = await deploy();
    BALANCER_VAULT = await getBalancerContractAddress(
      '20210418-vault',
      'Vault',
      'arbitrum',
    );
    balVaultInstance = IVault__factory.connect(BALANCER_VAULT, depositor);

    for (let i = 0; i < assets.length; i++) {
      await assets[i]
        .connect(depositor)
        ['increaseAllowance(address,uint256)'](
          instance.address,
          ethers.constants.MaxUint256,
        );
    }

    const investmentPoolAddress = await instance.asset();

    investmentPoolToken = SolidStateERC20Mock__factory.connect(
      investmentPoolAddress,
      depositor,
    );
  });

  describe('#deposit(uint256[],uint256)', () => {
    it('it mints instance tokens to user at 1:1 for BPT received', async () => {
      const minBPTOut = ethers.utils.parseUnits('1', 'gwei');
      const [bptOut, amountsRequired] = await instance.callStatic[
        'querydeposit(uint256[],uint256)'
      ](amountsIn, minBPTOut);

      await expect(() =>
        instance
          .connect(depositor)
          ['deposit(uint256[],uint256)'](amountsIn, bptOut),
      ).to.changeTokenBalance(instance, depositor, bptOut);
    });

    it('transfers all of the deposited token amounts from user to Balancer Vault', async () => {
      const minBPTOut = ethers.utils.parseUnits('1', 'gwei');
      const [bptOut, amountsRequired] = await instance.callStatic[
        'querydeposit(uint256[],uint256)'
      ](amountsIn, minBPTOut);

      const preJoinVaultBalances = [
        await assets[0].balanceOf(BALANCER_VAULT),
        await assets[1].balanceOf(BALANCER_VAULT),
      ];
      const preJoinUserBalances = [
        await assets[0].balanceOf(depositor.address),
        await assets[1].balanceOf(depositor.address),
      ];
      await instance
        .connect(depositor)
        ['deposit(uint256[],uint256)'](amountsIn, bptOut);
      const postJoinVaultBalances = [
        await assets[0].balanceOf(BALANCER_VAULT),
        await assets[1].balanceOf(BALANCER_VAULT),
      ];
      const postJoinUserBalances = [
        await assets[0].balanceOf(depositor.address),
        await assets[1].balanceOf(depositor.address),
      ];
      for (let i = 0; i < assets.length; i++) {
        expect(preJoinVaultBalances[i]).to.eq(
          postJoinVaultBalances[i].sub(amountsIn[i]),
        );
        expect(preJoinUserBalances[i]).to.eq(
          postJoinUserBalances[i].add(amountsIn[i]),
        );
      }
    });
  });
}
