const hre = require("hardhat");
const { ethers } = require("hardhat");

async function main() {

  // Select an allowlisted address to mint NFT
  const selectedAddress = "0xe583327E8D32184aA21475f98c76c6900aB40a17";

  // Define wallet that will be used to sign messages
  const walletAddress = '0x46A8E0e3C7597077d69A779574641989e8ed934F'; // owner.address
  const privateKey = '3923addc437cb6ba106a2316682b89e7345b07bba097313ad22cee1a906ac6c9';
  const signer = new ethers.Wallet(privateKey);
  console.log("Wallet used to sign messages: ", signer.address, "\n");

  let messageHash, signature;

  // Check if selected address is in allowlist
  // If yes, sign the wallet's address
  if (selectedAddress) {
    console.log("Address is allowlisted! Minting should be possible.");

    // Compute message hash
    messageHash = ethers.utils.id(selectedAddress);
    console.log("Message Hash: ", messageHash);

    // Sign the message hash
    let messageBytes = ethers.utils.arrayify(messageHash);
    signature = await signer.signMessage(messageBytes);
    console.log("Signature: ", signature, "\n");
  }

  const factory = await hre.ethers.getContractFactory("NFTAllowlist");
  const contract = await factory.deploy();

  await contract.deployed();
  console.log("Contract deployed to: ", contract.address);
  console.log("Contract deployed by (Owner/Signing Wallet): ", walletAddress, "\n");

  recover = await contract.recoverSigner(messageHash, signature);
  console.log("Message was signed by: ", recover);

  let txn;
  txn = await contract.connect(selectedAddress).claimAirdrop(2, messageHash, signature);
  await txn.wait();
  console.log("NFTs minted successfully!");

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });