const Migrations = artifacts.require("Migrations");
const ItemManager = artifacts.require("ItemManager");
module.exports = function (deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(ItemManager);
};
