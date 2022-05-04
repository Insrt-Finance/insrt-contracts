import {
  IERC20,
  InsrtTokenMock,
  InsrtTokenMock__factory,
  StakedInsrtTokenMock,
  StakedInsrtTokenMock__factory,
} from '../../typechain-types';
import { describeBehaviorOfERC4626 } from '@solidstate/spec';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers } from 'hardhat';
import { BigNumber } from 'ethers';

describe('StakedInsrtToken', () => {
  let instance: StakedInsrtTokenMock;
  let insrtToken: InsrtTokenMock;
  let deployer: SignerWithAddress;

  const name: string = 'Staked INSRT';
  const symbol: string = 'xINSRT';
  const decimals: BigNumber = BigNumber.from('18');

  beforeEach(async () => {
    [deployer] = await ethers.getSigners();

    insrtToken = await new InsrtTokenMock__factory(deployer).deploy(
      deployer.address,
    );

    instance = await new StakedInsrtTokenMock__factory(deployer).deploy(
      insrtToken.address,
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
        insrtToken.address,
      ) as Promise<IERC20>,
    mintAsset: async (recipient, amount) =>
      await insrtToken['__mint(address,uint256)'](recipient, amount),
    name,
    symbol,
    decimals,
    supply: ethers.constants.Zero,
  });
});
