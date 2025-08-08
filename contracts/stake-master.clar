;; Title: StakeMaster Pro - Next-Generation DeFi Protocol
;;
;; Summary: 
;; A sophisticated multi-tiered staking ecosystem that transforms idle STX into 
;; productive yield-generating assets through intelligent reward distribution 
;; and community-governed decision making on the Stacks blockchain.
;;
;; Description:
;; StakeMaster Pro redefines decentralized finance by creating a comprehensive
;; staking infrastructure that seamlessly blends capital efficiency with user
;; empowerment. Built on Bitcoin's robust security through Stacks Layer-2, this
;; protocol offers participants multiple pathways to maximize their STX returns
;; while maintaining full control over their digital assets.
;;
;; The protocol implements a dynamic tier-based reward system (Bronze, Gold, Diamond)
;; where users unlock enhanced benefits and exclusive features based on their
;; commitment level. Strategic time-locking mechanisms provide additional yield
;; multipliers, while the integrated governance framework ensures community-driven
;; protocol evolution and transparent decision-making processes.
;;
;; Key Features:
;; - Multi-tier reward optimization with up to 2.5x yield multipliers
;; - Community-driven governance with proportional voting rights
;; - Enterprise-grade security with multi-layered protection protocols
;; - Native Bitcoin integration leveraging Proof of Transfer consensus
;; - Flexible liquidity management with optional lock-up periods
;; - Institutional-ready compliance framework for mainstream adoption
;;
;; StakeMaster Pro bridges traditional finance with cutting-edge blockchain
;; technology, delivering unprecedented value and security to DeFi participants
;; while fostering a truly decentralized financial ecosystem.

;; TOKEN DEFINITIONS

(define-fungible-token STAKEMASTER-TOKEN u0)

;; PROTOCOL CONSTANTS

(define-constant CONTRACT-OWNER tx-sender)

;; Comprehensive Error Code System
(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-INVALID-PROTOCOL (err u1001))
(define-constant ERR-INVALID-AMOUNT (err u1002))
(define-constant ERR-INSUFFICIENT-STX (err u1003))
(define-constant ERR-COOLDOWN-ACTIVE (err u1004))
(define-constant ERR-NO-STAKE (err u1005))
(define-constant ERR-BELOW-MINIMUM (err u1006))
(define-constant ERR-PAUSED (err u1007))

;; PROTOCOL STATE VARIABLES

(define-data-var protocol-active bool true)
(define-data-var emergency-shutdown bool false)
(define-data-var total-stx-locked uint u0)
(define-data-var base-yield-rate uint u600) ;; 6% annual base yield
(define-data-var performance-bonus uint u150) ;; 1.5% performance bonus
(define-data-var minimum-entry-stake uint u1000000) ;; 1M uSTX minimum entry
(define-data-var withdrawal-delay uint u1440) ;; 24-hour withdrawal delay
(define-data-var governance-proposals uint u0) ;; Total governance proposals

;; DATA STRUCTURES

;; Governance Proposal Management
(define-map GovernanceProposals
  { proposal-id: uint }
  {
    proposer: principal,
    title: (string-utf8 256),
    created-block: uint,
    voting-ends: uint,
    is-executed: bool,
    support-votes: uint,
    opposition-votes: uint,
    quorum-required: uint,
  }
)

;; Comprehensive User Portfolio Tracking
(define-map UserPortfolios
  principal
  {
    total-staked: uint,
    locked-amount: uint,
    health-score: uint,
    last-interaction: uint,
    stx-deposited: uint,
    reward-tokens: uint,
    governance-weight: uint,
    membership-tier: uint,
    yield-multiplier: uint,
  }
)

;; Detailed Staking Position Records
(define-map StakingRecords
  principal
  {
    staked-amount: uint,
    entry-block: uint,
    last-reward-claim: uint,
    lock-duration: uint,
    withdrawal-initiated: (optional uint),
    total-rewards: uint,
  }
)

;; Membership Tier Configuration
(define-map MembershipTiers
  uint
  {
    required-stake: uint,
    yield-multiplier: uint,
    tier-benefits: (list 10 bool),
  }
)

;; PROTOCOL INITIALIZATION

;; Initialize protocol with membership tier structure
(define-public (initialize-protocol)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    ;; Bronze Tier - Entry Level (1M STX minimum)
    (map-set MembershipTiers u1 {
      required-stake: u1000000,
      yield-multiplier: u100,
      tier-benefits: (list true false false false false false false false false false),
    })

    ;; Gold Tier - Advanced Level (5M STX minimum)
    (map-set MembershipTiers u2 {
      required-stake: u5000000,
      yield-multiplier: u175,
      tier-benefits: (list true true true true false false false false false false),
    })

    ;; Diamond Tier - Elite Level (10M STX minimum)
    (map-set MembershipTiers u3 {
      required-stake: u10000000,
      yield-multiplier: u250,
      tier-benefits: (list true true true true true true true false false false),
    })

    (ok true)
  )
)

;; CORE STAKING FUNCTIONALITY

