// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "./Enums.sol";
import "./Structs.sol";

/**
 * Contract that handles the control process of a supply chain entity. Is implemented as a state machine.
 */
contract ControlStateMachine is Ownable {
    uint256 public id;
    uint256 public created;
    Enums.ControlStage stage;
    address public controlled;
    address public controller;
    Structs.GSEControlDetails public details;

    constructor(
        address _controlled,
        address _controller,
        uint256 _id
    ) public Ownable() {
        created = block.timestamp;
        stage = Enums.ControlStage.Registered;
        id = _id;
        controlled = _controlled;
        controller = _controller;
    }

    /**
     * @notice Modifier that checks that the transitions between stages are valid
     @param _stage that is valid
     */
    modifier atStage(Enums.ControlStage _stage) {
        require(
            stage == _stage,
            "Method not executable at this stage of the control process"
        );
        _;
    }

    /**
     * @notice Add findings to initiated control
     * @param _findings that were made during the control
     */
    function addFindings(Structs.GSEControlDetails memory _findings)
        public
        atStage(Enums.ControlStage.Registered)
        onlyOwner
    {
        details = _findings;
        nextStage();
    }

    /**
     * @notice Signal that the controlled entity agrees or disagrees with the control fingings
     */
    function commentControl()
        public
        payable
        atStage(Enums.ControlStage.Findings)
        onlyOwner
    {
        nextStage();
    }

    /**
     * @notice Internal function to transition from one stage to another
     */
    function nextStage() internal {
        stage = Enums.ControlStage(uint256(stage) + 1);
    }
}
