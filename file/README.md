# Decentralized Affiliate & Influencer Platform

A decentralized platform for managing influencer relationships and affiliate marketing using Clarity smart contracts on Stacks blockchain.

## Overview

This project provides a transparent, trustless way to manage influencer/affiliate relationships with the following key features:

- Registration of influencers with customizable commission rates
- Tracking of sales attributed to each influencer
- Commission calculation based on individual rates
- Enhanced security with ownership controls
- Tracking of individual sales receipts
- Influencer staking rewards program

## Smart Contracts

### 1. Influencer Affiliate Contract

The main contract handling the core affiliate marketing functionality:

- **Registration**: Register influencers with customizable commission rates
- **Sales Tracking**: Record sales attributed to specific influencers
- **Commission Management**: Calculate commissions based on configured rates
- **Receipt System**: Track individual sales with unique receipt IDs
- **Security Controls**: Owner-only administrative functions

### 2. Influencer Staking Contract

A complementary contract allowing influencers to stake tokens and earn rewards:

- **Staking**: Influencers can stake tokens to show commitment
- **Rewards**: Earn additional rewards based on staking duration and amount
- **Governance**: Potential future integration with DAO governance model

## Key Functions

### Influencer Affiliate Contract

- `register-influencer`: Register a new influencer with a commission rate
- `update-influencer`: Update an influencer's active status or commission rate
- `record-sale`: Record a sale credited to an influencer with a unique receipt ID
- `mark-sale-paid`: Mark a specific sale as paid
- `calculate-settlement`: Calculate total sales attributed to an influencer
- `calculate-commission`: Calculate the commission owed to an influencer

### Influencer Staking Contract

- `stake-tokens`: Stake tokens in the platform
- `calculate-pending-rewards`: Calculate rewards earned but not yet claimed
- `claim-rewards`: Claim earned staking rewards
- `unstake-tokens`: Withdraw staked tokens after minimum staking period

## Security Features

- **Ownership Controls**: Critical functions restricted to contract owner
- **Receipt Tracking**: Individual sales tracked with unique identifiers
- **Status Management**: Ability to activate/deactivate influencers
- **Input Validation**: Comprehensive input validation with error codes
- **Amount Limits**: Maximum transaction and staking amounts enforced
- **Blacklist System**: Protection against malicious actors
- **Non-Zero Validation**: Prevents zero-value transactions
- **Receipt Validation**: Ensures valid receipt IDs
- **Safe Ownership Transfer**: Prevents transferring ownership to invalid addresses

## Security Best Practices Implemented

- **Parameter Validation**: All user inputs are validated before processing
- **Access Control**: Clear permissions model with owner-only functions
- **Error Handling**: Comprehensive error codes with descriptive messages
- **Numeric Bounds**: Upper and lower limits on numeric values
- **Principal Validation**: Checks against blacklisted or known-bad addresses
- **Buffer Validation**: Ensures non-empty buffer values
- **State Validation**: Checks for valid state transitions
- **Transaction Limits**: Protection against extremely large transactions

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic knowledge of Clarity language

### Installation

```bash
# Clone the repository
git clone https://github.com/midorichie/decentralized-affiliate-influencer.git
cd decentralized-affiliate-influencer

# Install dependencies
npm install

# Run tests
clarinet test
```

## Usage Example

```clarity
;; Register an influencer with a 5% commission rate (50 basis points)
(contract-call? .influencer-affiliate register-influencer 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM 50)

;; Record a sale of 1000 units for an influencer
(contract-call? .influencer-affiliate record-sale 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM 1000 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef)

;; Stake 500 tokens as an influencer
(contract-call? .influencer-staking stake-tokens 500)
```

## Error Codes

| Code | Description |
|------|-------------|
| u1   | Unauthorized - caller is not the contract owner |
| u100 | Influencer already registered |
| u101 | Influencer not registered |
| u102 | Invalid commission rate |
| u103 | Receipt ID already exists |
| u104 | Receipt not found |
| u105 | Zero amount not allowed |
| u106 | Amount too large |
| u107 | Blacklisted address |
| u108 | Invalid owner address |
| u109 | Empty receipt ID |
| u200 | Insufficient tokens for operation |
| u201 | No staking position found |
| u202 | Minimum staking period not met |
| u203 | Zero amount not allowed (staking) |
| u204 | Amount too large (staking) |
| u205 | Blacklisted address (staking) |
| u206 | Invalid recipient address |

## License

This project is licensed under the MIT License - see the LICENSE file for details.