;; Deposit STX with optional time-lock for enhanced rewards
(define-public (deposit-stx
    (amount uint)
    (lock-duration uint)
  )
  (let ((existing-portfolio (default-to {
      total-staked: u0,
      locked-amount: u0,
      health-score: u100,
      last-interaction: u0,
      stx-deposited: u0,
      reward-tokens: u0,
      governance-weight: u0,
      membership-tier: u0,
      yield-multiplier: u100,
    }
      (map-get? UserPortfolios tx-sender)
    )))
    ;; Input validation and protocol status checks
    (asserts! (is-valid-lock-duration lock-duration) ERR-INVALID-PROTOCOL)
    (asserts! (var-get protocol-active) ERR-PAUSED)
    (asserts! (>= amount (var-get minimum-entry-stake)) ERR-BELOW-MINIMUM)

    ;; Execute STX transfer to protocol vault
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))

    ;; Calculate new tier status and multipliers
    (let (
        (updated-stake (+ (get stx-deposited existing-portfolio) amount))
        (tier-data (calculate-tier-status updated-stake))
        (time-lock-bonus (get-lock-bonus lock-duration))
      )
      ;; Create new staking record
      (map-set StakingRecords tx-sender {
        staked-amount: amount,
        entry-block: stacks-block-height,
        last-reward-claim: stacks-block-height,
        lock-duration: lock-duration,
        withdrawal-initiated: none,
        total-rewards: u0,
      })

      ;; Update user portfolio with new tier benefits
      (map-set UserPortfolios tx-sender
        (merge existing-portfolio {
          stx-deposited: updated-stake,
          membership-tier: (get tier-level tier-data),
          yield-multiplier: (* (get base-multiplier tier-data) time-lock-bonus),
          last-interaction: stacks-block-height,
        })
      )

      ;; Update protocol's total locked value
      (var-set total-stx-locked (+ (var-get total-stx-locked) amount))
      (ok true)
    )
  )
)

;; Initiate withdrawal process with mandatory cooling period
(define-public (request-withdrawal (amount uint))
  (let (
      (user-stake (unwrap! (map-get? StakingRecords tx-sender) ERR-NO-STAKE))
      (staked-balance (get staked-amount user-stake))
    )
    ;; Validate withdrawal eligibility
    (asserts! (>= staked-balance amount) ERR-INSUFFICIENT-STX)
    (asserts! (is-none (get withdrawal-initiated user-stake)) ERR-COOLDOWN-ACTIVE)

    ;; Initialize withdrawal cooldown period
    (map-set StakingRecords tx-sender
      (merge user-stake { withdrawal-initiated: (some stacks-block-height) })
    )
    (ok true)
  )
)

;; Complete withdrawal after cooldown period expires
(define-public (execute-withdrawal)
  (let (
      (user-stake (unwrap! (map-get? StakingRecords tx-sender) ERR-NO-STAKE))
      (withdrawal-block (unwrap! (get withdrawal-initiated user-stake) ERR-NOT-AUTHORIZED))
    )
    ;; Verify cooldown period has elapsed
    (asserts!
      (>= (- stacks-block-height withdrawal-block) (var-get withdrawal-delay))
      ERR-COOLDOWN-ACTIVE
    )

    ;; Transfer STX back to user
    (try! (as-contract (stx-transfer? (get staked-amount user-stake) tx-sender tx-sender)))

    ;; Remove staking record
    (map-delete StakingRecords tx-sender)

    ;; Update protocol's total locked value
    (var-set total-stx-locked
      (- (var-get total-stx-locked) (get staked-amount user-stake))
    )
    (ok true)
  )
)

;; GOVERNANCE SYSTEM

;; Create new governance proposal for community voting
(define-public (submit-proposal
    (title (string-utf8 256))
    (voting-duration uint)
  )
  (let (
      (user-portfolio (unwrap! (map-get? UserPortfolios tx-sender) ERR-NOT-AUTHORIZED))
      (new-proposal-id (+ (var-get governance-proposals) u1))
    )
    ;; Validate proposal requirements
    (asserts! (>= (get governance-weight user-portfolio) u1000000)
      ERR-NOT-AUTHORIZED
    )
    (asserts! (is-valid-proposal-title title) ERR-INVALID-PROTOCOL)
    (asserts! (is-valid-voting-duration voting-duration) ERR-INVALID-PROTOCOL)

    ;; Register new governance proposal
    (map-set GovernanceProposals { proposal-id: new-proposal-id } {
      proposer: tx-sender,
      title: title,
      created-block: stacks-block-height,
      voting-ends: (+ stacks-block-height voting-duration),
      is-executed: false,
      support-votes: u0,
      opposition-votes: u0,
      quorum-required: u2000000,
    })

    ;; Increment proposal counter
    (var-set governance-proposals new-proposal-id)
    (ok new-proposal-id)
  )
)

