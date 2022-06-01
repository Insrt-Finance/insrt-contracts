import { ethers } from 'hardhat';
import { IIndexBase } from '../../typechain-types';

import { BigNumber, BigNumberish, ContractTransaction } from 'ethers';
import {
  describeBehaviorOfSolidStateERC4626,
  SolidStateERC4626BehaviorArgs,
} from '@solidstate/spec';

export interface IndexBaseBehaviorArgs extends SolidStateERC4626BehaviorArgs {}

export function describeBehaviorOfIndexBase(
  deploy: () => Promise<IIndexBase>,
  args: IndexBaseBehaviorArgs,
) {
  describe('::IndexBase', () => {
    // TODO: fix spec tests and uncomment
    // describeBehaviorOfERC4626(
    //   Object.assign({}, args, {
    //     deploy: async () => args.deploy() as unknown as ERC4626,
    //   }), //as unknown as ERC4626BehaviorArgs,
    // );
  });
}
