;; Influencer Staking and Rewards Contract
;; This contract allows influencers to stake tokens and earn additional rewards

;; Token definitions (in a real contract, you would import an existing token)
(define-fungible-token influencer-token)

;; Define a data var for the contract owner
(define-data-var contract-owner principal tx-sender)

;; Define a mapping for influencer stakes
(define-map staking-positions 
  {influencer: principal} 
  {amount: uint, start-time: uint, last-claim-time: uint})

;; Define a constant for reward rate (per block)
(define-constant REWARD-RATE-PER-BLOCK u10)  ;; 0.01 tokens per block

;; Define a constant for minimum staking period (blocks)
(define-constant MIN-STAKING-PERIOD u144)  ;; ~1 day in blocks

;; Define a constant for maximum staking amount
(define-constant MAX-STAKING-AMOUNT u10000000000)

;; Define a constant for maximum mint amount
(define-constant MAX-MINT-AMOUNT u1000000000)

;; Define a constant for blacklisted addresses (example purposes)
(define-constant BLACKLISTED_ADDR1 'SP000000000000000000002Q6VF78)

;; Error codes
(define-constant ERR-UNAUTHORIZED u1)
(define-constant ERR-INSUFFICIENT-TOKENS u200)
(define-constant ERR-NO-STAKE-FOUND u201)
(define-constant ERR-MIN-STAKING-PERIOD u202)
(define-constant ERR-ZERO-AMOUNT u203)
(define-constant ERR-AMOUNT-TOO-LARGE u204)
(define-constant ERR-BLACKLISTED u205)
(define-constant ERR-INVALID-RECIPIENT u206)

;; Check if caller is contract owner
(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner)))

;; Check if principal is blacklisted
(define-private (is-blacklisted (address principal))
  (or
    (is-eq address BLACKLISTED_ADDR1)
    false)) ;; Add more blacklisted addresses as needed

;; Validate amount for staking
(define-private (validate-stake-amount (amount uint))
  (and (> amount u0) (<= amount MAX-STAKING-AMOUNT)))

;; Validate amount for minting
(define-private (validate-mint-amount (amount uint))
  (and (> amount u0) (<= amount MAX-MINT-AMOUNT)))

;; Transfer contract ownership
(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-contract-owner) (err ERR-UNAUTHORIZED))
    ;; Validate new owner is not blacklisted
    (asserts! (not (is-blacklisted new-owner)) (err ERR-BLACKLISTED))
    (ok (var-set contract-owner new-owner))))

;; Stake tokens
(define-public (stake-tokens (amount uint))
  (begin
    ;; Validate amount
    (asserts! (> amount u0) (err ERR-ZERO-AMOUNT))
    (asserts! (<= amount MAX-STAKING-AMOUNT) (err ERR-AMOUNT-TOO-LARGE))
    ;; Check if user is blacklisted
    (asserts! (not (is-blacklisted tx-sender)) (err ERR-BLACKLISTED))
    
    (let ((current-time block-height)
          (existing-stake (map-get? staking-positions {influencer: tx-sender})))
      
      ;; Check if user has enough tokens
      (asserts! (<= amount (ft-get-balance influencer-token tx-sender)) 
                (err ERR-INSUFFICIENT-TOKENS))
      
      ;; Transfer tokens to contract
      (try! (ft-transfer? influencer-token amount tx-sender (as-contract tx-sender)))
      
      ;; Update staking position
      (match existing-stake
        existing 
        (map-set staking-positions 
                {influencer: tx-sender} 
                {amount: (+ amount (get amount existing)), 
                  start-time: (get start-time existing),
                  last-claim-time: current-time})
        
        ;; No existing stake, create new one
        (map-set staking-positions 
                {influencer: tx-sender} 
                {amount: amount, 
                  start-time: current-time,
                  last-claim-time: current-time}))
      
      (print {event: "tokens-staked", influencer: tx-sender, amount: amount})
      (ok amount))))

;; Calculate pending rewards
(define-read-only (calculate-pending-rewards (influencer principal))
  (match (map-get? staking-positions {influencer: influencer})
    stake 
    (let ((blocks-since-last-claim (- block-height (get last-claim-time stake)))
          (staked-amount (get amount stake)))
      (ok (* blocks-since-last-claim 
            (/ (* staked-amount REWARD-RATE-PER-BLOCK) u1000))))
    (err ERR-NO-STAKE-FOUND)))

;; Claim rewards
(define-public (claim-rewards)
  (begin
    ;; Check if user is blacklisted
    (asserts! (not (is-blacklisted tx-sender)) (err ERR-BLACKLISTED))
    
    (match (map-get? staking-positions {influencer: tx-sender})
      stake 
      (let ((pending-rewards (unwrap! (calculate-pending-rewards tx-sender) (err ERR-NO-STAKE-FOUND))))
        
        ;; Update last claim time
        (map-set staking-positions 
                {influencer: tx-sender} 
                (merge stake {last-claim-time: block-height}))
        
        ;; Mint rewards to user
        (try! (as-contract (ft-mint? influencer-token pending-rewards tx-sender)))
        
        (print {event: "rewards-claimed", influencer: tx-sender, amount: pending-rewards})
        (ok pending-rewards))
      (err ERR-NO-STAKE-FOUND))))

;; Unstake tokens
(define-public (unstake-tokens (amount uint))
  (begin
    ;; Validate amount
    (asserts! (> amount u0) (err ERR-ZERO-AMOUNT))
    ;; Check if user is blacklisted
    (asserts! (not (is-blacklisted tx-sender)) (err ERR-BLACKLISTED))
    
    (match (map-get? staking-positions {influencer: tx-sender})
      stake 
      (begin
        ;; Check minimum staking period
        (asserts! (>= (- block-height (get start-time stake)) MIN-STAKING-PERIOD) 
                  (err ERR-MIN-STAKING-PERIOD))
        
        ;; Check sufficient staked amount
        (asserts! (<= amount (get amount stake)) 
                  (err ERR-INSUFFICIENT-TOKENS))
        
        ;; Claim any pending rewards first
        (try! (claim-rewards))
        
        ;; Update staking position
        (if (is-eq amount (get amount stake))
            ;; Remove staking position entirely if unstaking all
            (map-delete staking-positions {influencer: tx-sender})
            ;; Otherwise reduce staked amount
            (map-set staking-positions 
                    {influencer: tx-sender} 
                    (merge stake {amount: (- (get amount stake) amount)})))
        
        ;; Transfer tokens back to user
        (try! (as-contract (ft-transfer? influencer-token amount (as-contract tx-sender) tx-sender)))
        
        (print {event: "tokens-unstaked", influencer: tx-sender, amount: amount})
        (ok amount))
      (err ERR-NO-STAKE-FOUND))))

;; Get staking position details
(define-read-only (get-staking-position (influencer principal))
  (match (map-get? staking-positions {influencer: influencer})
    position (ok position)
    (err ERR-NO-STAKE-FOUND)))

;; Initialize token supply for testing - SECURITY ENHANCED
(define-public (initialize-token-supply (recipient principal) (amount uint))
  (begin
    ;; Check authorization
    (asserts! (is-contract-owner) (err ERR-UNAUTHORIZED))
    
    ;; Validate recipient
    (asserts! (not (is-blacklisted recipient)) (err ERR-BLACKLISTED))
    (asserts! (not (is-eq recipient 'SP000000000000000000002Q6VF78)) (err ERR-INVALID-RECIPIENT))
    
    ;; Validate amount
    (asserts! (> amount u0) (err ERR-ZERO-AMOUNT))
    (asserts! (<= amount MAX-MINT-AMOUNT) (err ERR-AMOUNT-TOO-LARGE))
    
    ;; Mint tokens to recipient
    (try! (as-contract (ft-mint? influencer-token amount recipient)))
    (ok amount)))
