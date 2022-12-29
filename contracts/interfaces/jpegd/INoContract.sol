// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title JPEG'd NoContract interface
 * @dev used for whitelisting contracts in testing
 */
interface INoContract {
    function setContractWhitelisted(address addr, bool isWhitelisted) external;
}
