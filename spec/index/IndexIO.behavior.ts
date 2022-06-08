import { ethers } from 'hardhat';
import {
  IBalancerHelpers,
  IBalancerHelpers__factory,
  IERC20__factory,
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
  const poolTokenAmounts: BigNumber[] = [];
  const BALANCER_HELPERS = '0x77d46184d22CA6a3726a2F500c776767b6A3d6Ab';
  let BALANCER_VAULT = '';
  let balVaultInstance: IVault;
  let balancerHelpers: IBalancerHelpers;

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
      let unweightedAmount = ethers.utils.parseEther('0.01');
      let depositAmount = unweightedAmount
        .mul(args.weights[i])
        .div(totalWeight);
      poolTokenAmounts.push(depositAmount);
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
    balancerHelpers = IBalancerHelpers__factory.connect(
      BALANCER_HELPERS,
      depositor,
    );

    for (let i = 0; i < assets.length; i++) {
      await assets[i]
        .connect(depositor)
        ['increaseAllowance(address,uint256)'](
          instance.address,
          poolTokenAmounts[i],
        );
    }

    const investmentPoolAddress = await instance.asset();

    investmentPoolToken = SolidStateERC20Mock__factory.connect(
      investmentPoolAddress,
      depositor,
    );
  });

  describe('#deposit(uint256[],uint256)', () => {
    it('mints shares to user at 1:1 for BPT received', async () => {
      const minShareAmount = ethers.utils.parseUnits('1', 'gwei');

      // const userData = ethers.utils.solidityPack(
      // ['uint256', 'uint256[]', 'uint256'],
      // [ethers.BigNumber.from('3'), poolTokenAmounts, minShareAmount],
      // );

      // const request = {
      // assets: args.tokens,
      // maxAmountsIn: poolTokenAmounts,
      // userData,
      // fromInternalBalance: false,
      // };

      // const [bptOut, requiredAmounts] = await balancerHelpers
      // .connect(depositor)
      // .callStatic
      // .queryJoin(
      // await instance.callStatic.getPoolId(),
      // instance.address,
      // instance.address,
      // request,
      // );

      const oldUserBalance = await instance.balanceOf(depositor.address);
      const oldIndexBalance = await investmentPoolToken.balanceOf(
        instance.address,
      );

      await instance
        .connect(depositor)
        ['deposit(uint256[],uint256,address)'](
          poolTokenAmounts,
          minShareAmount,
          depositor.address,
        );

      const newUserBalance = await instance.balanceOf(depositor.address);
      const newIndexBalance = await investmentPoolToken.balanceOf(
        instance.address,
      );

      const mintedShares = newUserBalance.sub(oldUserBalance);
      const receivedBPT = newIndexBalance.sub(oldIndexBalance);

      expect(mintedShares).to.eq(receivedBPT);
    });

    it('transfers all of the deposited token amounts from user to Balancer Vault', async () => {
      const minShareAmount = ethers.utils.parseUnits('1', 'gwei');

      const oldVaultBalances = [];
      for (let i = 0; i < assets.length; i++) {
        oldVaultBalances.push(await assets[i].balanceOf(BALANCER_VAULT));
      }

      await instance
        .connect(depositor)
        ['deposit(uint256[],uint256,address)'](
          poolTokenAmounts,
          minShareAmount,
          depositor.address,
        );

      const newVaultBalances = [];
      for (let i = 0; i < assets.length; i++) {
        newVaultBalances.push(await assets[i].balanceOf(BALANCER_VAULT));
      }

      for (let i = 0; i < assets.length; i++) {
        expect(oldVaultBalances[i]).to.eq(
          newVaultBalances[i].sub(poolTokenAmounts[i]),
        );
      }
    });
  });
}
