contract DataObjectOne {
    mapping (uint64 => uint32) _first_attribute;
    mapping (uint64 => uint32) _second_attribute;

    function setFirstAttribute(uint64 instanceId, uint32 value) public {
        _first_attribute[instanceId] = value;
    }

    function getFirstAttribute(uint64 instanceId) public view returns(uint32) {
        return _first_attribute[instanceId];
    }

    function setSecondAttribute(uint64 instanceId, uint32 value) public {
        _second_attribute[instanceId] = value;
    }

    function getSecondAttribute(uint64 instanceId) public view returns(uint32) {
        return _second_attribute[instanceId];
    }
}

contract FirstParticipant {
    bool[3] _executions  = [false];

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

    function firstTask(uint64 instanceId, uint32 value) public executeOnce(0) {
        require(value > 0);
        DataObjectOne _do = DataObjectOne(_store.getDataObject("Data Object One"));
        _do.setFirstAttribute(instanceId, value);
    }
}

contract SecondParticipant {
    bool[3] _executions  = [false];

    // Dependencies
    DataObjectStore _store;

    constructor(DataObjectStore store) public {
        _store = store;
    }

    function getLatestInstanceId() public view returns(uint64) {
        return _store.getLatestInstanceId();
    }

    modifier executeOnce (uint8 tasknumber) {
        require(!_executions[tasknumber], "Function can only be executed one");
        _;
    }

    function secondTask(uint64 instanceId, uint32 value) public executeOnce(0) {
        require(value > 0);
        DataObjectOne _do = DataObjectOne(_store.getDataObject("Data Object One"));
        require(_do.getFirstAttribute(instanceId) > 0);
        _do.setSecondAttribute(instanceId, value);
    }
}

contract DataObjectStore {
    uint64 instanceId = 0;
    mapping (uint64 => mapping (string => address)) importReferences;
    mapping (uint64 => mapping (string => uint64)) importInstanceIds;
    mapping (string => address) dataObjects;

    struct ImportInstance {
        uint64 instanceId;
        address instanceReference;
    }

    constructor(DataObjectOne dataObject) public {
        dataObjects["Data Object One"] = address(dataObject);
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
