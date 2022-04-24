import {
  IERC20,
  InsertMock,
  InsertMock__factory,
  XInsertMock,
  XInsertMock__factory,
} from '../../typechain-types';
import { describeBehaviorOfERC4626 } from '@solidstate/spec';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers } from 'hardhat';
import { BigNumber } from 'ethers';

describe.only('XInsert', () => {
  let instance: XInsertMock;
  let insertToken: InsertMock;
  let deployer: SignerWithAddress;

  const name: string = 'xInsert';
  const symbol: string = 'xINSRT';
  const decimals: BigNumber = BigNumber.from('18');

  beforeEach(async () => {
    [deployer] = await ethers.getSigners();

    insertToken = await new InsertMock__factory(deployer).deploy(
      deployer.address,
    );

    instance = await new XInsertMock__factory(deployer).deploy(
      insertToken.address,
    );
  });

  describeBehaviorOfERC4626({
    deploy: async () => instance,
    mint: async (recipient, amount) =>
      await instance['__mint(address,uint256)'](recipient, amount),
    burn: async (recipient, amount) =>
      await instance['__burn(address,uint256)'](recipient, amount),
    getAsset: async () =>
      ethers.getContractAt(
        '@solidstate/contracts/token/ERC20/IERC20.sol:IERC20',
        insertToken.address,
      ) as Promise<IERC20>,
    mintAsset: async (recipient, amount) =>
      await insertToken['__mint(address,uint256)'](recipient, amount),
    name,
    symbol,
    decimals,
    supply: ethers.constants.Zero,
  });
});
