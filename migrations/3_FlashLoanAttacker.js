const FlashLoanAttacker = artifacts.require("FlashLoanAttacker");

module.exports = function (deployer) {
  deployer.deploy(FlashLoanAttacker);
};
