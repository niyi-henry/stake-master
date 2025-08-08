# StakeMaster Pro - Next-Generation DeFi Protocol

![StakeMaster Pro](https://img.shields.io/badge/Stacks-Layer2-orange) ![Clarity](https://img.shields.io/badge/Clarity-Smart_Contract-blue) ![License](https://img.shields.io/badge/License-ISC-green) ![Version](https://img.shields.io/badge/Version-1.0.0-purple)

## 🚀 Overview

StakeMaster Pro is a sophisticated multi-tiered staking ecosystem that transforms idle STX into productive yield-generating assets through intelligent reward distribution and community-governed decision making on the Stacks blockchain. Built on Bitcoin's robust security through Stacks Layer-2, this protocol offers participants multiple pathways to maximize their STX returns while maintaining full control over their digital assets.

### 🎯 Key Features

- **Multi-tier Reward Optimization**: Up to 2.5x yield multipliers across Bronze, Gold, and Diamond tiers
- **Community-driven Governance**: Proportional voting rights for protocol evolution
- **Enterprise-grade Security**: Multi-layered protection protocols
- **Native Bitcoin Integration**: Leveraging Proof of Transfer consensus
- **Flexible Liquidity Management**: Optional lock-up periods for enhanced rewards
- **Institutional-ready Compliance**: Framework designed for mainstream adoption

## 🏗️ Architecture

### Membership Tiers

| Tier | Required Stake | Yield Multiplier | Benefits |
|------|----------------|------------------|----------|
| **Bronze** 🥉 | 1M STX | 1.0x | Basic staking rewards |
| **Gold** 🥇 | 5M STX | 1.75x | Enhanced rewards + governance participation |
| **Diamond** 💎 | 10M STX | 2.5x | Maximum rewards + premium features |

### Time-Lock Bonuses

| Lock Period | Multiplier | Description |
|-------------|------------|-------------|
| No Lock | 1.0x | Flexible withdrawal |
| 7 Days | 1.15x | Short-term commitment bonus |
| 30 Days | 1.4x | Medium-term commitment bonus |
| 60 Days | 1.75x | Long-term commitment bonus |

## 🛠️ Technical Specifications

### Contract Details

- **Language**: Clarity 3.0
- **Blockchain**: Stacks Layer-2
- **Token Standard**: SIP-010 Fungible Token
- **Consensus**: Proof of Transfer (PoX)

### Key Constants

```clarity
;; Base yield rate: 6% annual
(define-constant base-yield-rate u600)

;; Minimum entry stake: 1M uSTX
(define-constant minimum-entry-stake u1000000)

;; Withdrawal delay: 24 hours
(define-constant withdrawal-delay u1440)
```

### Error Codes

| Code | Description |
|------|-------------|
| u1000 | ERR-NOT-AUTHORIZED |
| u1001 | ERR-INVALID-PROTOCOL |
| u1002 | ERR-INVALID-AMOUNT |
| u1003 | ERR-INSUFFICIENT-STX |
| u1004 | ERR-COOLDOWN-ACTIVE |
| u1005 | ERR-NO-STAKE |
| u1006 | ERR-BELOW-MINIMUM |
| u1007 | ERR-PAUSED |

## 📋 Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) v2.0+
- [Node.js](https://nodejs.org/) v18+
- [Git](https://git-scm.com/)

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/niyi-henry/stake-master.git
cd stake-master
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Initialize Development Environment

```bash
# Check contract syntax
clarinet check

# Run tests
npm test

# Format contracts
clarinet fmt --in-place
```

### 4. Deploy to Devnet

```bash
clarinet integrate
```

## 🧪 Testing

The project includes comprehensive test suites using Vitest and Clarinet SDK.

### Run Tests

```bash
# Run all tests
npm test

# Run tests with coverage
npm run test:report

# Watch mode for development
npm run test:watch
```

### Test Structure

```
tests/
├── stake-master.test.ts    # Core functionality tests
└── utils/                  # Test utilities and helpers
```

## 📖 API Reference

### Public Functions

#### Core Staking

##### `deposit-stx`

Deposit STX with optional time-lock for enhanced rewards.

```clarity
(deposit-stx (amount uint) (lock-duration uint))
```

**Parameters:**

- `amount`: Amount of STX to stake (minimum 1M uSTX)
- `lock-duration`: Lock period in blocks (0, 1440, 4320, or 8640)

**Returns:** `(response bool uint)`

##### `request-withdrawal`

Initiate withdrawal process with mandatory cooling period.

```clarity
(request-withdrawal (amount uint))
```

**Parameters:**

- `amount`: Amount of STX to withdraw

**Returns:** `(response bool uint)`

##### `execute-withdrawal`

Complete withdrawal after cooldown period expires.

```clarity
(execute-withdrawal)
```

**Returns:** `(response bool uint)`

#### Governance

##### `submit-proposal`

Create new governance proposal for community voting.

```clarity
(submit-proposal (title (string-utf8 256)) (voting-duration uint))
```

**Parameters:**

- `title`: Proposal title (15-256 characters)
- `voting-duration`: Voting period in blocks (144-4320)

**Returns:** `(response uint uint)`

##### `cast-vote`

Submit vote on active governance proposal.

```clarity
(cast-vote (proposal-id uint) (support-proposal bool))
```

**Parameters:**

- `proposal-id`: ID of the proposal to vote on
- `support-proposal`: true for support, false for opposition

**Returns:** `(response bool uint)`

### Read-Only Functions

##### `get-protocol-status`

Check current protocol operational status.

```clarity
(get-protocol-status)
```

**Returns:**

```clarity
{
  active: bool,
  emergency: bool,
  base-rate: uint
}
```

##### `get-user-portfolio`

Retrieve user's complete portfolio information.

```clarity
(get-user-portfolio (user principal))
```

**Returns:**

```clarity
{
  total-staked: uint,
  locked-amount: uint,
  health-score: uint,
  last-interaction: uint,
  stx-deposited: uint,
  reward-tokens: uint,
  governance-weight: uint,
  membership-tier: uint,
  yield-multiplier: uint
}
```

## 🔒 Security Features

### Multi-layered Protection

- **Emergency Halt**: Contract owner can pause operations during security incidents
- **Withdrawal Delays**: 24-hour cooling period for all withdrawals
- **Input Validation**: Comprehensive parameter checking
- **Access Controls**: Role-based authorization system

### Audit Status

- ✅ Static Analysis via Clarinet
- ✅ Unit Test Coverage
- ⏳ External Security Audit (Planned)

## 🏛️ Governance

### Proposal Requirements

- Minimum governance weight: 1M STX
- Proposal title: 15-256 characters
- Voting period: 24 hours to 30 days
- Quorum requirement: 2M STX

### Voting Power

Voting power is proportional to staked amount and membership tier multipliers.

## 📈 Tokenomics

### Yield Calculation

```
Annual Yield = (Staked Amount × Base Rate × Tier Multiplier × Lock Bonus) / 100
```

### Example Scenarios

**Bronze Tier, No Lock:**

- Stake: 1M STX
- Yield: 6% annual (60,000 STX/year)

**Diamond Tier, 60-day Lock:**

- Stake: 10M STX  
- Yield: 26.25% annual (2.625M STX/year)
- Calculation: 6% × 2.5× × 1.75× = 26.25%

## 🌐 Network Configurations

### Devnet

```toml
[network]
name = "devnet"
node_rpc_address = "http://localhost:20443"
```

### Testnet

```toml
[network]
name = "testnet"
node_rpc_address = "https://api.testnet.hiro.so"
```

### Mainnet

```toml
[network]
name = "mainnet"
node_rpc_address = "https://api.hiro.so"
```

## 🤝 Contributing

We welcome contributions! Please read our [Contributing Guidelines](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

### Development Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests (`npm test`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## 📄 License

This project is licensed under the ISC License - see the [LICENSE](LICENSE) file for details.
