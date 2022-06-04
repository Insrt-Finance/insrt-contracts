import { ethers } from 'hardhat';
import {
  IIndex,
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
  const assets: SolidStateERC20Mock[] = [];
  const amountsIn: BigNumber[] = [];

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
    //await instance.connect(depositor)['userDepositExactInForAnyOut(uint256[],uint256)'](amountsIn, BigNumber.from('1'));
    // InvestmentPool apparently does not require initialization. That being said, the error appearing
    // indicates that there are 0 balances of underlying tokens in the pool. How do balances increase
    // if all joinKinds reject them due to 0 balance?
  });

  describe('correct initialization', () => {
    it('correct initiliazation', async () => {
      console.log(amountsIn);
      console.log(await instance['balanceOf(address)'](depositor.address));
      console.log(await instance['totalSupply()']());
      //await instance.connect(depositor).initializePoolByDeposit(amountsIn, ethers.constants.Zero);
      //await instance.connect(depositor).userDepositExactInForAnyOut(amountsIn, 0);
      //await instance.connect(depositor)['queryUserDepositExactInForAnyOut(uint256[],uint256)'](amountsIn, 0);
    });
  });
}
