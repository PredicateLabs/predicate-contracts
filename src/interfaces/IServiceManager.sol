// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {ISignatureUtils} from "eigenlayer-contracts/src/contracts/interfaces/ISignatureUtils.sol";
import {IDelegationManager} from "eigenlayer-contracts/src/contracts/interfaces/IDelegationManager.sol";

struct Task {
    string taskId;
    address msgSender;
    address target;
    uint256 value;
    bytes encodedSigAndArgs;
    string policyID;
    uint32 quorumThresholdCount;
    uint256 expireByBlockNumber;
}

/**
 * @title Minimal interface for a ServiceManager-type contract that forms the single point for an AVS to push updates to EigenLayer
 * @author Predicate Labs, Inc
 */
interface IServiceManager {
    /**
     * @notice Sets the metadata URI for the AVS
     * @param _metadataURI is the metadata URI for the AVS
     */
    function setMetadataURI(
        string memory _metadataURI
    ) external;

    /**
     * @notice Forwards a call to EigenLayer's DelegationManager contract to confirm operator registration with the AVS
     * @param operatorSigningKey The address of the operator's signing key.
     * @param operatorSignature The signature, salt, and expiry of the operator's signature.
     */
    function registerOperatorToAVS(
        address operatorSigningKey,
        ISignatureUtils.SignatureWithSaltAndExpiry memory operatorSignature
    ) external;

    /**
     * @notice Forwards a call to EigenLayer's DelegationManager contract to confirm operator deregistration from the AVS
     * @param operator The address of the operator to deregister.
     */
    function deregisterOperatorFromAVS(
        address operator
    ) external;

    /**
     * @notice Returns the list of strategies that the operator has potentially restaked on the AVS
     * @param operator The address of the operator to get restaked strategies for
     * @dev This function is intended to be called off-chain
     * @dev No guarantee is made on whether the operator has shares for a strategy in a quorum or uniqueness
     *      of each element in the returned array. The off-chain service should do that validation separately
     */
    function getOperatorRestakedStrategies(
        address operator
    ) external view returns (address[] memory);

    /**
     * @notice Returns the list of strategies that the AVS supports for restaking
     * @dev This function is intended to be called off-chain
     * @dev No guarantee is made on uniqueness of each element in the returned array.
     *      The off-chain service should do that validation separately
     */
    function getRestakeableStrategies() external view returns (address[] memory);

    /**
     * @notice Sets a policy ID for the sender, defining execution rules or parameters for tasks
     * @param policyID string pointing to the policy details
     * @dev Only callable by client contracts or EOAs to associate a policy with their address
     * @dev Emits a SetPolicy event upon successful association
     */
    function setPolicy(
        string memory policyID
    ) external;

    /**
     * @notice Removes a policy ID for the sender, removing execution rules or parameters for tasks
     * @param policyID string pointing to the policy details
     * @dev Only callable by client contracts or EOAs to disassociate a policy with their address
     * @dev Emits a RemovedPolicy event upon successful association
     */
    function removePolicy(
        string memory policyID
    ) external;

    /**
     * @notice Deploys a policy with ID with execution rules or parameters for tasks
     * @param _policyID string pointing to the policy details
     * @param _policy string containing the policy details
     * @param _quorumThreshold The number of signatures required to authorize a task
     * @dev Only callable by service manager deployer
     * @dev Emits a DeployedPolicy event upon successful deployment
     */
    function deployPolicy(string memory _policyID, string memory _policy, uint256 _quorumThreshold) external;

    /**
     * @notice Gets array of deployed policies
     */
    function getDeployedPolicies() external view returns (string[] memory);

    /**
     * @notice Deploys a social graph which clients can use in policy
     * @param _socialGraphID is a unique identifier
     * @param _socialGraphConfig is the config for the social graph
     * @dev Only callable by service manager deployer
     * @dev Emits a SocialGraphDeployed event upon successful deployment
     */
    function deploySocialGraph(string memory _socialGraphID, string memory _socialGraphConfig) external;

    /**
     * @notice Returns the list of social graph IDs that the AVS supports
     */
    function getSocialGraphIDs() external view returns (string[] memory);

    /**
     * @notice Verifies if a task is authorized by the required number of operators
     * @param _task Parameters of the task including sender, target, function signature, arguments, quorum count, and expiry block
     * @param signerAddresses Array of addresses of the operators who signed the task
     * @param signatures Array of signatures from the operators authorizing the task
     * @return isVerified Boolean indicating if the task has been verified by the required number of operators
     * @dev This function checks the signatures against the hash of the task parameters to ensure task authenticity and authorization
     */
    function validateSignatures(
        Task memory _task,
        address[] memory signerAddresses,
        bytes[] memory signatures
    ) external returns (bool isVerified);

    /**
     * @notice Adds a new strategy to the Service Manager
     * @dev Only callable by the contract owner. Adds a strategy that operators can stake on.
     * @param _strategy The address of the strategy contract to add
     * @param quorumNumber The quorum number associated with the strategy
     * @param index The index of the strategy within the quorum
     * @dev Emits a StrategyAdded event upon successful addition of the strategy
     * @dev Reverts if the strategy does not exist or is already added
     */
    function addStrategy(address _strategy, uint8 quorumNumber, uint256 index) external;

    /**
     * @notice Removes an existing strategy from the Service Manager
     * @dev Only callable by the contract owner. Removes a strategy that operators are currently able to stake on.
     * @param _strategy The address of the strategy contract to remove
     * @dev Emits a StrategyRemoved event upon successful removal of the strategy
     * @dev Reverts if the strategy is not currently added or if the address is invalid
     */
    function removeStrategy(
        address _strategy
    ) external;

    /**
     * @notice Enables the rotation of Predicate Signing Key for an operator
     * @param _oldSigningKey address of the old signing key to remove
     * @param _newSigningKey address of the new signing key to add
     */
    function rotatePredicateSigningKey(address _oldSigningKey, address _newSigningKey) external;
}
