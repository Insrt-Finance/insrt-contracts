// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ERC20MetadataInternal } from '@solidstate/contracts/token/ERC20/metadata/ERC20MetadataInternal.sol';
import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';
import { ERC4626BaseInternal } from '@solidstate/contracts/token/ERC4626/base/ERC4626BaseInternal.sol';
import { UintUtils } from '@solidstate/contracts/utils/UintUtils.sol';

import { IndexStorage } from './IndexStorage.sol';

/**
 * @title Infra Index internal functions
 * @dev inherited by all Index implementation contracts
 */
abstract contract IndexInternal is ERC4626BaseInternal, ERC20MetadataInternal {
    using UintUtils for uint256;

    address internal immutable BALANCER_VAULT;
    address internal immutable BALANCER_HELPERS;
    uint256 internal constant FEE_BASIS = 10000;

    constructor(address balancerVault, address balancerHelpers) {
        BALANCER_VAULT = balancerVault;
        BALANCER_HELPERS = balancerHelpers;
    }

    function _applyFee(uint16 fee, uint256 amount)
        internal
        pure
        returns (uint256 totalFee, uint256 remainder)
    {
        totalFee = (fee * amount) / FEE_BASIS;
        remainder = amount - totalFee;

        return (totalFee, remainder);
    }

    function _exactFees(
        IERC20[] storage tokens,
        uint16 fee,
        uint256[] memory amounts
    ) internal returns (uint256[] memory remainders) {
        remainders;
        for (uint256 i; i < tokens.length; i++) {
            (uint256 currTotalFee, uint256 currRemainder) = _applyFee(
                fee,
                amounts[i]
            );
            tokens[i].transferFrom(msg.sender, address(this), currTotalFee);
            remainders[i] = currRemainder;
        }
        return remainders;
    }

    /**
     * @inheritdoc ERC20MetadataInternal
     */
    function _name() internal view virtual override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    'Insrt Finance InfraIndex #',
                    IndexStorage.layout().id.toString()
                )
            );
    }

    /**
     * @inheritdoc ERC20MetadataInternal
     */
    function _symbol() internal view virtual override returns (string memory) {
        return
            string(
                abi.encodePacked('IFII-', IndexStorage.layout().id.toString())
            );
    }

    /**
     * @inheritdoc ERC20MetadataInternal
     */
    function _decimals() internal pure virtual override returns (uint8) {
        return 18;
    }

    /**
     * @inheritdoc ERC4626BaseInternal
     */
    function _totalAssets() internal view override returns (uint256) {
        // TODO: check all positions
        return IERC20(_asset()).balanceOf(address(this));
    }
}
