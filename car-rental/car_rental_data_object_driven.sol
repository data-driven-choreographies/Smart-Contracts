pragma solidity ^0.5;

// Participants

contract Customer {
    bool[3] _executions  = [false, false, false];

    // Dependencies
    DataObjectStore _store;

    constructor(DataObjectStore store) public {
        _store = store;
    }

    function getLatestInstanceId() public view returns(uint64) {
        return _store.getLatestInstanceId();
    }

    function createInstance() public returns(uint64) {
        return _store.createInstance();
    }

    modifier executeOnce (uint8 tasknumber) {
        require(!_executions[tasknumber], "Function can only be executed one");
        _;
    }

    // Tasks
    function requestCar(uint64 instanceId, string memory carType, uint32 startDate, uint32 endDate) public  {
        // postcondition
        require(startDate < endDate, "Postcondition not fulfilled");

        // get stored objects for instance
        Order order = Order(_store.getDataObject("Order"));

        // set state
        order.setStartDate(instanceId, startDate);
        order.setEndDate(instanceId, endDate);
        order.setCarType(instanceId, carType);
    }

    function proveDriversLicense(uint64 instanceId, address driversLicenseReference, uint64 referenceId) public  {
        // get stored objects for instance
        Order order = Order(_store.getDataObject("Order"));

        require(order.getAccepted(instanceId) == true, "Precondition not fulfilled");

        DriversLicense driversLicense = DriversLicense(driversLicenseReference);

        require(driversLicense.getValidUntil(referenceId) > driversLicense.getBirthDateYear(referenceId), "Postcondition not fulfilled");

        _store.importDataObject(instanceId, "DriversLicense", address(driversLicense), referenceId);
    }

    function provePaymentOfInvoice(uint64 instanceId, uint32 transfer_amount) public {
        // get stored objects for instance
        Invoice invoice = Invoice(_store.getDataObject("Invoice"));

        //Precondition
        require(invoice.getPrice(instanceId) > 0, "Precondition not fulfilled");

        // Postcondition
        require(invoice.getPrice(instanceId) == transfer_amount, "Postcondition not fulfilled");

        invoice.setTransferAmount(instanceId, transfer_amount);
    }

}

contract RentalCarCompany {
    bool[5] _executions  = [false, false, false, false, false];

    // Dependencies
    DataObjectStore _store;

    constructor(DataObjectStore store) public {
        _store = store;
    }

    modifier executeOnce (uint8 tasknumber) {
        require(!_executions[tasknumber], "Function can only be executed one");
        _executions[tasknumber] = true;
        _;
    }

    function getLatestInstanceId() public view returns(uint64) {
        return _store.getLatestInstanceId();
    }

     // Tasks
    function rejectOrder(uint64 instanceId, bool rejected) public  {
        // get stored objects for instance
        Order order = Order(_store.getDataObject("Order"));

        // precondition
        require(order.getStartDate(instanceId) < order.getEndDate(instanceId), "Precondition not fulfilled");
        require(!(order.getAccepted(instanceId) == true), "Precondition not fulfilled");

        // postcondition
        require(rejected == true, "Postcondition not fulfilled");

        // set state
        order.setRejected(instanceId, rejected);
    }

    function acceptOrder(uint64 instanceId, bool accepted) public  {
        // get stored objects for instance
        Order order = Order(_store.getDataObject("Order"));

        // precondition
        require(order.getStartDate(instanceId) < order.getEndDate(instanceId), "Precondition not fulfilled");
        require(!(order.getRejected(instanceId) == true), "Precondition not fulfilled");

        // postcondition
        require(accepted == true, "Postcondition not fulfilled");

        // set state
        order.setAccepted(instanceId, accepted);
    }

    function sendInvoice(uint64 instanceId, uint32 price) public  {
        // precondition
        DriversLicense driversLicense = DriversLicense(_store.getImportedDataObject(instanceId, "DriversLicense"));
        uint64 driversLicenseInstance = _store.getImportedDataObjectInstance(instanceId, "DriversLicense");
        require(driversLicense.getValidUntil(driversLicenseInstance) > driversLicense.getBirthDateYear(driversLicenseInstance), "Precondition not fulfilled");

        // postcondition
        require(price > 0, "Postcondition not fulfilled");

        // get stored objects for instance
        Invoice invoice = Invoice(_store.getDataObject("Invoice"));

        // set state
        invoice.setPrice(instanceId, price);
    }

    function requestCarPreparation(uint64 instanceId, uint16 id) public  {
        // precondition
        DriversLicense driversLicense = DriversLicense(_store.getImportedDataObject(instanceId, "DriversLicense"));
        uint64 driversLicenseInstance = _store.getImportedDataObjectInstance(instanceId, "DriversLicense");
        require(driversLicense.getValidUntil(driversLicenseInstance) > driversLicense.getBirthDateYear(driversLicenseInstance), "Precondition not fulfilled");


        // postcondition
        require(id > 0, "Postcondition not fulfilled"); // No condition

        // get stored objects for instance
        Car car = Car(_store.getDataObject("Car"));

        // set state
        car.setId(instanceId, id);
        // set flow control
        car.setRequestCarPreparationDone(instanceId, true);
    }

    function handOverKeys(uint64 instanceId, uint32 keyId) public  {
        // get stored objects for instance
        Car car = Car(_store.getDataObject("Car"));
        Order order = Order(_store.getDataObject("Order"));

        require(car.getId(instanceId) == car.getPreparedCarId(instanceId), "Precondition not fulfilled");
        // public CHECK

        require(keyId > 0, "Postcondition not fulfilled");

        order.setKeyId(instanceId, keyId);
    }
}


