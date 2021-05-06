// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "openzeppelin-solidity/contracts/utils/structs/EnumerableSet.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";
import "openzeppelin-solidity/contracts/utils/Context.sol";


/**
 * Implements Role Based Acces Control using a smart contract. (Originally from
 * https://github.com/HQ20/contracts/blob/v0.0.2/contracts/access/RBAC.sol and then
 * adapted to fit newer compiler version)
 */
contract RBAC is Context{
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    mapping(string => EnumerableSet.AddressSet) private _roles;
    mapping(string => bool) private _roleIds;

    event RoleCreated(string roleId);
    event MemberAdded(address member, string roleId);
    event MemberRemoved(address member, string roleId);

    string public constant ROOT_ROLE = "ROOT";
    string public constant SUPPLY_CHAIN_ADMIN_ROLE = "ADMIN";
    string public constant SUPPLY_CHAIN_CONTROL_ENTITY_ROLE = "CONTROL";
    string public constant SUPPLY_CHAIN_ENTITY_ROLE = "SUPPLY_CHAIN_ENTITY";

    /**
     * @notice The contract initializer
     */
    constructor() public {
        _roles[ROOT_ROLE].add(_msgSender());
        _roleIds[ROOT_ROLE] = true;

        addRole(SUPPLY_CHAIN_CONTROL_ENTITY_ROLE);
        addRole(SUPPLY_CHAIN_ENTITY_ROLE);

        emit RoleCreated(ROOT_ROLE);
        emit RoleCreated(SUPPLY_CHAIN_CONTROL_ENTITY_ROLE);
        emit RoleCreated(SUPPLY_CHAIN_ENTITY_ROLE);
        emit MemberAdded(_msgSender(), ROOT_ROLE);
    }

    /**
     * @notice A method to verify if a role exists.
     * @param _roleId The id of the role being verified.
     * @return True or false.
     */
    function roleExists(string memory _roleId) public view returns (bool) {
        return (_roleIds[_roleId]);
    }

    /**
     * @notice A method to verify whether an member is a member of a role
     * @param _member The member to verify.
     * @param _roleId The role to look into.
     * @return Whether the member is a member of the role.
     */
    function hasRole(address _member, string memory _roleId)
        public
        view
        returns (bool)
    {
        require(roleExists(_roleId), "Role doesn't exist.");
        return _roles[_roleId].contains(_member);
    }

    /**
     * @notice A method to create a new role.
     * @param _roleId The id for role that is being created
     */
    function addRole(string memory _roleId) private {
        // require(_roleId != NO_ROLE, "Reserved role id.");
        require(!roleExists(_roleId), "Role already exists.");
        require(hasRole(_msgSender(), ROOT_ROLE), "Caller address is not an admin.");

        _roles[_roleId];
        _roleIds[_roleId] = true;
        emit RoleCreated(_roleId);
    }
    
    /**
     * @notice A method to add a member to a role
     * @param _member The member to add as a member.
     * @param _roleId The role to add the member to.
     */
    function addMember(address _member, string memory _roleId) public {
        require(roleExists(_roleId), "Role doesn't exist.");
        require(
            _roles[ROOT_ROLE].contains(_msgSender()),
            "Caller address can't add members."
        );
        require(
            !hasRole(_member, _roleId),
            "Address is already member of role."
        );

        _roles[_roleId].add(_member);
        emit MemberAdded(_member, _roleId);
    }

    /**
     * @notice A method to remove a member from a role
     * @param _member The member to remove as a member.
     * @param _roleId The role to remove the member from.
     */
    function removeMember(address _member, string memory _roleId) public {
        require(roleExists(_roleId), "Role doesn't exist.");
        require(
            _roles[ROOT_ROLE].contains(_msgSender()),
            "Caller address can't remove members."
        );
        require(hasRole(_member, _roleId), "Address is not member of role.");

        _roles[_roleId].remove(_member);
        emit MemberRemoved(_member, _roleId);
    }
}
