import { ethers } from 'hardhat';
import {
  IIndex,
  IVault__factory,
  SolidStateERC20Mock,
  SolidStateERC20Mock__factory,
} from '../../typechain-types';
import { BigNumber, BigNumberish, ContractTransaction } from 'ethers';
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
  let balVaultInstance;

  before(async () => {
    [depositor] = await ethers.getSigners();
    BALANCER_VAULT = await getBalancerContractAddress(
      '20210418-vault',
      'Vault',
      'arbitrum',
    );
    balVaultInstance = IVault__factory.connect(BALANCER_VAULT, depositor);
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
    await instance.connect(depositor).initializePoolByDeposit(amountsIn);
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
    it('mints shares to user at 1:1 for BPT received,', async () => {
      const bptAmountWanted = ethers.utils.parseUnits('1000000', 'gwei');
      const [bptOut, amountsRequired] = await instance.callStatic[
        'queryUserDepositSingleForExactOut(uint256[],uint256,uint256)'
      ](amountsIn, bptAmountWanted, 0);

      console.log('BPT Out: ', bptOut);
      console.log('IT Out: ', await instance.previewDeposit(bptAmountWanted));

      await expect(() =>
        instance
          .connect(depositor)
          ['userDepositSingleForExactOut(uint256[],uint256,uint256)'](
            amountsIn,
            bptAmountWanted,
            0,
          ),
      ).to.changeTokenBalance(
        instance,
        depositor,
        await instance.previewDeposit(bptAmountWanted),
      );
    });

    it('query test', async () => {
      const [bptOut, amountsInned] = await instance.callStatic[
        'queryUserDepositSingleForExactOut(uint256[],uint256,uint256)'
      ](amountsIn, ethers.utils.parseUnits('1', 'wei'), 0);
      console.log(bptOut, amountsInned);
    });
  });

  describe('#userDepositExactInForAnyOut(uint256[],uint256)', () => {
    it('it transfers all tokens from the user', async () => {
      const [bptOut, amountsInned] = await instance.callStatic[
        'queryUserDepositExactInForAnyOut(uint256[],uint256)'
      ](amountsIn, ethers.utils.parseUnits('1', 'wei'));

      await instance
        .connect(depositor)
        ['userDepositExactInForAnyOut(uint256[],uint256)'](
          amountsIn,
          ethers.utils.parseUnits('1', 'gwei'),
        );
    });
  });
}
