// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IProxy } from '@solidstate/contracts/proxy/IProxy.sol';

import { IIndexBase } from './IIndexBase.sol';
import { IIndexInternal } from './IIndexInternal.sol';
import { IIndexIO } from './IIndexIO.sol';
import { IIndexView } from './IIndexView.sol';
import { IIndexSettings } from './IIndexSettings.sol';

interface IIndex is
    IProxy,
    IIndexBase,
    IIndexIO,
    IIndexView,
    IIndexSettings,
    IIndexInternal
{}
