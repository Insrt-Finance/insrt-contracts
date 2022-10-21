import hre, { ethers } from 'hardhat';
import {
  IShardVault,
  ShardCollection,
  ShardCollection__factory,
} from '../../typechain-types';

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { BigNumber } from 'ethers';
import { expect } from 'chai';

export interface ShardVaultViewBehaviorArgs {}

function formatTokenId(internalId: BigNumber, address: string): BigNumber {
  let tokenId: BigNumber;
  tokenId = BigNumber.from(address).shl(96).add(internalId);
  return tokenId;
}

export function describeBehaviorOfShardVaultView(
  deploy: () => Promise<IShardVault>,
  args: ShardVaultViewBehaviorArgs,
  skips?: string[],
) {
  let depositor: SignerWithAddress;
  let instance: IShardVault;
  let shardCollection: ShardCollection;

  before(async () => {
    [depositor] = await ethers.getSigners();
  });

  beforeEach(async () => {
    instance = await deploy();
    shardCollection = ShardCollection__factory.connect(
      await instance['shardCollection()'](),
      depositor,
    );
  });

  describe('#totalSupply()', () => {
    it('TODO');
  });

  describe('#maxSupply()', () => {
    it('TODO');
  });

  describe('#shardCollection()', () => {
    it('TODO');
  });

  describe('#count()', () => {
    it('TODO');
  });

  describe('#formatTokenId(uint256)', () => {
    it('generates a unique token id using the vault address as a seed', async () => {
      const tokenIds = [];
      const testIds = [];
      for (let i = 0; i < 10; i++) {
        tokenIds.push(await instance.formatTokenId(i));
        testIds.push(
          formatTokenId(BigNumber.from(i.toString()), instance.address),
        );
        expect(tokenIds[i]).to.eq(testIds[i]);
      }
    });
    it('generates incrementally increasing tokenIds', async () => {
      const initialId = await instance['formatTokenId(uint256)'](
        ethers.constants.One,
      );
      const finalId = await instance['formatTokenId(uint256)'](
        BigNumber.from('101'),
      );

      expect(finalId.sub(initialId)).to.eq(BigNumber.from('100'));
    });
  });
  describe('#parseTokenId(uint256)', () => {
    it('returns the seeded vault address', async () => {
      const tokenId = await instance['formatTokenId(uint256)'](
        ethers.constants.One,
      );
      const [address] = await instance['parseTokenId(uint256)'](tokenId);

      expect(address).to.eq(instance.address);
    });

    it('returns the internal id used to generate the tokenId', async () => {
      const maxUint96 = ethers.constants.Two.pow(BigNumber.from('96')).sub(
        ethers.constants.One,
      );
      const tokenId = await instance['formatTokenId(uint256)'](maxUint96);
      const [, internalId] = await instance['parseTokenId(uint256)'](tokenId);

      expect(internalId).to.eq(maxUint96);
    });

    it('should fail when input is larger than maxUint96', async () => {
      const maxUint96 = ethers.constants.Two.pow(BigNumber.from('96')).sub(
        ethers.constants.One,
      );
      const tokenId = await instance['formatTokenId(uint256)'](
        maxUint96.add(ethers.constants.One),
      );
      const [, internalId] = await instance['parseTokenId(uint256)'](tokenId);

      expect(internalId).to.not.eq(maxUint96.add(ethers.constants.One));
      expect(internalId).to.eq(ethers.constants.Zero);
    });
  });
}
