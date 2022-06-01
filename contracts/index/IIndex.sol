// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IProxy } from '@solidstate/contracts/proxy/IProxy.sol';

import { IIndexBase } from './IIndexBase.sol';

interface IIndex is IProxy, IIndexBase {}
