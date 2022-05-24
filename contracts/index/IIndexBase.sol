// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IERC20Metadata } from '@solidstate/contracts/token/ERC20/metadata/IERC20Metadata.sol';
import { IERC4626 } from '@solidstate/contracts/token/ERC4626/IERC4626.sol';

interface IIndexBase is IERC4626, IERC20Metadata {}
