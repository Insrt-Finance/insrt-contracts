// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title interface needed for Index Facet events
 */
interface IIndexInternal {
    event StreamingFeePaid(address payer, uint256 amount);
    event ExitFeePaid(address payer, uint256 amount);
}
