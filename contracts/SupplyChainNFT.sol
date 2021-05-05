// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721.sol";
import "./LKGRegistry.sol";
import "./Structs.sol";
import "./RBAC.sol";
import "openzeppelin-solidity/contracts/utils/Counters.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

/**
 * Contract that represents a NFT Token for every stage in the supply chain where something is produced
 */
contract SupplyChainNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    LKGRegistry private registry;
    RBAC private rbac;
    string public name;
    string public symbol;
    mapping(uint256 => Structs.Metadata) metadata;

    constructor(
        string memory _name,
        string memory _symbol,
        address _registry,
        address _rbac
    ) ERC721("SupplyChainToken", "SCT") {
        registry = LKGRegistry(_registry);
        rbac = RBAC(_rbac);
        name = _name;
        symbol = _symbol;
    }
}