contract Staff {
    bool[1]  _executions  = [false];

    // Dependencies
    DataObjectStore _store;

    constructor(DataObjectStore store) public {
        _store = store;
    }

    modifier executeOnce (uint8 tasknumber) {
        require(!_executions[tasknumber], "Function can only be executed one");
        _executions[tasknumber] = true;
        _;
    }

    function getLatestInstanceId() public view returns(uint64) {
        return _store.getLatestInstanceId();
    }


    // Tasks
    function confirmCarPreparation(uint64 instanceId, uint16 preparedCarId) public  {
        // get stored objects for instance
        Car car = Car(_store.getDataObject("Car"));

        require(car.getRequestCarPreparationDone(instanceId) == true, "Precondition not fulfilled");

        require(preparedCarId == car.getId(instanceId), "Postcondition not fulfilled");

        car.setPreparedCarId(instanceId, preparedCarId);
    }
}


// Data Objects

contract DataObjectStore {
    uint64 instanceId = 0;
    mapping (uint64 => mapping (string => address)) importReferences;
    mapping (uint64 => mapping (string => uint64)) importInstanceIds;
    mapping (string => address) dataObjects;

    struct ImportInstance {
        uint64 instanceId;
        address instanceReference;
    }

    constructor(Order order, Invoice invoice, Car car) public {
        dataObjects["Invoice"] = address(invoice);
        dataObjects["Order"] = address(order);
        dataObjects["Car"] = address(car);
    }

    function createInstance() public returns(uint64) {
        return instanceId++;
    }

    function getLatestInstanceId() public view returns(uint64) {
        return instanceId;
    }

    function getImportedDataObject(uint64 id, string memory identifier) public view returns(address) {
        return importReferences[id][identifier];
    }

    function getImportedDataObjectInstance(uint64 id, string memory identifier) public view returns(uint64) {
        return importInstanceIds[id][identifier];
    }

    function getDataObject(string memory identifier) public view returns(address) {
        return dataObjects[identifier];
    }

    function importDataObject(uint64 id, string memory identifier, address dataObject, uint64 referenceId) public {
        importReferences[id][identifier] = dataObject;
        importInstanceIds[id][identifier] = referenceId;
    }
}

