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
import {
  describeBehaviorOfShardVaultPermissioned,
  ShardVaultPermissionedBehaviorArgs,
} from './ShardVaultPermissioned.behavior';

export interface ShardVaultProxyBehaviorArgs
  extends ShardVaultIOBehaviorArgs,
    ShardVaultViewBehaviorArgs,
    ShardVaultPermissionedBehaviorArgs {}

export function describeBehaviorOfShardVaultProxy(
  deploy: () => Promise<IShardVault>,
  secondDeploy: () => Promise<IShardVault>,
  pethDeploy: () => Promise<IShardVault>,
  args: ShardVaultProxyBehaviorArgs,
  skips?: string[],
) {
  describe('::ShardVaultProxy', () => {
    describeBehaviorOfShardVaultIO(deploy, secondDeploy, args, skips);
    describeBehaviorOfShardVaultView(deploy, pethDeploy, args, skips);
    describeBehaviorOfShardVaultPermissioned(
      deploy,
      secondDeploy,
      pethDeploy,
      args,
      skips,
    );
  });
}
