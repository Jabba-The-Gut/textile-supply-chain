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
    mapping(uint256 => bool) activeIndex;

    event NonGSETransaction(Structs.NonGSETransaction);

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

    /**
     * @notice Creates a token and set's the given address as new owner
     * @param _owner owner of the newly created token
     * @param _tokenData metadata for the token to be created
     */
    function mintToken(address _owner, Structs.Metadata memory _tokenData)
        public
        returns (uint256)
    {
        require(
            rbac.hasRole(_msgSender(), rbac.SUPPLY_CHAIN_MINTER_ROLE()),
            "Not the valid role to create tokens"
        );
        require(
            rbac.hasRole(_owner, rbac.SUPPLY_CHAIN_ENTITY_ROLE()),
            "Owner must be a supply chain entity"
        );

        // increment counter for first tokenID
        _tokenIds.increment();
        uint256 tokenID = _tokenIds.current();

        // mint token
        _mint(_owner, tokenID);

        // add _tokenData to internal mapping
        metadata[tokenID] = _tokenData;
        // set token as active
        activeIndex[tokenID] = true;
        // set all input tokens to inactive, so they cannot be transferred further
        uint256[] memory inputTokens = _tokenData.sourceTokenIds;
        for (uint256 i = 0; i < inputTokens.length; i++) {
            activeIndex[inputTokens[i]] = false;
        }

        return tokenID;
    }

    /**
     * @notice Transfer token from one entity to another
     * @param _from sender entity
     * @param _to receiver entity
     * @param _tokenId id of the token to be transferred
     */
    function transferToken(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        require(
            rbac.hasRole(_msgSender(), rbac.SUPPLY_CHAIN_ENTITY_ROLE()),
            "Only supply chain entities can transfer tokens"
        );
        require(
            rbac.hasRole(_to, rbac.SUPPLY_CHAIN_ENTITY_ROLE()),
            "Only supply chain entities can receive tokens"
        );
        require(_exists(_tokenId), "Token with given ID does not exist");
        require(
            activeIndex[_tokenId],
            "Token must be active to be transferrable"
        );

        _transfer(_from, _to, _tokenId);
    }

    /**
     * @notice Returns the metadata belonging to a token
     * @param _tokenId of the token
     * @return metadata of the token
     */
    function getTokenMetadata(uint256 _tokenId)
        public
        view
        returns (Structs.Metadata memory)
    {
        require(_exists(_tokenId), "Token with give ID does not exist");

        return metadata[_tokenId];
    }

    /**
     * @notice Function that gets called before every transfer of a token. Checks if the from and to addresses
     * have conformed to the "Grundsatzerklärung"
     * @param _from address of the token owner
     * @param _to address of the token receiver
     * @param _tokenId of the token to be transferred
     */
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual override {
        require(
            rbac.hasRole(_to, rbac.SUPPLY_CHAIN_ENTITY_ROLE()),
            "Only supply chain entities can receive tokens"
        );

        // only check for gse status if it's not a mint or burn operation
        if (_from != address(0) && _to != address(0)) {
            Structs.SupplyChainEntity memory toEntity =
                registry.getSupplyChainEntity(_to);

            Structs.SupplyChainEntity memory fromEntity =
                registry.getSupplyChainEntity(_from);

            if (!toEntity.gseStatus || !fromEntity.gseStatus) {
                Structs.NonGSETransaction memory transaction =
                    Structs.NonGSETransaction({
                        time: block.timestamp,
                        tokenId: _tokenId
                    });

                if (!toEntity.gseStatus) {
                    registry.addNonGSETransaction(_to, transaction);
                }
                if (!fromEntity.gseStatus) {
                    registry.addNonGSETransaction(_from, transaction);
                }

                emit NonGSETransaction(transaction);
            }
        }
    }
}
