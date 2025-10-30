const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", await deployer.getAddress());

  // Params (can be customized via env if desired)
  const tokenName = process.env.TOKEN_NAME || "Test Token";
  const tokenSymbol = process.env.TOKEN_SYMBOL || "TT";

  // 1) Deploy TestToken
  const Token = await ethers.getContractFactory("TestToken");
  const token = await Token.deploy(tokenName, tokenSymbol);
  await token.waitForDeployment();
  const tokenAddress = await token.getAddress();
  console.log("TestToken deployed at:", tokenAddress);

  // 2) Deploy ROIStaking with token address
  const Staking = await ethers.getContractFactory("ROIStaking");
  const staking = await Staking.deploy(tokenAddress);
  await staking.waitForDeployment();
  const stakingAddress = await staking.getAddress();
  console.log("ROIStaking deployed at:", stakingAddress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });


