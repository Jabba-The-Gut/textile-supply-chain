// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "./Structs.sol";

contract LKGRegistry is Ownable {
    constructor() public {}

    function getSupplyChainEntity(address _entity)
        public
        returns (Structs.SupplyChainEntity memory)
    {}

    function addNonGSETransaction(Structs.NonGSETransaction memory _transaction ) public {
        
    }
}
