// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "openzeppelin-solidity/contracts/utils/Counters.sol";
import "./RBAC.sol";
import "./ControlStateMachine.sol";
import "openzeppelin-solidity/contracts/utils/Context.sol";
import "./LKGRegistry.sol";

/**
 * Contract that acts as a gateway to the control state machine
 */
contract Control is Context{
    using Counters for Counters.Counter;
    Counters.Counter private controlId;
    mapping(uint256 => bool) private controlIndex;
    mapping(uint256 => ControlStateMachine) private controls;
    RBAC private access;
    LKGRegistry private registry;

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

    constructor(address _rbacAddress, address _registryAddress) public {
        access = RBAC(_rbacAddress);
        registry = LKGRegistry(_registryAddress);
    }

    /**
     * @notice Start control process for given address
     * @param _controlled address of controlled instance
     * @return id of the control
     */
    function startControl(address _controlled) public returns (uint256) {
        require(
            access.hasRole(_msgSender(), access.SUPPLY_CHAIN_CONTROL_ENTITY_ROLE()),
            "Account is not a control instance."
        );
        require(
            access.hasRole(_controlled, access.SUPPLY_CHAIN_ENTITY_ROLE()),
            "Account to be controlled is not a supply chain entity."
        );

        // generate id of control process
        controlId.increment();
        // create instance of control process
        ControlStateMachine proc =
            new ControlStateMachine(
                _controlled,
                _msgSender(),
                controlId.current()
            );
        // store mapping of control process
        controlIndex[controlId.current()] = true;
        controls[controlId.current()] = proc;

        emit ControlCreated(controlId.current(), _controlled, _msgSender());

        return controlId.current();
    }

    /**
     * @notice Report findings during control
     * @param _controlId of the control
     * @param _findings made during control
     */
    function reportFindingsForControl(
        uint256 _controlId,
        Structs.GSEControlDetails memory _findings
    ) public {
        require(
            access.hasRole(_msgSender(), access.SUPPLY_CHAIN_CONTROL_ENTITY_ROLE()),
            "Account is not a control instance."
        );
        require(controlIndex[_controlId], "No control with given ID.");
        require(controls[_controlId].controller() == _msgSender(), "Only the controller can add findings.");
        controls[_controlId].addFindings(_findings);

        emit FindingsForControlReported(_controlId, _findings);
    }

    /**
     * @notice Acknowledge control
     * @param _controlId identifier of the control
     * @param _opinion true if the controlled entity knows about the control and
     * agrees with the results, false if the entity knows (or doesn't know) about the control and/or does not agree with the results
     */
    function acknowledgeControl(uint256 _controlId, bool _opinion) public {
        require(
            access.hasRole(_msgSender(), access.SUPPLY_CHAIN_ENTITY_ROLE()),
            "Caller address is not part of the supply chain."
        );
        require(controlIndex[_controlId], "No control with given ID.");
        require(controls[_controlId].controlled() == _msgSender(), "Only controlled entity can acknowledge.");

        // get the given control process instance
        ControlStateMachine instance = controls[_controlId];
        instance.commentControl();

        Enums.ControlStatus status;
        if (_opinion) {
            status = Enums.ControlStatus.Accepted;
        } else {
            status = Enums.ControlStatus.NotAccepted;
        }

        Structs.GSEControl memory control = Structs.GSEControl({
                controlId: _controlId,
                timeOfControl: instance.created(),
                status: status,
                controlled: instance.controlled(),
                controller: instance.controller()
            });

        registry.addControl(instance.controlled(), control);

        emit ControlFinished(
            control
        );
    }
}
