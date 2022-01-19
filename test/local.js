const Web3 = require("web3");

const Setup = artifacts.require("Setup");
const FlashLoanAttacker = artifacts.require("FlashLoanAttacker");

let web3 = new Web3("http://localhost:7545");

describe("Test", () => {
  it("Test", async () => {
    let setupContract = await Setup.deployed();
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
