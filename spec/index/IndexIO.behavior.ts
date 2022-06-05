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
  const BALANCER_VAULT = '0xBA12222222228d8Ba445958a75a0704d566BF2C8'; //arbitrum

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
      'BPT Balance Supply: ',
      await investmentPoolToken['totalSupply()'](),
    );
    console.log(
      'Index Balance of BPT: ',
      await investmentPoolToken['balanceOf(address)'](instance.address),
    );
    console.log(
      'User balance of Insrt-Index: ',
      await instance
        .connect(depositor)
        ['balanceOf(address)'](depositor.address),
    );
  });

  describe('#userDepositExactInForAnyOut(uint256[],uint256)', () => {
    it('perform join test', async () => {
      console.log(
        'Total BPT supply: ',
        await investmentPoolToken['totalSupply()'](),
      );
      console.log(
        'Approved relayer: ',
        await IVault__factory.connect(BALANCER_VAULT, depositor)[
          'hasApprovedRelayer(address,address)'
        ](depositor.address, instance.address),
      );
      await instance
        .connect(depositor)
        ['userDepositExactInForAnyOut(uint256[],uint256)'](amountsIn, 0);

      await instance['balanceOf(address)'](depositor.address);
    });
  });
}