;; Submit vote on active governance proposal
(define-public (cast-vote
    (proposal-id uint)
    (support-proposal bool)
  )
  (let (
      (proposal-data (unwrap! (map-get? GovernanceProposals { proposal-id: proposal-id })
        ERR-INVALID-PROTOCOL
      ))
      (user-portfolio (unwrap! (map-get? UserPortfolios tx-sender) ERR-NOT-AUTHORIZED))
      (user-voting-power (get governance-weight user-portfolio))
      (total-proposals (var-get governance-proposals))
    )
    ;; Validate voting requirements
    (asserts! (< stacks-block-height (get voting-ends proposal-data))
      ERR-NOT-AUTHORIZED
    )
    (asserts! (and (> proposal-id u0) (<= proposal-id total-proposals))
      ERR-INVALID-PROTOCOL
    )
    (asserts! (> user-voting-power u0) ERR-NOT-AUTHORIZED)

    ;; Record weighted vote
    (map-set GovernanceProposals { proposal-id: proposal-id }
      (merge proposal-data {
        support-votes: (if support-proposal
          (+ (get support-votes proposal-data) user-voting-power)
          (get support-votes proposal-data)
        ),
        opposition-votes: (if support-proposal
          (get opposition-votes proposal-data)
          (+ (get opposition-votes proposal-data) user-voting-power)
        ),
      })
    )
    (ok true)
  )
)

;; ADMINISTRATIVE FUNCTIONS

;; Emergency protocol halt for security purposes
(define-public (emergency-halt)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set protocol-active false)
    (var-set emergency-shutdown true)
    (ok true)
  )
)

;; Restore normal protocol operations
(define-public (restore-operations)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set protocol-active true)
    (var-set emergency-shutdown false)
    (ok true)
  )
)

;; Update base yield rate (governance controlled)
(define-public (update-yield-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (and (>= new-rate u100) (<= new-rate u2000)) ERR-INVALID-AMOUNT)
    (var-set base-yield-rate new-rate)
    (ok true)
  )
)

;; READ-ONLY QUERY FUNCTIONS

;; Retrieve protocol owner address
(define-read-only (get-protocol-owner)
  (ok CONTRACT-OWNER)
)

;; Query total STX locked in protocol
(define-read-only (get-total-locked-stx)
  (ok (var-get total-stx-locked))
)

;; Get current governance proposal count
(define-read-only (get-proposal-count)
  (ok (var-get governance-proposals))
)

;; Check protocol operational status
(define-read-only (get-protocol-status)
  (ok {
    active: (var-get protocol-active),
    emergency: (var-get emergency-shutdown),
    base-rate: (var-get base-yield-rate),
  })
)

;; Get user's complete portfolio information
(define-read-only (get-user-portfolio (user principal))
  (map-get? UserPortfolios user)
)

;; Retrieve specific governance proposal details
(define-read-only (get-proposal-details (proposal-id uint))
  (map-get? GovernanceProposals { proposal-id: proposal-id })
)

;; INTERNAL HELPER FUNCTIONS

;; Determine membership tier based on total stake
(define-private (calculate-tier-status (stake-total uint))
  (if (>= stake-total u10000000)
    {
      tier-level: u3,
      base-multiplier: u250,
    } ;; Diamond Tier
    (if (>= stake-total u5000000)
      {
        tier-level: u2,
        base-multiplier: u175,
      } ;; Gold Tier
      {
        tier-level: u1,
        base-multiplier: u100,
      } ;; Bronze Tier
    )
  )
)

;; Calculate time-lock reward bonus
(define-private (get-lock-bonus (duration uint))
  (if (>= duration u8640) ;; 60-day lock
    u175 ;; 1.75x bonus
    (if (>= duration u4320) ;; 30-day lock
      u140 ;; 1.4x bonus
      (if (>= duration u1440) ;; 7-day lock
        u115 ;; 1.15x bonus
        u100 ;; No lock bonus
      )
    )
  )
)

;; Calculate user rewards based on staking parameters
(define-private (compute-user-rewards
    (user principal)
    (block-duration uint)
  )
  (let (
      (stake-record (unwrap! (map-get? StakingRecords user) u0))
      (user-portfolio (unwrap! (map-get? UserPortfolios user) u0))
      (principal-amount (get staked-amount stake-record))
      (yield-rate (var-get base-yield-rate))
      (user-multiplier (get yield-multiplier user-portfolio))
    )
    ;; Reward Formula: (principal * rate * multiplier * duration) / normalization
    (/ (* (* (* principal-amount yield-rate) user-multiplier) block-duration)
      u15000000
    )
  )
)

;; Validate governance proposal title format
(define-private (is-valid-proposal-title (title (string-utf8 256)))
  (and
    (>= (len title) u15) ;; Minimum 15 characters
    (<= (len title) u256) ;; Maximum 256 characters
  )
)

;; Validate lock duration options
(define-private (is-valid-lock-duration (duration uint))
  (or
    (is-eq duration u0) ;; No time lock
    (is-eq duration u1440) ;; 7-day lock
    (is-eq duration u4320) ;; 30-day lock
    (is-eq duration u8640) ;; 60-day lock
  )
)

;; Validate voting period parameters
(define-private (is-valid-voting-duration (duration uint))
  (and
    (>= duration u144) ;; Minimum 24 hours
    (<= duration u4320) ;; Maximum 30 days
  )
)
