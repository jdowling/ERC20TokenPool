var ERC20TokenPool = artifacts.require("./ERC20TokenPool.sol");

module.exports = function(deployer) {
  deployer.deploy(ERC20TokenPool);
};
