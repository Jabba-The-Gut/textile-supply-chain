// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "./Enums.sol";
import "./Structs.sol";

/**
 * Contract that handles the control process of an supply chain entity. Is implemented as a state machine.
 */
contract ControlStateMachine is Ownable {
    uint256 private id;
    uint256 private created;
    Enums.ControlStage stage;
    address private controlled;
    address private controller;
    Structs.GSEControlDetails findings;

    event ControlCreated(
        uint256 controlId,
        address controlledEntity,
        address controlEntity
    );
    event FindingsForControlReported(
        uint256 controlId,
        Structs.GSEControlDetails findings
    );
    event ControlFinished(Structs.GSEControl control);

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

        emit ControlCreated(id, controlled, controller);
    }

    /**
     * @notice Modifier that checks that the transitions between stages are valid
     @param _stage that is valid
     */
    modifier atStage(Enums.ControlStage _stage) {
        require(stage == _stage);
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
        findings = _findings;
        emit FindingsForControlReported(id, findings);
        nextStage();
    }

    /**
     * @notice Signal that the controlled entity agrees or disagrees with the control fingings
     * @param _agree true if the controlled entity agrees with the findings
     */
    function commentControl(bool _agree)
        public
        payable
        atStage(Enums.ControlStage.Findings)
        onlyOwner
    {
        Enums.ControlStatus status;
        if (_agree) {
            status = Enums.ControlStatus.Accepted;
        } else {
            status = Enums.ControlStatus.NotAccepted;
        }

        emit ControlFinished(
            Structs.GSEControl({
                controlId: id,
                timeOfControl: created,
                status: status,
                controlled: controlled,
                controller: controller
            })
        );

        nextStage();
    }

    /**
     * @notice Internal function to transition from one stage to another
     */
    function nextStage() internal {
        stage = Enums.ControlStage(uint256(stage) + 1);
    }

    /**
     * @notice Function to query stage
     * @return stage
     */
    function getStage() public view onlyOwner returns (Enums.ControlStage) {
        return stage;
    }
}
