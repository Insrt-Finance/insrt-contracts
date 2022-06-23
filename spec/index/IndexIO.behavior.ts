import { ethers } from 'hardhat';
import {
  IBalancerHelpers,
  IBalancerHelpers__factory,
  IIndex,
  IVault,
  IVault__factory,
  SolidStateERC20Mock,
  SolidStateERC20Mock__factory,
} from '../../typechain-types';
import { BigNumber } from 'ethers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { getBalancerContractAddress } from '@balancer-labs/v2-deployments';
import { Interface } from '@ethersproject/abi';
import { defaultAbiCoder } from 'ethers/lib/utils';

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
  let arbitraryERC20: SolidStateERC20Mock;
  const assets: SolidStateERC20Mock[] = [];
  const poolTokenAmounts: BigNumber[] = [];
  const BALANCER_HELPERS = '0x77d46184d22CA6a3726a2F500c776767b6A3d6Ab';
  const uniswapV2RouterAddress = '0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506';
  const uniSwapV2RouterABI = new Interface([
    'function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) returns (uint amountA, uint amountB, uint liquidity)',
    'function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] path, address to, uint deadline) returns (uint[] amounts)',
  ]);
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
    arbitraryERC20 = await new SolidStateERC20Mock__factory(depositor).deploy(
      'ArbERC20',
      'AERC20',
    );
    await arbitraryERC20['__mint(address,uint256)'](
      depositor.address,
      ethers.utils.parseEther('1000000'),
    );
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

  describe.only('#deposit(uint256[],uint256)', () => {
    it('mints shares to user at 1:1 for BPT received', async () => {
      const minBptOut = ethers.utils.parseUnits('1', 'gwei');

      const userData = defaultAbiCoder.encode(
        ['uint256', 'uint256[]', 'uint256'],
        [ethers.BigNumber.from('1'), poolTokenAmounts, minBptOut],
      );

      const request = {
        assets: args.tokens,
        maxAmountsIn: poolTokenAmounts,
        userData: userData,
        fromInternalBalance: false,
      };

      const [bptOut, requiredAmounts] = await balancerHelpers
        .connect(depositor)
        .callStatic.queryJoin(
          await instance.callStatic.getPoolId(),
          instance.address,
          instance.address,
          request,
        );

      await expect(() =>
        instance
          .connect(depositor)
          ['deposit(uint256[],uint256,address)'](
            poolTokenAmounts,
            minBptOut,
            depositor.address,
          ),
      ).to.changeTokenBalance(instance, depositor, bptOut);
    });

    it('transfers all of the deposited token amounts from user to Balancer Vault', async () => {
      const minBptOut = ethers.utils.parseUnits('1', 'gwei');

      const oldVaultBalances = [];
      for (let i = 0; i < assets.length; i++) {
        oldVaultBalances.push(await assets[i].balanceOf(BALANCER_VAULT));
      }

      await instance
        .connect(depositor)
        ['deposit(uint256[],uint256,address)'](
          poolTokenAmounts,
          minBptOut,
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

  describe('#deposit(address,uint256,address,uint256,uint256,uint256,address,bytes,address)', () => {
    it('mints shares to user at 1:1 for BPT received', async () => {
      const uniswapV2Router = new ethers.Contract(
        uniswapV2RouterAddress,
        uniSwapV2RouterABI,
        depositor,
      );
      const { timestamp } = await ethers.provider.getBlock('latest');
      const liquidityAmount = ethers.utils.parseEther('100');
      const deadline = BigNumber.from(timestamp.toString()).add(
        BigNumber.from('86000'),
      );
      await arbitraryERC20.approve(uniswapV2RouterAddress, liquidityAmount);
      await assets[0].approve(uniswapV2RouterAddress, liquidityAmount);
      await uniswapV2Router
        .connect(depositor)
        .addLiquidity(
          assets[0].address,
          arbitraryERC20.address,
          liquidityAmount,
          liquidityAmount,
          ethers.utils.parseEther('1'),
          ethers.utils.parseEther('1'),
          depositor.address,
          deadline,
        );

      const amountIn = ethers.utils.parseEther('1.0');
      const amountOutMin = ethers.utils.parseEther('0.1');
      await arbitraryERC20
        .connect(depositor)
        .approve(instance.address, amountIn);
      const swapper = await instance.getSwapper();
      const data = uniSwapV2RouterABI.encodeFunctionData(
        'swapExactTokensForTokens',
        [
          amountIn,
          amountOutMin,
          [arbitraryERC20.address, assets[0].address],
          swapper,
          deadline,
        ],
      );
      const target = uniswapV2RouterAddress;

      const oldUserBalance = await instance.balanceOf(depositor.address);
      const oldIndexBalance = await investmentPoolToken.balanceOf(
        instance.address,
      );

      await instance
        .connect(depositor)
        [
          'deposit(address,uint256,address,uint256,uint256,uint256,address,bytes,address)'
        ](
          arbitraryERC20.address,
          amountIn,
          assets[0].address,
          amountOutMin,
          ethers.constants.Zero,
          amountOutMin,
          target,
          data,
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
  });

  describe('#redeem(uint256,uint256[],address)', () => {
    it('burns BPT at 1:1, for shares - fee', async () => {
      // const minBptOut = ethers.utils.parseUnits('1', 'gwei');

      // await instance
      // .connect(depositor)
      // ['deposit(uint256[],uint256,address)'](
      // poolTokenAmounts,
      // minBptOut,
      // depositor.address,
      // );

      // const oldUserBalance = await instance.balanceOf(depositor.address);
      // const oldBptSupply = await investmentPoolToken.totalSupply();
      // const minPoolTokenAmounts = [
      // minBptOut,
      // minBptOut
      // ];

      // await instance.connect(depositor)['redeem(uint256,uint256[],address)']
      // (oldUserBalance, minPoolTokenAmounts, depositor.address);

      // const newUserBalance = await instance.balanceOf(depositor.address);
      // const newBptSupply = await investmentPoolToken.totalSupply();

      // const fee = await instance.getExitFee();
      // const feeBasis = BigNumber.from('10000');
      // const feeScaling = (feeBasis.sub(fee)).div(feeBasis);

      // const bptDelta = newBptSupply.sub(oldBptSupply);
      // const userDelta = newUserBalance.sub(oldUserBalance);
      // expect(bptDelta).to.eq(userDelta.mul(feeScaling));
      const minBptOut = ethers.utils.parseUnits('1', 'gwei');

      await instance
        .connect(depositor)
        ['deposit(uint256[],uint256,address)'](
          poolTokenAmounts,
          minBptOut,
          depositor.address,
        );

      const userBalance = await instance.balanceOf(depositor.address);

      const userData = ethers.utils.solidityPack(
        ['uint256', 'uint256'],
        [ethers.BigNumber.from('1'), userBalance],
      );

      const minPoolTokenAmounts = [minBptOut, minBptOut];

      const request = {
        assets: args.tokens,
        minAmountsOut: minPoolTokenAmounts,
        userData,
        toInternalBalance: false,
      };

      const [bptIn, returnedAmounts] = await balancerHelpers
        .connect(depositor)
        .callStatic.queryExit(
          await instance.callStatic.getPoolId(),
          instance.address,
          depositor.address,
          request,
        );

      const fee = await instance.getExitFee();
      const feeBasis = BigNumber.from('10000');
      const feeScaling = feeBasis.sub(fee).div(feeBasis);

      await expect(() =>
        instance
          .connect(depositor)
          ['redeem(uint256,uint256[],address)'](
            userBalance,
            minPoolTokenAmounts,
            depositor.address,
          ),
      ).to.changeTokenBalance(
        instance,
        depositor,
        bptIn.mul(feeScaling).mul(ethers.constants.NegativeOne),
      );
    });

    it('returns tokens to user', async () => {
      const minBptOut = ethers.utils.parseUnits('1', 'gwei');

      await instance
        .connect(depositor)
        ['deposit(uint256[],uint256,address)'](
          poolTokenAmounts,
          minBptOut,
          depositor.address,
        );

      const userBalance = await instance.balanceOf(depositor.address);

      const userData = ethers.utils.solidityPack(
        ['uint256', 'uint256'],
        [ethers.BigNumber.from('1'), userBalance],
      );

      const minPoolTokenAmounts = [minBptOut, minBptOut];

      const request = {
        assets: args.tokens,
        minAmountsOut: minPoolTokenAmounts,
        userData,
        toInternalBalance: false,
      };

      const [bptIn, returnedAmounts] = await balancerHelpers
        .connect(depositor)
        .callStatic.queryExit(
          await instance.callStatic.getPoolId(),
          instance.address,
          instance.address,
          request,
        );

      const oldUserBalances = [];
      for (let i = 0; i < assets.length; i++) {
        oldUserBalances.push(await assets[i].balanceOf(depositor.address));
      }
      await instance
        .connect(depositor)
        ['redeem(uint256,uint256[],address)'](
          userBalance,
          minPoolTokenAmounts,
          depositor.address,
        );

      const newUserBalances = [];
      for (let i = 0; i < assets.length; i++) {
        newUserBalances.push(await assets[i].balanceOf(depositor.address));
      }

      for (let i = 0; i < assets.length; i++) {
        expect(returnedAmounts[i]).to.eq(
          newUserBalances[i].sub(oldUserBalances[i]),
        );
      }
    });
  });

  describe('#redeem(uint256,uint256[],uint256,address)', () => {
    it('burns BPT at 1:1 for shares - fee', async () => {
      const minBptOut = ethers.utils.parseUnits('1', 'gwei');

      await instance
        .connect(depositor)
        ['deposit(uint256[],uint256,address)'](
          poolTokenAmounts,
          minBptOut,
          depositor.address,
        );

      const userData = ethers.utils.solidityPack(
        ['uint256', 'uint256', 'uint256'],
        [ethers.constants.Zero, minBptOut, ethers.constants.Zero],
      );

      const minPoolTokenAmounts = [
        ethers.constants.Zero,
        ethers.constants.Zero,
      ];

      const request = {
        assets: args.tokens,
        minAmountsOut: minPoolTokenAmounts,
        userData,
        toInternalBalance: false,
      };

      const [bptIn, returnedAmounts] = await balancerHelpers
        .connect(depositor)
        .callStatic.queryExit(
          await instance.callStatic.getPoolId(),
          instance.address,
          depositor.address,
          request,
        );

      const fee = await instance.getExitFee();
      const feeBasis = BigNumber.from('10000');
      const feeScaling = feeBasis.sub(fee).div(feeBasis);

      await expect(() =>
        instance
          .connect(depositor)
          ['redeem(uint256,uint256[],uint256,address)'](
            minBptOut,
            minPoolTokenAmounts,
            ethers.constants.Zero,
            depositor.address,
          ),
      ).to.changeTokenBalance(
        instance,
        depositor,
        bptIn.mul(feeScaling).mul(ethers.constants.NegativeOne),
      );
    });
  });
}
