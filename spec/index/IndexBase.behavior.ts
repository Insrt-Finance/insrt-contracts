import { ethers } from 'hardhat';
import { IIndex, IERC20, ERC4626 } from '../../typechain-types';

import { BigNumber, BigNumberish, ContractTransaction } from 'ethers';
import { describeBehaviorOfERC4626 } from '@solidstate/spec';

interface IndexBaseBehaviorArgs {
  deploy: () => Promise<IIndex>;
  getAsset: () => Promise<IERC20>;
  mint: (address: string, amount: BigNumber) => Promise<ContractTransaction>;
  burn: (address: string, amount: BigNumber) => Promise<ContractTransaction>;
  mintAsset: (
    address: string,
    amount: BigNumber,
  ) => Promise<ContractTransaction>;
  name: string;
  symbol: string;
  decimals: BigNumber;
  supply: BigNumber;
}

export function describeBehaviorOfIndexBase(args: IndexBaseBehaviorArgs) {
  describe('::IndexBase', () => {
    describeBehaviorOfERC4626(
      Object.assign({}, args, {
        deploy: async () => args.deploy() as unknown as ERC4626,
      }), //as unknown as ERC4626BehaviorArgs,
    );
  });
}
