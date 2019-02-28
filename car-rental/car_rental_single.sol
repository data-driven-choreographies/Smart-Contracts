pragma solidity ^0.5.1;

contract Choreography {
    bool start = true;
    bool requestCarExecuted = false;
    bool acceptOrderExecuted = false;
    bool rejectOrderExecuted = false;
    bool proveDriversLicenseExecuted = false;
    bool sendInvoiceExecuted = false;
    bool provePaymentOfInvoiceExecuted = false;
    bool requestCarPreparationExecuted = false;
    bool confirmCarPreparationExecuted = false;
    bool handOverKeysExecuted = false;

    uint32 payload_requestCar_startDate;
    uint32 payload_requestCar_endDate;
    string payload_requestCar_carType;
    bool payload_acceptOrder_accepted;
    bool payload_rejectOrder_rejected;
    uint32 payload_proveDriversLicense_birthDateYear;
    uint32 payload_proveDriversLicense_validUntil;
    string payload_proveDriversLicense_authorizedCarType;
    uint32 payload_sendInvoice_price;
    uint32 payload_provePaymentOfInvoice_transferAmount;
    uint32 payload_requestCarPreparation_id;
    uint32 payload_confirmCarPreparation_preparedCarId;
    uint32 payload_handOverKeys_keyId;

    modifier isActive(bool active) {
        require(active);
        _;
    }

    function requestCar(string calldata carType, uint32 startDate, uint32 endDate) external isActive(start) isActive(!requestCarExecuted) {
        requestCarExecuted = true;
        payload_requestCar_carType = carType;
        payload_requestCar_startDate = startDate;
        payload_requestCar_endDate = endDate;
    }

    function acceptOrder(bool accepted) external isActive(requestCarExecuted) isActive(!acceptOrderExecuted) isActive(!rejectOrderExecuted) {
        acceptOrderExecuted = true;
        payload_acceptOrder_accepted = accepted;
    }

    function rejectOrder(bool rejected) external isActive(requestCarExecuted) isActive(!rejectOrderExecuted) isActive(!acceptOrderExecuted) {
        rejectOrderExecuted = true;
        payload_rejectOrder_rejected = rejected;
    }

    function proveDriversLicense(uint32 birthDateYear, uint32 validUntil, string calldata authorizedCarType) external isActive(acceptOrderExecuted) isActive(!proveDriversLicenseExecuted) {
       proveDriversLicenseExecuted = true;
       payload_proveDriversLicense_birthDateYear = birthDateYear;
       payload_proveDriversLicense_validUntil = validUntil;
       payload_proveDriversLicense_authorizedCarType = authorizedCarType;
    }

      function sendInvoice(uint32 price) external isActive(proveDriversLicenseExecuted) isActive(!sendInvoiceExecuted) {
        sendInvoiceExecuted = true;
        payload_sendInvoice_price = price;
    }

    function provePaymentOfInvoice(uint32 transferAmount) external isActive(sendInvoiceExecuted) isActive(!provePaymentOfInvoiceExecuted) {
        provePaymentOfInvoiceExecuted = true;
        payload_provePaymentOfInvoice_transferAmount = transferAmount;
    }

    function requestCarPreparation(uint32 id) external isActive(proveDriversLicenseExecuted) isActive(!requestCarPreparationExecuted) {
        requestCarPreparationExecuted = true;
        payload_requestCarPreparation_id = id;
     }

    function confirmCarPreparation(uint32 preparedCarId) external isActive(requestCarPreparationExecuted) isActive(!confirmCarPreparationExecuted) {
        confirmCarPreparationExecuted = true;
        payload_confirmCarPreparation_preparedCarId = preparedCarId;
    }

    function handOverKeys(uint32 keyId) external isActive(provePaymentOfInvoiceExecuted) isActive(confirmCarPreparationExecuted) isActive(!handOverKeysExecuted) {
        handOverKeysExecuted = true;
        payload_handOverKeys_keyId = keyId;
     }
}

