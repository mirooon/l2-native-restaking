# Solidity Proof of Concept for L2 Native Restaking

## Overview

This project serves as a proof of concept (PoC) implemented in Solidity, focusing on the exploration of Layer 2 Native Restaking and conducting research on the LayerZero platform. The primary motivation behind this project was to demonstrate the feasibility and potential of L2 Native Restaking as discussed in EtherFi's concept of [Native L2 Restaking](https://medium.com/layerzero-ecosystem/introducing-native-l2-restaking-079edaa1804a).

### Objectives

The objectives of this Solidity project were to:
1. Validate the possibility of L2 Native Restaking using the OFT standard of LayerZero.
2. Showcase the use of Solidity skills and the capabilities of the Foundry tool.
3. Ensure modularity, clean code, comprehensive documentation, and the use of mocks to facilitate testing and further development.

### Key Features and Problem Solving

#### L2 Native Restaking
- **Problem Solved**: Reduces the need for frequent bridging back to Layer 1, which can be costly and time-consuming.
- **LayerZero and OFT**: By utilizing the OFT standard provided by LayerZero, this project enables seamless re-staking of assets on Layer 2, enhancing user experience and efficiency.

#### Modular Design and Foundry
- **Modularity and Clean Code**: The project is designed to be modular with clear, well-documented code to ensure ease of understanding and development.
- **Foundry Tool**: Demonstrates the integration and capabilities of the Foundry tool for smart contract testing.

## Installation and Setup

To get started with this project, follow these steps:
1. Install dependencies:
```bash
yarn
```
2. Install packages via Forge:
```bash
forge install
```
3. Test
```bash
forge test
```

### Running Tests

The `Playground.spec.sol` file contains an end-to-end test designed to validate the overall functionality of the smart contracts. Execute this test to ensure the robustness of your implementation. While currently limited to a single comprehensive test, it serves as a foundational checkpoint for assessing the project's core functionalities.

## Challenges and Future Work

### Challenges
Given the 24-hour timeline for this ambitious project, it was challenging to cover extensive testing, resulting in fewer tests than ideal. This project was a unique endeavor and understandably impacted by the ambitious scope.

### Future Work
1. **Implement Restake Logic**: Future versions should implement actual logic connecting to services like Lido or Eigen Layer, replacing the current mock implementations of `RestakingManager` and `RestakingProtocol`.
2. **Bridge Automation**: Address the issue in `vETHOFT_L2` where ETH is not automatically bridged upon deposit, requiring user interaction.
3. **Oracle Integration**: Integrate oracles effectively to ensure that `vETH` is minted based on real-time ETH prices, rather than a fixed 1:1 ratio.
4. **Comprehensive Testing**: Extensive testing needs to be developed to ensure all components work seamlessly and securely.

## Conclusion

This proof of concept has successfully demonstrated the viability of L2 Native Restaking using the OFT standard and has showcased potential strategies for improving Ethereum scalability. The project provides a solid foundation for future research and development in Layer 2 solutions and sets a clear path for ongoing improvements and expansions.