interface DriversLicense {
    function getBirthDateYear(uint64 instanceId) external view returns (uint16);
    function getValidUntil(uint64 instanceId) external view returns (uint32);
    function getAuthorizedCarTypes(uint64 instanceId) external view returns (string memory);
}

contract MyDriversLicense is DriversLicense {
    mapping (uint64 => uint16) _birthDateYear;
    mapping (uint64 => uint32) _validUntil;
    mapping (uint64 => string) _authorizedCarTypes;

    constructor() public {
        _birthDateYear[50] = 1990;
        _validUntil[50] = 2030;
        _authorizedCarTypes[50] = "B";
    }

    function getBirthDateYear(uint64 instanceId) public view returns(uint16) {
        return _birthDateYear[instanceId];
    }

    function getValidUntil(uint64 instanceId) public view returns(uint32) {
        return _validUntil[instanceId];
    }

    function getAuthorizedCarTypes(uint64 instanceId) public view returns(string memory) {
        return _authorizedCarTypes[instanceId];
    }
}


contract Order {
    mapping (uint64 => string) _carType;
    mapping (uint64 => uint32) _startDate;
    mapping (uint64 => uint32) _endDate;
    mapping (uint64 => uint32) _keyId;
    mapping (uint64 => bool) _rejected;
    mapping (uint64 => bool) _accepted;

    function setRejected(uint64 instanceId, bool value) public {
        _rejected[instanceId] = value;
    }

    function getRejected(uint64 instanceId) public view returns(bool) {
        return _rejected[instanceId];
    }

    function setAccepted(uint64 instanceId, bool value) public {
        _accepted[instanceId] = value;
    }

    function getAccepted(uint64 instanceId) public view returns(bool) {
        return _accepted[instanceId];
    }

    function setCarType(uint64 instanceId, string memory value) public {
        _carType[instanceId] = value;
    }

    function getCarType(uint64 instanceId) public view returns(string memory) {
        return _carType[instanceId];
    }

    function setStartDate(uint64 instanceId, uint32 value) public {
        _startDate[instanceId] = value;
    }

    function getStartDate(uint64 instanceId) public view returns(uint32) {
        return _startDate[instanceId];
    }

    function setEndDate(uint64 instanceId, uint32 value) public {
        _endDate[instanceId] = value;
    }

    function getEndDate(uint64 instanceId) public view returns(uint32) {
        return _endDate[instanceId];
    }

    function setKeyId(uint64 instanceId, uint32 value) public {
        _keyId[instanceId] = value;
    }

    function getKeyId(uint64 instanceId) public view returns(uint32) {
        return _keyId[instanceId];
    }
}


contract Invoice {
    mapping (uint64 => uint32) _price;
    mapping (uint64 => uint32) _transfer_amount;

    function setPrice(uint64 instanceId, uint32 value) public {
        _price[instanceId] = value;
    }

    function getPrice(uint64 instanceId) public view returns(uint32) {
        return _price[instanceId];
    }

    function setTransferAmount(uint64 instanceId, uint32 value) public {
        _transfer_amount[instanceId] = value;
    }

    function getTransferAmount(uint64 instanceId) public view returns(uint32) {
        return _transfer_amount[instanceId];
    }
}


contract Car {
    mapping (uint64 => uint16) _id;
    mapping (uint64 => uint16) _preparedCarId;
    mapping (uint64 => bool) _requestCarPreparationDone;

    function setId(uint64 instanceId, uint16 value) public {
        _id[instanceId] = value;
    }

    function getId(uint64 instanceId) public view returns(uint16) {
        return _id[instanceId];
    }

    function setPreparedCarId(uint64 instanceId, uint16 value) public {
        _preparedCarId[instanceId] = value;
    }

    function getPreparedCarId(uint64 instanceId) public view returns(uint16) {
        return _preparedCarId[instanceId];
    }

    function setRequestCarPreparationDone(uint64 instanceId, bool value) public {
        _requestCarPreparationDone[instanceId] = value;
    }

    function getRequestCarPreparationDone(uint64 instanceId) public view returns(bool) {
        return _requestCarPreparationDone[instanceId];
    }
}
