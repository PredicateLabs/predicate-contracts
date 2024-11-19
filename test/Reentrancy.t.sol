// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import {Test, console} from "forge-std/Test.sol";
import {ISignatureUtils} from "eigenlayer-contracts/src/contracts/interfaces/ISignatureUtils.sol";
import {ServiceManager} from "../src/ServiceManager.sol";
import {Task} from "../src/interfaces/IPredicateManager.sol";
import {MockClient} from "./helpers/MockClient.sol";
import {MockProxy} from "./helpers/MockProxy.sol";
import {MockProxyAdmin} from "./helpers/MockProxyAdmin.sol";
import {MockStakeRegistry} from "./helpers/MockStakeRegistry.sol";
import {MockDelegationManager} from "./helpers/MockDelegationManager.sol";
import {IPauserRegistry} from "./helpers/eigenlayer/interfaces/IPauserRegistry.sol";
import {IDelegationManager} from "./helpers/eigenlayer/interfaces/IDelegationManager.sol";
import {MockStrategyManager} from "./helpers/MockStrategyManager.sol";
import {MockEigenPodManager} from "./helpers/MockEigenPodManager.sol";
import "./helpers/utility/TestUtils.sol";
import "./helpers/utility/ServiceManagerSetup.sol";
import "./helpers/utility/TestPrep.sol";

contract ReentrancyTest is TestPrep, ServiceManagerSetup {
    Attacker public attacker;
    function setUpAttacker() public {
        attacker = new Attacker(serviceManager);
    }

    modifier permissionedOperators() {
        vm.startPrank(address(this));
        address[] memory operators = new address[](2);
        operators[0] = operatorOne;
        operators[1] = operatorTwo;
        serviceManager.addPermissionedOperators(operators);
        vm.stopPrank();
        _;
    }

    function test_reentrancy_add_strategy() public permissionedOperators {
        vm.expectRevert(ServiceManager.ServiceManager__Reentrancy.selector);

        attacker.attackAddStrategy();
    }

    function test_reentrancy_remove_strategy() public permissionedOperators {
        vm.expectRevert(ServiceManager.ServiceManager__Reentrancy.selector);

        attacker.attackRemoveStrategy();
    }
}

contract Attacker {
    ServiceManager public serviceManager;
    bool public attackInitiated = false;
    bool public removeAttackInitiated = false;

    constructor(ServiceManager _serviceManager) {
        serviceManager = _serviceManager;
    }

    // Initiate reentrancy
    fallback() external payable {
        if (!attackInitiated) {
            attackInitiated = true;
            // Try to re-enter the serviceManager contract
            serviceManager.addStrategy(address(this), 1, 0);
        } else if (!removeAttackInitiated) {
            removeAttackInitiated = true;
            // Try to re-enter the serviceManager contract
            serviceManager.removeStrategy(address(this));
        }
    }

    // fallback() requires receive()
    receive() external payable {}

    function attackAddStrategy() external {
        serviceManager.addStrategy(address(this), 1, 0);
    }

    function attackRemoveStrategy() external {
        serviceManager.removeStrategy(address(this));
    }
}
