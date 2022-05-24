import { ethers } from 'hardhat';
import { BigNumber, BigNumberish, ContractTransaction } from 'ethers';
import { describeBehaviorOfProxy } from '@solidstate/spec';
import { describeBehaviorOfIndexBase } from './IndexBase.behavior';

import { IERC20, IIndex } from '../../typechain-types';

interface IndexProxyBehaviorArgs {
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
  implementationFunction: string;
  implementationFunctionArgs: any[];
}

export function describeBehaviorOfIndexProxy(args: IndexProxyBehaviorArgs) {
  describe('::IndexProxy', () => {
    describeBehaviorOfProxy(args);

    // TODO: facet behaviors

    describeBehaviorOfIndexBase(args);
  });
}
