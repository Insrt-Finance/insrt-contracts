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
    const tokenLength = args.tokens.length;
    //giving balance to depositor, calculation of totalWeights for deposit amounts
    //note: assumption is that tokens are already deployed, and weights.length == tokens.length
    for (let i = 0; i < tokenLength; i++) {
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
    for (let i = 0; i < args.tokens.length; i++) {
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
    console.log('\nInitialization of underlying Balancer Investment Pool: \n');
    await assets[0]
      .connect(depositor)
      ['increaseAllowance(address,uint256)'](
        instance.address,
        amountsIn[0].mul(BigNumber.from('100')),
      );
    await assets[1]
      .connect(depositor)
      ['increaseAllowance(address,uint256)'](
        instance.address,
        amountsIn[1].mul(BigNumber.from('100')),
      );
    console.log(
      '\nExpect total BPT supply to be greater than what was received by the pool, ' +
        'and for the depositor to have an equal amount of Insrt-Index tokens as the balance of BPT in the Insrt-Index.\n',
    );
    const investmentPoolAddress = await instance.getPool();
    investmentPoolToken = SolidStateERC20Mock__factory.connect(
      investmentPoolAddress,
      depositor,
    );
    console.log(
      'BPT Supply: ',
      (await investmentPoolToken['totalSupply()']()).toBigInt(),
    );
    console.log(
      'Index Balance of BPT: ',
      (
        await investmentPoolToken['balanceOf(address)'](instance.address)
      ).toBigInt(),
    );
    console.log(
      'User balance of Insrt-Index: ',
      (
        await instance
          .connect(depositor)
          ['balanceOf(address)'](depositor.address)
      ).toBigInt(),
      '\n\n',
    );
  });

  describe('#userDepositExactInForAnyOut(uint256[],uint256)', () => {
    it('it mints instance tokens to user at 1:1 for BPT received', async () => {
      const minBPTOut = ethers.utils.parseUnits('1', 'gwei');
      const [bptOut, amountsRequired] = await instance.callStatic[
        'queryUserDepositExactInForAnyOut(uint256[],uint256)'
      ](amountsIn, minBPTOut);

      await expect(() =>
        instance
          .connect(depositor)
          ['userDepositExactInForAnyOut(uint256[],uint256)'](amountsIn, bptOut),
      ).to.changeTokenBalance(instance, depositor, bptOut);
    });

    it('transfers all of the deposited token amounts from user to Balancer Vault', async () => {
      const minBPTOut = ethers.utils.parseUnits('1', 'gwei');
      const [bptOut, amountsRequired] = await instance.callStatic[
        'queryUserDepositExactInForAnyOut(uint256[],uint256)'
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
        ['userDepositExactInForAnyOut(uint256[],uint256)'](amountsIn, bptOut);
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
