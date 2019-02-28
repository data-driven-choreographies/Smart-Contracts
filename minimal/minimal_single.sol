pragma solidity ^0.5.1;
 
contract Choreography {
   
   bool start = true;
   bool firstTaskExecuted = false;
   bool secondTaskExecuted = false;
   
    uint32 firstTask_payload_value;
    uint32 secondTask_payload_value;
    
    modifier isActive(bool active) {
        require(active);
        _;
    }

    function firstTask(uint32 value) external isActive(start) isActive(!firstTaskExecuted) {
        firstTask_payload_value = value;
        firstTaskExecuted = true;
    }
    
    function secondTask(uint32 value) external isActive(firstTaskExecuted) isActive(!secondTaskExecuted) {
        secondTask_payload_value = value;
        secondTaskExecuted = true; 
    }
}
