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
  describeBehaviorOfShardVaultAdmin,
  ShardVaultAdminBehaviorArgs,
} from './ShardVaultAdmin.behavior';

export interface ShardVaultProxyBehaviorArgs
  extends ShardVaultIOBehaviorArgs,
    ShardVaultViewBehaviorArgs,
    ShardVaultAdminBehaviorArgs {}

export function describeBehaviorOfShardVaultProxy(
  deploy: () => Promise<IShardVault>,
  secondDeploy: () => Promise<IShardVault>,
  pethDeploy: () => Promise<IShardVault>,
  args: ShardVaultProxyBehaviorArgs,
  skips?: string[],
) {
  describe('::ShardVaultProxy', () => {
    describeBehaviorOfShardVaultIO(
      deploy,
      secondDeploy,
      pethDeploy,
      args,
      skips,
    );
    describeBehaviorOfShardVaultView(deploy, pethDeploy, args, skips);
    describeBehaviorOfShardVaultAdmin(
      deploy,
      secondDeploy,
      pethDeploy,
      args,
      skips,
    );
  });
}
