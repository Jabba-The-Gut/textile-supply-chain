// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "openzeppelin-solidity/contracts/utils/Counters.sol";
import "./RBAC.sol";
import "./ControlStateMachine.sol";

/**
 * Contract that acts as a gateway to the control state machine
 */
contract Control {
    using Counters for Counters.Counter;
    Counters.Counter private controlId;
    mapping(uint256 => bool) private controlIndex;
    mapping(uint256 => ControlStateMachine) private controls;
    RBAC private access;

    constructor(address _rbacAddress) public {
        access = RBAC(_rbacAddress);
    }

    /**
     * @notice Start control process for given address
     * @param _controlled address of controlled instance
     */
    function startControl(address _controlled) public {
        require(
            access.hasRole(msg.sender, access.CONTROL_ROLE()),
            "Account is not a control instance."
        );

        // generate id of control process
        controlId.increment();
        // create instance of control process
        ControlStateMachine proc =
            new ControlStateMachine(
                _controlled,
                msg.sender,
                controlId.current()
            );
        // store mapping of control process
        controlIndex[controlId.current()] = true;
        controls[controlId.current()] = proc;
    }

    /**
     * @notice Report findings during control
     * @param _findings made during control
     */
    function reportFindingsForControl(
        uint256 _controlId,
        Structs.GSEControlDetails memory _findings
    ) public {
        require(
            access.hasRole(msg.sender, access.CONTROL_ROLE()),
            "Account is not a control instance."
        );
        require(controlIndex[_controlId], "No control with giben ID.");
        controls[_controlId].addFindings(_findings);
    }

    /**
     * @notice Acknowledge control
     * @param _controlId identifier of the control
     * @param _opinion true if the controlled entity knows about the control and
     * agrees with the results, false if the entitiy knows about the control but does not agree with the results
     */
    function acknowledgeControl(uint256 _controlId, bool _opinion) public {
        require(
            access.hasRole(msg.sender, access.SUPPLY_CHAIN_ENTITY_ROLE()),
            "Caller address is not part of the supply chain."
        );
        require(controlIndex[_controlId], "No control with given ID.");

        // get the given control process instance
        controls[_controlId].commentControl(_opinion);
    }
}
