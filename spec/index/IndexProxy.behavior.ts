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
import {
  describeBehaviorOfIndexView,
  IndexViewBehaviorArgs,
} from './IndexView.behavior';

import { IIndex } from '../../typechain-types';

export interface IndexProxyBehaviorArgs
  extends ProxyBehaviorArgs,
    IndexBaseBehaviorArgs,
    IndexIOBehaviorArgs {}

export function describeBehaviorOfIndexProxy(
  deploy: () => Promise<IIndex>,
  args: IndexProxyBehaviorArgs,
  skips?: string[],
) {
  describe('::IndexProxy', () => {
    describeBehaviorOfProxy(deploy, args, skips);
    describeBehaviorOfIndexBase(deploy, args, skips);
    describeBehaviorOfIndexIO(deploy, args, skips);
    describeBehaviorOfIndexView(deploy, args, skips);
  });
}
