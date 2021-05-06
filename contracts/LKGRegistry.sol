// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Structs.sol";
import "./RBAC.sol";
import "openzeppelin-solidity/contracts/utils/Context.sol";

/**
 * Contract that works as registry for all detials regarding the supply chain
 */
contract LKGRegistry is Context {
    RBAC private rbac;
    mapping(address => bool) private entitiesIndex;
    mapping(address => Structs.SupplyChainEntity) private supplyChainEntities;
    mapping(address => bool) private controlEntitiesIndex;
    mapping(address => Structs.ControlEntity) private controlEntities;

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
            rbac.hasRole(_msgSender(), rbac.SUPPLY_CHAIN_CONTROL_ENTITY_ROLE()),
            "Not a chain member"
        );
        require(
            rbac.hasRole(_msgSender(), rbac.SUPPLY_CHAIN_ENTITY_ROLE()),
            "Not a chain member"
        );
        require(
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
     * @param _address of the entity
     *@param _entity to add
     */
    function addControlEntity(
        address _address,
        Structs.ControlEntity memory _entity
    ) public onlyChainAdmin {
        require(!controlEntitiesIndex[_address], "Entity already exists");
        controlEntitiesIndex[_address] = true;
        controlEntities[_address] = _entity;
    }

    /**
     * @notice Get the control entity from the registry
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
        supplyChainEntities[_entity].controls.push(_control);
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
        supplyChainEntities[_entity].transactions.push(_transaction);
    }

    /**
     * @notice Get the list of controls for a given supply chain entity
     * @return Array of controls
     */
    function listControlsOfSupplyChainEntity(address _entity)
        public
        view
        onlyChainMember
        returns (Structs.GSEControl[] memory)
    {
        require(entitiesIndex[_entity], "Entity does not exist");
        return supplyChainEntities[_entity].controls;
    }

    /**
     * @notice Get the list of NonGSETransactions for a given supply chain entity
     * @return Array of transactions
     */
    function listNonGSETransactionsOfSupplyChainEntity(address _entity)
        public
        view
        onlyChainMember
        returns (Structs.NonGSETransaction[] memory)
    {
        require(entitiesIndex[_entity], "Entity does not exist");
        return supplyChainEntities[_entity].transactions;
    }
}
