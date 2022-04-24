// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

import { XInsert } from '../token/XInsert.sol';
import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';

contract XInsertMock is XInsert {
    event AfterDepositCheck(
        address receiver,
        uint256 assetAmount,
        uint256 shareAmount
    );
    event BeforeWithdrawCheck(
        address owner,
        uint256 assetAmount,
        uint256 shareAmount
    );

    constructor(address insertToken) XInsert(insertToken) {}

    function _afterDeposit(
        address receiver,
        uint256 assetAmount,
        uint256 shareAmount
    ) internal override {
        super._afterDeposit(receiver, assetAmount, shareAmount);
        emit AfterDepositCheck(receiver, assetAmount, shareAmount);
    }

    function _beforeWithdraw(
        address owner,
        uint256 assetAmount,
        uint256 shareAmount
    ) internal override {
        super._beforeWithdraw(owner, assetAmount, shareAmount);
        emit BeforeWithdrawCheck(owner, assetAmount, shareAmount);
    }

    function __mint(address recipient, uint256 amount) external {
        _mint(recipient, amount);
    }

    function __burn(address recipient, uint256 amount) external {
        _burn(recipient, amount);
    }

    function __mint4626(uint256 shareAmount, address receiver)
        external
        returns (uint256)
    {
        return _mint(shareAmount, receiver);
    }

    function _getAsset() external view returns (IERC20) {
        return IERC20(_asset());
    }
}
