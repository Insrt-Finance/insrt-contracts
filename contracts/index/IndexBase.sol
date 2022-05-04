// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ERC4626 } from '@solidstate/contracts/token/ERC4626/ERC4626.sol';

import { IndexInternal } from './IndexInternal.sol';

/**
 * @title Infra Index base functions
 * @dev deployed standalone and referenced by IndexProxy
 */
contract IndexBase is ERC4626, IndexInternal {

}
