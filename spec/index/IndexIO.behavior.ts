import hre, { ethers } from 'hardhat';
import {
  IBalancerHelpers,
  IBalancerHelpers__factory,
  IIndex,
  SolidStateERC20Mock,
  SolidStateERC20Mock__factory,
  UniswapV2Router02,
  UniswapV2Router02__factory,
} from '../../typechain-types';
import { BigNumber } from 'ethers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { getBalancerContractAddress } from '@balancer-labs/v2-deployments';
import { defaultAbiCoder } from 'ethers/lib/utils';

export interface IndexIOBehaviorArgs {
  tokens: string[];
  weights: BigNumber[];
  swapper: string[];
  streamingFee: BigNumber;
}

export function describeBehaviorOfIndexIO(
  deploy: () => Promise<IIndex>,
  args: IndexIOBehaviorArgs,
  skips?: string[],
) {
  let depositor: SignerWithAddress;
  let protocolOwner: SignerWithAddress;
  let instance: IIndex;
  let investmentPoolToken: SolidStateERC20Mock;
  let arbitraryERC20: SolidStateERC20Mock;
  const assets: SolidStateERC20Mock[] = [];
  const poolTokenAmounts: BigNumber[] = [];
  const BALANCER_HELPERS = '0x77d46184d22CA6a3726a2F500c776767b6A3d6Ab'; //arbitrum
  const uniswapV2RouterAddress = '0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506'; //arbitrum
  const feeBasis = ethers.utils.parseEther('1.0');
  const streamingFeePerSecond = args.streamingFee.div(31557600); //streamingFee / (365.25*24*3600)
  const decayFactor = ethers.utils.parseEther('1.0').sub(streamingFeePerSecond);

  let BALANCER_VAULT = '';
  let balancerHelpers: IBalancerHelpers;
  let uniswapV2Router: UniswapV2Router02;
  let deadline: BigNumber;

  before(async () => {
    [protocolOwner, depositor] = await ethers.getSigners();
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

    uniswapV2Router = UniswapV2Router02__factory.connect(
      uniswapV2RouterAddress,
      depositor,
    );

    let { timestamp } = await ethers.provider.getBlock('latest');
    deadline = BigNumber.from(timestamp.toString()).add(
      BigNumber.from('86000'),
    );

    const liquidityAmount = ethers.utils.parseEther('100');
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
  });

  beforeEach(async () => {
    instance = await deploy();

    BALANCER_VAULT = await getBalancerContractAddress(
      '20210418-vault',
      'Vault',
      'arbitrum',
    );
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
      const amountIn = ethers.utils.parseEther('1.0');
      const amountOutMin = ethers.constants.Zero;
      await arbitraryERC20
        .connect(depositor)
        .approve(instance.address, amountIn);

      //for query
      await arbitraryERC20
        .connect(depositor)
        .approve(uniswapV2RouterAddress, amountIn);

      const swapper = args.swapper[0];

      const queriedSwapAmounts = await uniswapV2Router
        .connect(depositor)
        .callStatic.swapExactTokensForTokens(
          amountIn,
          amountOutMin,
          [arbitraryERC20.address, assets[0].address],
          swapper,
          deadline,
        );

      //position of output token amount
      const queriedSwapAmountOut = queriedSwapAmounts[1];

      //filling inputAmounts array for balancer query
      const inputAmounts = [queriedSwapAmountOut];
      for (let i = 1; i < assets.length; i++) {
        inputAmounts[i] = ethers.constants.Zero;
      }

      const userData = defaultAbiCoder.encode(
        ['uint256', 'uint256[]', 'uint256'],
        [ethers.BigNumber.from('1'), inputAmounts, amountOutMin],
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

      const swapData = uniswapV2Router.interface.encodeFunctionData(
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

      await expect(() =>
        instance
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
            swapData,
            depositor.address,
          ),
      ).to.changeTokenBalance(instance, depositor, bptOut);
    });

    describe('reverts if', () => {
      it('swapper: amount of output token returned is less than minimum  expected', async () => {
        const amountIn = ethers.utils.parseEther('1.0');
        const amountOutMin = ethers.utils.parseEther('100000');
        await arbitraryERC20
          .connect(depositor)
          .approve(instance.address, amountIn);

        //for query
        await arbitraryERC20
          .connect(depositor)
          .approve(uniswapV2RouterAddress, amountIn);

        const swapper = args.swapper[0];

        const swapData = uniswapV2Router.interface.encodeFunctionData(
          'swapExactTokensForTokens',
          [
            amountIn,
            ethers.constants.Zero,
            [arbitraryERC20.address, assets[0].address],
            swapper,
            deadline,
          ],
        );
        const target = uniswapV2RouterAddress;

        await expect(
          instance
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
              swapData,
              depositor.address,
            ),
        ).to.be.revertedWith('Swapper: output token amount received too small');
      });

      it('swapper: external call fails', async () => {
        const amountIn = ethers.utils.parseEther('1.0');
        const amountOutMin = ethers.utils.parseEther('100000');
        await arbitraryERC20
          .connect(depositor)
          .approve(instance.address, amountIn);

        //for query
        await arbitraryERC20
          .connect(depositor)
          .approve(uniswapV2RouterAddress, amountIn);

        const swapper = args.swapper[0];

        const swapData = uniswapV2Router.interface.encodeFunctionData(
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

        await expect(
          instance
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
              swapData,
              depositor.address,
            ),
        ).to.be.revertedWith('Swapper: external swap failed');
      });
    });
  });

  describe('#redeem(uint256,uint256[],address)', () => {
    it('burns BPT at 1:1, for shares - fee', async () => {
      const minBptOut = ethers.utils.parseUnits('1', 'gwei');

      await instance
        .connect(depositor)
        ['deposit(uint256[],uint256,address)'](
          poolTokenAmounts,
          minBptOut,
          depositor.address,
        );

      const depositBlock = await ethers.provider.getBlock('latest');
      const depositTimeStamp = BigNumber.from(
        depositBlock.timestamp.toString(),
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

      const oldTotalSupply = await investmentPoolToken['totalSupply()']();
      const exitFee = await instance.exitFee();
      const bptExitFee = bptIn.mul(exitFee).div(feeBasis);
      const bptAfterExitFee = bptIn.sub(bptExitFee);

      await hre.network.provider.send('evm_setNextBlockTimestamp', [
        depositTimeStamp.add(BigNumber.from('100')).toNumber(),
      ]);

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
        bptIn.mul(ethers.constants.NegativeOne),
      );

      const redeemBlock = await ethers.provider.getBlock('latest');
      const redeemTimestamp = BigNumber.from(redeemBlock.timestamp.toString());
      const duration = redeemTimestamp.sub(depositTimeStamp);
      const decayedBPTAfterExitFee = decayFactor
        .pow(duration)
        .mul(bptAfterExitFee)
        .div(feeBasis.pow(duration));
      const bptStreamingFee = bptAfterExitFee.sub(decayedBPTAfterExitFee);
      const bptAfterAllFees = bptIn.sub(bptStreamingFee).sub(bptExitFee);

      const newTotalSupply = await investmentPoolToken['totalSupply()']();

      expect(oldTotalSupply.sub(newTotalSupply)).to.eq(bptAfterAllFees);
    });

    it('increases the user balance by the amount returned by the query - fee', async () => {
      const minBptOut = ethers.utils.parseUnits('1', 'gwei');

      await instance
        .connect(depositor)
        ['deposit(uint256[],uint256,address)'](
          poolTokenAmounts,
          minBptOut,
          depositor.address,
        );

      const depositBlock = await ethers.provider.getBlock('latest');
      const depositTimeStamp = BigNumber.from(
        depositBlock.timestamp.toString(),
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

      const oldUserBalances = [];
      for (let i = 0; i < assets.length; i++) {
        oldUserBalances.push(await assets[i].balanceOf(depositor.address));
      }

      await hre.network.provider.send('evm_setNextBlockTimestamp', [
        depositTimeStamp.add(BigNumber.from('100')).toNumber(),
      ]);

      const [bptIn, returnedAmounts] = await balancerHelpers
        .connect(depositor)
        .callStatic.queryExit(
          await instance.callStatic.getPoolId(),
          instance.address,
          instance.address,
          request,
        );

      await instance
        .connect(depositor)
        ['redeem(uint256,uint256[],address)'](
          userBalance,
          minPoolTokenAmounts,
          depositor.address,
        );

      const redeemBlock = await ethers.provider.getBlock('latest');
      const redeemTimestamp = BigNumber.from(redeemBlock.timestamp.toString());
      const duration = redeemTimestamp.sub(depositTimeStamp);

      const newUserBalances = [];
      for (let i = 0; i < assets.length; i++) {
        newUserBalances.push(await assets[i].balanceOf(depositor.address));
      }

      const exitFee = await instance.exitFee();

      for (let i = 0; i < assets.length; i++) {
        let exitFeeAmount = returnedAmounts[i].mul(exitFee).div(feeBasis);
        let returnedAmountAfterExitFee = returnedAmounts[i].sub(exitFeeAmount);
        let decayedReturnedAmountAfterExitFee = decayFactor
          .pow(duration)
          .mul(returnedAmountAfterExitFee)
          .div(feeBasis.pow(duration));
        let streamingFeeAmount = returnedAmountAfterExitFee.sub(
          decayedReturnedAmountAfterExitFee,
        );

        expect(
          returnedAmounts[i].sub(exitFeeAmount).sub(streamingFeeAmount),
        ).to.eq(newUserBalances[i].sub(oldUserBalances[i]));
      }
    });

    it('sends the fees to the protocol owner', async () => {
      const minBptOut = ethers.utils.parseUnits('1', 'gwei');

      await instance
        .connect(depositor)
        ['deposit(uint256[],uint256,address)'](
          poolTokenAmounts,
          minBptOut,
          depositor.address,
        );

      const depositBlock = await ethers.provider.getBlock('latest');
      const depositTimeStamp = BigNumber.from(
        depositBlock.timestamp.toString(),
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

      const oldFeeRecipientBalance = await instance.balanceOf(
        protocolOwner.address,
      );

      await hre.network.provider.send('evm_setNextBlockTimestamp', [
        depositTimeStamp.add(BigNumber.from('100')).toNumber(),
      ]);

      await instance
        .connect(depositor)
        ['redeem(uint256,uint256[],address)'](
          userBalance,
          minPoolTokenAmounts,
          depositor.address,
        );

      const newFeeRecipientBalance = await instance.balanceOf(
        protocolOwner.address,
      );

      const exitFee = await instance.exitFee();
      const bptExitFee = bptIn.mul(exitFee).div(feeBasis);
      const bptAfterExitFee = bptIn.sub(bptExitFee);
      const redeemBlock = await ethers.provider.getBlock('latest');
      const redeemTimestamp = BigNumber.from(redeemBlock.timestamp.toString());
      const duration = redeemTimestamp.sub(depositTimeStamp);
      const decayedBPTAfterExitFee = decayFactor
        .pow(duration)
        .mul(bptAfterExitFee)
        .div(feeBasis.pow(duration));
      const bptStreamingFee = bptAfterExitFee.sub(decayedBPTAfterExitFee);

      expect(bptExitFee.add(bptStreamingFee)).to.eq(
        newFeeRecipientBalance.sub(oldFeeRecipientBalance),
      );
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

      const depositBlock = await ethers.provider.getBlock('latest');
      const depositTimeStamp = BigNumber.from(
        depositBlock.timestamp.toString(),
      );
      const userBalance = await instance.balanceOf(depositor.address);
      const userData = ethers.utils.solidityPack(
        ['uint256', 'uint256', 'uint256'],
        [ethers.constants.Zero, userBalance, ethers.constants.Zero],
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

      await hre.network.provider.send('evm_setNextBlockTimestamp', [
        depositTimeStamp.add(BigNumber.from('100')).toNumber(),
      ]);

      const tokenId = ethers.constants.Zero;

      const oldSupply = await instance.totalSupply();
      const exitFee = await instance.exitFee();
      const bptExitFee = bptIn.mul(exitFee).div(feeBasis);
      const bptAfterExitFee = bptIn.sub(bptExitFee);

      await expect(() =>
        instance
          .connect(depositor)
          ['redeem(uint256,uint256[],uint256,address)'](
            userBalance,
            minPoolTokenAmounts,
            tokenId,
            depositor.address,
          ),
      ).to.changeTokenBalance(
        instance,
        depositor,
        bptIn.mul(ethers.constants.NegativeOne),
      );
      const redeemBlock = await ethers.provider.getBlock('latest');
      const redeemTimestamp = BigNumber.from(redeemBlock.timestamp.toString());
      const duration = redeemTimestamp.sub(depositTimeStamp);
      const decayedBPTAfterExitFee = decayFactor
        .pow(duration)
        .mul(bptAfterExitFee)
        .div(feeBasis.pow(duration));
      const bptStreamingFee = bptAfterExitFee.sub(decayedBPTAfterExitFee);
      const bptAfterAllFees = bptIn.sub(bptStreamingFee).sub(bptExitFee);
      const newSupply = await instance.totalSupply();

      expect(oldSupply.sub(newSupply)).to.eq(bptAfterAllFees);
    });

    it('increases the user balance by the amount returned by the query - fee', async () => {
      const minBptOut = ethers.utils.parseUnits('1', 'gwei');
      const duration = BigNumber.from('100');

      await instance
        .connect(depositor)
        ['deposit(uint256[],uint256,address)'](
          poolTokenAmounts,
          minBptOut,
          depositor.address,
        );

      const depositBlock = await ethers.provider.getBlock('latest');
      const depositTimeStamp = BigNumber.from(
        depositBlock.timestamp.toString(),
      );
      const minPoolTokenAmounts = [
        ethers.constants.Zero,
        ethers.constants.Zero,
      ];

      //mimic effect of applying both fees
      const userIndexBalance = await instance.balanceOf(depositor.address);
      const tokenId = ethers.constants.Zero;
      const exitFee = await instance.exitFee();
      const exitFeeAmount = userIndexBalance.mul(exitFee).div(feeBasis);
      const returnedAmountAfterExitFee = userIndexBalance.sub(exitFeeAmount);
      const decayedReturnedAmountAfterExitFee = decayFactor
        .pow(duration)
        .mul(returnedAmountAfterExitFee)
        .div(feeBasis.pow(duration));

      const userData = ethers.utils.solidityPack(
        ['uint256', 'uint256', 'uint256'],
        [
          ethers.constants.Zero,
          decayedReturnedAmountAfterExitFee,
          ethers.constants.Zero,
        ],
      );
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

      const returnedIndexTokenAmount = returnedAmounts[tokenId.toNumber()];

      const oldUserBalance = await assets[tokenId.toNumber()].balanceOf(
        depositor.address,
      );

      await hre.network.provider.send('evm_setNextBlockTimestamp', [
        depositTimeStamp.add(duration).toNumber(),
      ]);

      await instance
        .connect(depositor)
        ['redeem(uint256,uint256[],uint256,address)'](
          userIndexBalance,
          minPoolTokenAmounts,
          tokenId,
          depositor.address,
        );

      const newUserBalance = await assets[tokenId.toNumber()].balanceOf(
        depositor.address,
      );

      expect(returnedIndexTokenAmount).to.eq(
        newUserBalance.sub(oldUserBalance),
      );
    });

    it('sends the total fees to the protocol owner', async () => {
      const minBptOut = ethers.utils.parseUnits('1', 'gwei');

      await instance
        .connect(depositor)
        ['deposit(uint256[],uint256,address)'](
          poolTokenAmounts,
          minBptOut,
          depositor.address,
        );

      const depositBlock = await ethers.provider.getBlock('latest');
      const depositTimeStamp = BigNumber.from(
        depositBlock.timestamp.toString(),
      );

      const minPoolTokenAmounts = [
        ethers.constants.Zero,
        ethers.constants.Zero,
      ];

      const tokenId = ethers.constants.Zero;

      const userData = ethers.utils.solidityPack(
        ['uint256', 'uint256', 'uint256'],
        [ethers.constants.Zero, minBptOut, ethers.constants.Zero],
      );

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

      const oldProtocolOwnerBalance = await instance.balanceOf(
        protocolOwner.address,
      );

      await hre.network.provider.send('evm_setNextBlockTimestamp', [
        depositTimeStamp.add(BigNumber.from('100')).toNumber(),
      ]);

      await instance
        .connect(depositor)
        ['redeem(uint256,uint256[],uint256,address)'](
          minBptOut,
          minPoolTokenAmounts,
          tokenId,
          depositor.address,
        );

      const newProtocolOwnerBalance = await instance.balanceOf(
        protocolOwner.address,
      );

      const exitFee = await instance.exitFee();
      const bptExitFee = bptIn.mul(exitFee).div(feeBasis);
      const bptAfterExitFee = bptIn.sub(bptExitFee);
      const redeemBlock = await ethers.provider.getBlock('latest');
      const redeemTimestamp = BigNumber.from(redeemBlock.timestamp.toString());
      const duration = redeemTimestamp.sub(depositTimeStamp);
      const decayedBPTAfterExitFee = decayFactor
        .pow(duration)
        .mul(bptAfterExitFee)
        .div(feeBasis.pow(duration));
      const bptStreamingFee = bptAfterExitFee.sub(decayedBPTAfterExitFee);

      expect(newProtocolOwnerBalance.sub(oldProtocolOwnerBalance)).to.eq(
        bptExitFee.add(bptStreamingFee),
      );
    });
  });
}
