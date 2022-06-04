import { ethers } from 'hardhat';
import { BigNumber, BigNumberish, ContractTransaction } from 'ethers';
import { describeBehaviorOfProxy, ProxyBehaviorArgs } from '@solidstate/spec';
import {
  describeBehaviorOfIndexBase,
  IndexBaseBehaviorArgs,
} from './IndexBase.behavior';
import {
  describeBehaviorOfIndexIO,
  IndexIOBehaviorArgs,
} from './IndexIO.behavior';

import { IIndex } from '../../typechain-types';

export interface IndexProxyBehaviorArgs
  extends ProxyBehaviorArgs,
    IndexBaseBehaviorArgs,
    IndexIOBehaviorArgs {}

export function describeBehaviorOfIndexProxy(
  deploy: () => Promise<IIndex>,
  args: IndexProxyBehaviorArgs,
) {
  describe('::IndexProxy', () => {
    describeBehaviorOfProxy(deploy, args);

    // TODO: facet behaviors

    describeBehaviorOfIndexBase(deploy, args);
    describeBehaviorOfIndexIO(deploy, {
      tokens: args.tokens,
      weights: args.weights,
    });
  });
}
