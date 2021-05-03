// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// This file contains all enums

library Enums {
    /**
     * enum for stages of control process
     */
    enum ControlStage {Registered, Findings, Archived}

    /**
     * enum for the different status of a finished control
     */
    enum ControlStatus {Accepted, NotAccepted}

    /**
     * enum for the different roles involved in the control process
     */
    enum ControlRole {Inspector, QualityControl, Risk}

    /**
     * enum for the different roles involved in the supply chain
     */
    enum SupplyChainRole {Delivery, Producer, External}
}
