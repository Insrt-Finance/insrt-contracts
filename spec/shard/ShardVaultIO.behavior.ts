import hre, { ethers } from 'hardhat';
import { IShardVault } from '../../typechain-types';

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

export interface ShardVaultIOBehaviorArgs {}

export function describeBehaviorOfShardVaultIO(
  deploy: () => Promise<IShardVault>,
  args: ShardVaultIOBehaviorArgs,
  skips?: string[],
) {}
