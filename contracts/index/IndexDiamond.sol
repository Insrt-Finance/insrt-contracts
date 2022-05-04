// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { Diamond } from '@solidstate/contracts/proxy/diamond/Diamond.sol';

/**
 * @title Diamond proxy used as centrally controlled Index implementation
 * @dev deployed standalone and passed to IndexManager constructor
 */
contract IndexDiamond is Diamond {

}
