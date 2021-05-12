// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Enums.sol";

library Structs {
    /**
     * struct that represents an entity that can make controls
     */
    struct ControlEntity {
        Enums.ControlRole role;
        string description;
        bool gseStatus;
        uint256 numberOfControls;
    }

    /**
     * struct that represents an entity in the supply chain
     */
    struct SupplyChainEntity {
        Enums.SupplyChainRole role;
        string tier;
        bool gseStatus;
        uint256[] controls;
        uint256[] transactions;
    }

    /**
     * struct that represents a control to check if the
     * circumstances of the GSE are met or not
     */
    struct GSEControl {
        uint256 controlId;
        uint256 timeOfControl;
        Enums.ControlStatus status;
        address controlled;
        address controller;
    }

    /**
     * struct that represents the findings in a GSE-control
     */
    struct GSEControlDetails {
        bool gseOK;
        string[] findings;
    }

    /**
     * struct that represents a transaction of a NFT with one of the parties
     * (either sender or receiver) not accepting or acknowledging the GSE
     */
    struct NonGSETransaction {
        uint256 time;
        uint256 tokenId;
    }

    /**
     * struct that represents the metadata belonging to a NFT
     */
    struct Metadata {
        uint256[] sourceTokenIds;
    }
}
