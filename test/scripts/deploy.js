const hre = require("hardhat");

async function main() {
  // const ContributorsTreasure = await hre.ethers.getContractFactory("ContributorsTreasure");
  // const contributorsTreasure = await ContributorsTreasure.deploy();
  // const EcosystemTreasure = await hre.ethers.getContractFactory("EcosystemTreasure");
  // const ecosystemTreasure = await EcosystemTreasure.deploy();
  // const HoldersYieldTreasure = await hre.ethers.getContractFactory("HoldersYieldTreasure");
  // const holdersYieldTreasure = await HoldersYieldTreasure.deploy();
  // const HoldersPoolTreasure = await hre.ethers.getContractFactory("HoldersPoolTreasure");
  // const holdersPoolTreasure = await HoldersPoolTreasure.deploy();
  // const Router = await hre.ethers.getContractFactory("Router");
  // const router = await Router.deploy();
  const Factory = await hre.ethers.getContractFactory("Factory");
  const factory = await Factory.deploy();

  // await contributorsTreasure.deployed();
  // await ecosystemTreasure.deployed();
  // await holdersYieldTreasure.deployed();
  // await holdersPoolTreasure.deployed();
  // await router.deployed();
  await factory.deployed();

  // console.log(`contributorsTreasure deployed to ${contributorsTreasure.address}`);
  // console.log(`ecosystemTreasure deployed to ${ecosystemTreasure.address}`);
  // console.log(`HoldersYieldTreasure deployed to ${holdersYieldTreasure.address}`);
  // console.log(`HoldersPoolTreasure deployed to ${holdersPoolTreasure.address}`);
  // console.log(`Router deployed to ${router.address}`);
  console.log(`Factory deployed to ${factory.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
