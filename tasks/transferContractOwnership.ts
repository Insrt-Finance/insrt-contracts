import { task, types } from 'hardhat/config';

task('transferContractOwnership', 'transfers contract ownership')
  .addParam('contract', 'the address of the contract', '', types.string)
  .addParam('newowner', 'new owner address', '', types.string)
  .setAction(async ({ contract, newowner }, hre) => {
    const newOwner = hre.ethers.utils.getAddress(newowner);
    const contractAddress = hre.ethers.utils.getAddress(contract);
    const ownableContract = await hre.ethers.getContractAt(
      'Ownable',
      contractAddress,
    );

    console.log(
      `\n\nAttempting to transfer ownership of ${contractAddress} to ${newOwner} ...\n\n`,
    );

    try {
      const tx = await ownableContract['transferOwnership(address)'](newOwner);
      await tx.wait(1);

      console.log(
        `\n\nSuccessfully transferred ownership of of ${contractAddress} to ${newOwner}\n\n`,
      );
    } catch (err) {
      console.log(
        `\n\nFailed to transfer ownership of ${contractAddress} to ${newOwner} ...\n\n`,
      );
      console.log(`Error occurred: `, err);
    }
  });
