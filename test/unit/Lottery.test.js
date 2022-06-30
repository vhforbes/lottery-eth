const { assert, expect } = require("chai")
const { getNamedAccounts, deployments, ethers } = require("hardhat")

describe("Lottery", async () => {
    let deployer
    let Lottery
    const entranceFee = ethers.utils.parseEther("1")

    beforeEach(async () => {
        deployer = (await getNamedAccounts()).deployer
        console.log(deployer)
        await deployments.fixture()
        Lottery = await ethers.getContract("Lottery", deployer)
    })

    describe("constructor", async () => {
        it("Set the entrance fee", async () => {
            const response = await Lottery.getEntranceFee()
            assert.equal(response.toString(), entranceFee.toString())
        })
    })

    // Fails if not enough
    // Add to array if enough

    describe("Enter Lottery", async () => {
        it("Must enter 1eth to participate", async () => {
            await expect(Lottery.enterLoterry()).to.be.revertedWith("Lottery__NotEnoughValue")
        })

        it("Populates the participants array", async () => {
            await Lottery.enterLoterry({ value: entranceFee })
            const response = await Lottery.getParticipants("0")
            assert.equal(response, deployer)
        })
    })
})
