import hre, { ethers } from 'hardhat';
import { IShardVault } from '../../typechain-types';

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

export interface ShardVaultViewBehaviorArgs {}

export function describeBehaviorOfShardVaultView(
  deploy: () => Promise<IShardVault>,
  args: ShardVaultViewBehaviorArgs,
  skips?: string[],
) {}
