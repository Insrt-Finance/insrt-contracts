import { ethers } from 'hardhat';
import { BigNumber, BigNumberish, ContractTransaction } from 'ethers';
import { describeBehaviorOfProxy, ProxyBehaviorArgs } from '@solidstate/spec';
import {
  describeBehaviorOfIndexBase,
  IndexBaseBehaviorArgs,
} from './IndexBase.behavior';

import { IIndex } from '../../typechain-types';

export interface IndexProxyBehaviorArgs
  extends ProxyBehaviorArgs,
    IndexBaseBehaviorArgs {}

export function describeBehaviorOfIndexProxy(
  deploy: () => Promise<IIndex>,
  args: IndexProxyBehaviorArgs,
) {
  describe('::IndexProxy', () => {
    describeBehaviorOfProxy(deploy, args);

    // TODO: facet behaviors

    describeBehaviorOfIndexBase(deploy, args);
  });
}
