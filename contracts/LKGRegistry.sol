// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Structs.sol";
import "./RBAC.sol";
import "openzeppelin-solidity/contracts/utils/Context.sol";
import "openzeppelin-solidity/contracts/utils/Counters.sol";

/**
 * Contract that works as registry for all details regarding the supply chain
 */
contract LKGRegistry is Context {
    using Counters for Counters.Counter;
    Counters.Counter private controlCounter;
    Counters.Counter private nonGseCounter;
    RBAC private rbac;
    mapping(address => bool) private entitiesIndex;
    mapping(address => Structs.SupplyChainEntity) private supplyChainEntities;
    mapping(address => bool) private controlEntitiesIndex;
    mapping(address => Structs.ControlEntity) private controlEntities;
    mapping(uint256 => Structs.GSEControl) controls;
    mapping(uint256 => Structs.NonGSETransaction) transactions;
    mapping(uint256 => bool) controlIndex;
    mapping(uint256 => bool) nonGseIndex;

    constructor(address _rbac) public {
        rbac = RBAC(_rbac);
    }

    /**
     * @notice Checks that caller has the role of a supply chain  admin
     */
    modifier onlyChainAdmin() {
        require(
            rbac.hasRole(_msgSender(), rbac.SUPPLY_CHAIN_ADMIN_ROLE()),
            "Only supply chain admin can call this function"
        );
        _;
    }

    /**
     *@notice Check that the caller is part of the supply chain
     */
    modifier onlyChainMember() {
        require(
            (rbac.hasRole(
                _msgSender(),
                rbac.SUPPLY_CHAIN_CONTROL_ENTITY_ROLE()
            ) || rbac.hasRole(_msgSender(), rbac.SUPPLY_CHAIN_ENTITY_ROLE())) ||
                rbac.hasRole(_msgSender(), rbac.SUPPLY_CHAIN_ADMIN_ROLE()),
            "Not a chain member"
        );
        _;
    }

    /**
     * @notice Add a supply chain entity to the registry
     * @param _address Address of the account belonging to the entity
     * @param _entity The entity to be added
     */
    function addSupplyChainEntity(
        address _address,
        Structs.SupplyChainEntity memory _entity
    ) public onlyChainAdmin {
        require(!entitiesIndex[_address], "Entity already existing");
        require(rbac.hasRole(_address, rbac.SUPPLY_CHAIN_ENTITY_ROLE()), "Address is not a supply chain entity");
        entitiesIndex[_address] = true;
        supplyChainEntities[_address] = _entity;
    }

    /**
     * @notice Get the supply chain entity belonging to the address
     * @param _entity Address of the entity
     * @return Supply chain entity
     */
    function getSupplyChainEntity(address _entity)
        public
        view
        onlyChainMember
        returns (Structs.SupplyChainEntity memory)
    {
        require(entitiesIndex[_entity], "Entity does not exist");
        return supplyChainEntities[_entity];
    }

    /**
     * @notice Remove a supply chain entity from the registry
     * @param _entity Address of the entity
     */
    function removeSupplyChainEntity(address _entity) public onlyChainAdmin {
        require(entitiesIndex[_entity], "Entity does not exist");
        entitiesIndex[_entity] = false;
        delete (supplyChainEntities[_entity]);
    }

    /**
     * @notice Add control entity to registry
     * @param _address of the control entity
     *@param _entity to add
     */
    function addControlEntity(
        address _address,
        Structs.ControlEntity memory _entity
    ) public onlyChainAdmin {
        require(!controlEntitiesIndex[_address], "Entity already exists");
        require(rbac.hasRole(_address, rbac.SUPPLY_CHAIN_CONTROL_ENTITY_ROLE()), "Address is not a control entity");
        controlEntitiesIndex[_address] = true;
        controlEntities[_address] = _entity;
    }

    /**
     * @notice Get a control entity from the registry
     * @param _entity The address of the entity
     * @return Control entity
     */
    function getControlentity(address _entity)
        public
        view
        onlyChainMember
        returns (Structs.ControlEntity memory)
    {
        require(controlEntitiesIndex[_entity], "Entity does not exist");
        return controlEntities[_entity];
    }

    /**
     * @notice Remove a control entity from the registry
     * @param _entity The address of the entity to be removed
     */
    function removeControlEntity(address _entity) public onlyChainAdmin {
        require(controlEntitiesIndex[_entity], "Entity does not exist");
        controlEntitiesIndex[_entity] = false;
        delete (controlEntitiesIndex[_entity]);
    }

    /**
     * @notice Add control to supply chain entity
     * @param _entity The supply chain entity to add the control to
     * @param _control The control to add
     */
    function addControl(address _entity, Structs.GSEControl memory _control)
        public
        onlyChainAdmin
    {
        require(entitiesIndex[_entity], "Entity does not exist");

        controlCounter.increment();
        // update control index
        controlIndex[controlCounter.current()] = true;
        // add control struct to the mapping
        controls[controlCounter.current()] = _control;
        // add control id to the supply chain entity
        supplyChainEntities[_entity].controls.push(controlCounter.current());
        // increment number of controls for controller
        controlEntities[_control.controller].numberOfControls += 1;
    }

    /**
     * @notice Get a control that was made
     * @param _controlId id of the control
     * @return control with the given id
     */
    function getControl(uint256 _controlId)
        public
        view
        onlyChainMember
        returns (Structs.GSEControl memory)
    {
        require(controlIndex[_controlId], "Control does not exist");
        return controls[_controlId];
    }

    /**
     * @notice Get a list of control ids that were made for a supply chain entity
     * @param _entity The entity to get the control ids for
     *@return Array of control ids
     */
    function getControls(address _entity)
        public
        view
        onlyChainMember
        returns (uint256[] memory)
    {
        require(entitiesIndex[_entity], "Entity does not exist");
        return supplyChainEntities[_entity].controls;
    }

    /**
     * @notice Add nonGSETransaction to supply chain entity
     * @param _entity The supply chain entity to add the transaction to
     * @param _transaction The transaction to add
     */
    function addNonGSETransaction(
        address _entity,
        Structs.NonGSETransaction memory _transaction
    ) public onlyChainAdmin {
        require(entitiesIndex[_entity], "Entity does not exits");

        nonGseCounter.increment();
        // update transaction index
        nonGseIndex[nonGseCounter.current()] = true;
        // add transaction struct to the mapping
        transactions[nonGseCounter.current()] = _transaction;
        // add transaction id to the supply chain entity
        supplyChainEntities[_entity].transactions.push(nonGseCounter.current());
    }

    /**
     * @notice Get a non gse transaction that was made
     * @param _transactionIndex id of the transaction
     * @return transaction with the given id
     */
    function getNonGSETransaction(uint256 _transactionIndex)
        public
        view
        onlyChainMember
        returns (Structs.NonGSETransaction memory)
    {
        require(nonGseIndex[_transactionIndex], "Transaction does not exist");
        return transactions[_transactionIndex];
    }

    /**
     * @notice Get a list of transaction ids that were recorded for a supply chain entity
     * @param _entity The entity to get the transaction ids for
     * @return Array of transaction ids
     */
    function getNonGSETransactions(address _entity)
        public
        view
        onlyChainMember
        returns (uint256[] memory)
    {
        require(entitiesIndex[_entity], "Entity does not exist");
        return supplyChainEntities[_entity].transactions;
    }

    /**
     * @notice A control or supply chain entity can acknowledge that they have red and accepted the "GSE"
     */
    function acknowledgeGSE() public onlyChainMember {
        require(
            entitiesIndex[_msgSender()] || controlEntitiesIndex[_msgSender()],
            "Entity does not exist"
        );
        if (
            rbac.hasRole(_msgSender(), rbac.SUPPLY_CHAIN_CONTROL_ENTITY_ROLE())
        ) {
            controlEntities[_msgSender()].gseStatus = true;
        }

        if (rbac.hasRole(_msgSender(), rbac.SUPPLY_CHAIN_ENTITY_ROLE())) {
            supplyChainEntities[_msgSender()].gseStatus = true;
        }
    }
}
