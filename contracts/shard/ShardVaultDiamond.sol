// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { SolidStateDiamond } from '@solidstate/contracts/proxy/diamond/SolidStateDiamond.sol';

/**
 * @title Diamond proxy used as centrally controlled ShardVault implementation
 * @dev deployed standalone and passed to ShardVaultManager constructor
 */
contract ShardVaultDiamond is SolidStateDiamond {

}
