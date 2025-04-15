# Decentralized Affiliate

A decentralized affiliate marketing system built on Stacks blockchain that allows influencers to earn commissions through a transparent and trustless process.

## Overview

This project implements a smart contract that enables:
- Registration of influencers
- Recording of sales attributed to influencers
- Calculating settlements for influencers

## Contract Structure

The main contract `influencer-affiliate.clar` manages:
- Influencer registration
- Sales tracking per influencer
- Commission settlement calculations

## Functions

### `register-influencer`
Registers a new influencer in the system.
- Parameters: `influencer` (principal)
- Returns: The influencer principal on success, or error code if already registered

### `record-sale`
Records a sale attributed to an influencer.
- Parameters: `influencer` (principal), `amount` (uint)
- Returns: The updated total sales amount for the influencer, or error if influencer not registered

### `calculate-settlement`
Calculates the total settlement amount for an influencer.
- Parameters: `influencer` (principal)
- Returns: The total sales amount attributed to the influencer, or error if influencer not found

## Error Codes

- `u100`: Influencer already registered
- `u101`: Influencer not found when recording sale
- `u102`: Influencer not found when calculating settlement

## Development

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic knowledge of [Clarity language](https://clarity-lang.org/)

### Setup

1. Clone the repository
```bash
git clone https://github.com/your-username/decentralized-affiliate.git
cd decentralized-affiliate
```

2. Run tests
```bash
clarinet test
```

### Project Structure
```
decentralized-affiliate/
│
├── contracts/
│   └── influencer-affiliate.clar  # Main contract logic
│
├── tests/
│   └── influencer-affiliate_test.clar  # Contract tests
│
├── Clarinet.toml  # Project configuration
├── README.md
└── .gitignore
```

## License

[MIT](LICENSE)
