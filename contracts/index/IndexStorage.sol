// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';

library IndexStorage {
    struct UserStreamingFeeData {
        uint256 lastAcquisitionTimestamp;
        uint256 streamingFeeAccumulated;
    }
    struct Layout {
        uint256 id;
        bytes32 poolId;
        IERC20[] tokens;
        mapping(address => UserStreamingFeeData) userStreamingFeeData;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('insrt.contracts.storage.Index');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
