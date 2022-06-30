const { ethers } = require("hardhat")

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const entranceFee = ethers.utils.parseEther("1")

    log("---- Deploying Lottery... ----")
    const Lottery = await deploy("Lottery", {
        from: deployer,
        log: true,
        args: [entranceFee],
    })
}
