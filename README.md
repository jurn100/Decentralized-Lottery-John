# Decentralized Lottery — Final Project

**Author:** Johnbosco Okoro  
**Network:** Sepolia testnet  
**Contract Address:** https://sepolia.etherscan.io/address/0xc4B5fBE8DFab12aab2c207007edFDeF200627aB2

## On-chain artifacts
- Deploy tx: https://sepolia.etherscan.io/tx/0x54db2ac781c5cd5098b94b271c50c556f38411e35738251e7cfedc725e79ab4b
- Account 2 buyTickets tx: https://sepolia.etherscan.io/tx/0xa99cb78e46bbf4119d3aa98ec54f2e1301df16aa3266746445f497b6d5a15446
- Account 3 buyTickets tx: https://sepolia.etherscan.io/tx/0x4522b11401214d55d6748aa3e863c4ba8557b6876067674e5ee55675d09db6c8
- pickWinner tx: https://sepolia.etherscan.io/tx/0x90d0fdf0d50f72dba40fa88675fed260d31d9d737abdead609aad4d953ba22b5 (Account 3 won)

## Files included
- `contracts/DecentralizedLottery.sol`
- `abi/DecentralizedLottery.json`
- `screenshots/` (compile, start_round, buy_ticket_acc2, buy_ticket_acc3, pick_winner)

## How to reproduce (Remix)
1. Open Remix: https://remix.ethereum.org  
2. Create file `contracts/DecentralizedLottery.sol` and paste source.  
3. Compile with Solidity 0.8.19.  
4. Deploy via Injected Provider (MetaMask) on Sepolia.  
5. Owner calls `startNewRound()`. Players call `buyTickets()` with 0.01 ETH. After time expires, call `pickWinner()`.
