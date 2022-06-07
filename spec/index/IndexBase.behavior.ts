import { ethers } from 'hardhat';
import { IIndex } from '../../typechain-types';

import { BigNumber, BigNumberish, ContractTransaction } from 'ethers';
import {
  describeBehaviorOfSolidStateERC4626,
  SolidStateERC4626BehaviorArgs,
} from '@solidstate/spec';

export interface IndexBaseBehaviorArgs extends SolidStateERC4626BehaviorArgs {}

export function describeBehaviorOfIndexBase(
  deploy: () => Promise<IIndex>,
  args: IndexBaseBehaviorArgs,
  skips?: string[],
) {
  describe('::IndexBase', () => {
    describeBehaviorOfSolidStateERC4626(deploy, args, skips);
  });
}
