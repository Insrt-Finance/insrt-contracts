// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IIndexManager } from './IIndexManager.sol';
import { IShardVaultManager } from './IShardVaultManager.sol';

interface ICore is IIndexManager, IShardVaultManager {}
