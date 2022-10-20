import hre, { ethers } from 'hardhat';
import { IShardCollection, IShardVault } from '../../typechain-types';
import {
  describeBehaviorOfShardVaultIO,
  ShardVaultIOBehaviorArgs,
} from './ShardVaultIO.behavior';
import {
  describeBehaviorOfShardVaultView,
  ShardVaultViewBehaviorArgs,
} from './ShardVaultView.behavior';

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

export interface ShardVaultProxyBehaviorArgs
  extends ShardVaultIOBehaviorArgs,
    ShardVaultViewBehaviorArgs {}

export function describeBehaviorOfShardVaultProxy(
  deploy: () => Promise<IShardVault>,
  args: ShardVaultProxyBehaviorArgs,
  skips?: string[],
) {
  describe('::ShardVaultProxy', () => {
    describeBehaviorOfShardVaultIO(deploy, args, skips);
    describeBehaviorOfShardVaultView(deploy, args, skips);
  });
}
