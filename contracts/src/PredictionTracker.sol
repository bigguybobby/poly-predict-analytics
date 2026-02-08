// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title PredictionTracker
/// @notice On-chain prediction accuracy tracking and leaderboard
contract PredictionTracker {
    struct Prediction {
        address predictor;
        bytes32 marketId;
        bool outcome;
        uint256 confidence; // 0-10000 bps
        uint256 timestamp;
        bool resolved;
        bool correct;
    }

    mapping(uint256 => Prediction) public predictions;
    uint256 public predictionCount;
    mapping(address => uint256) public correctCount;
    mapping(address => uint256) public totalCount;

    event PredictionMade(uint256 indexed id, address indexed predictor, bytes32 marketId, bool outcome, uint256 confidence);
    event PredictionResolved(uint256 indexed id, bool correct);

    address public oracle;
    modifier onlyOracle() { require(msg.sender == oracle, "not oracle"); _; }

    constructor() { oracle = msg.sender; }

    function predict(bytes32 marketId, bool outcome, uint256 confidence) external returns (uint256 id) {
        require(confidence <= 10000, "max 100%");
        id = predictionCount++;
        predictions[id] = Prediction(msg.sender, marketId, outcome, confidence, block.timestamp, false, false);
        totalCount[msg.sender]++;
        emit PredictionMade(id, msg.sender, marketId, outcome, confidence);
    }

    function resolve(uint256 id, bool actualOutcome) external onlyOracle {
        Prediction storage p = predictions[id];
        require(!p.resolved, "already resolved");
        p.resolved = true;
        p.correct = (p.outcome == actualOutcome);
        if (p.correct) correctCount[p.predictor]++;
        emit PredictionResolved(id, p.correct);
    }

    function getAccuracy(address predictor) external view returns (uint256) {
        if (totalCount[predictor] == 0) return 0;
        return correctCount[predictor] * 10000 / totalCount[predictor];
    }
}
