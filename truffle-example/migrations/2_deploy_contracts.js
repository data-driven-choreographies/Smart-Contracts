var Car = artifacts.require("Car");
var Customer = artifacts.require("Customer");
var MyDriversLicense = artifacts.require("MyDriversLicense");
var Invoice = artifacts.require("Invoice");
var Order = artifacts.require("Order");
var DataObjectStore = artifacts.require("DataObjectStore");
var RentalCarCompany = artifacts.require("RentalCarCompany");
var Staff = artifacts.require("Staff");

module.exports = async function(deployer) {
  await deployer.deploy(MyDriversLicense).then(() => {
    return deployer.deploy(Car).then(() => {
        return deployer.deploy(Invoice).then(() => {
          return deployer.deploy(Order).then(() => {
            return deployer.deploy(DataObjectStore, Order.address, Invoice.address, Car.address).then(() => {
            deployer.deploy(Customer, DataObjectStore.address)
            deployer.deploy(Staff, DataObjectStore.address)
            return deployer.deploy(RentalCarCompany, DataObjectStore.address)
          })
        })
      })
    })
  })
};
