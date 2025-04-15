;; Define a mapping for storing registered influencers with their commission rates
(define-map influencers {influencer: principal} {active: bool, commission-rate: uint})

;; Define a mapping for storing affiliate sales totals per influencer
(define-map affiliate-sales {influencer: principal} uint)

;; Define a mapping for tracking individual sales with receipts
(define-map sale-receipts {receipt-id: (buff 32)} {influencer: principal, amount: uint, paid: bool})

;; Define a data var for the contract owner
(define-data-var contract-owner principal tx-sender)

;; Define a constant for minimum commission rate (0.5%)
(define-constant MIN-COMMISSION-RATE u5)

;; Define a constant for maximum commission rate (30%)
(define-constant MAX-COMMISSION-RATE u300)

;; Define a constant for maximum allowed transaction amount
(define-constant MAX-TRANSACTION-AMOUNT u1000000000)

;; Define a constant for blacklisted addresses (example purposes)
(define-constant BLACKLISTED_ADDR1 'SP000000000000000000002Q6VF78)

;; Error codes
(define-constant ERR-UNAUTHORIZED u1)
(define-constant ERR-ALREADY-REGISTERED u100)
(define-constant ERR-NOT-REGISTERED u101)
(define-constant ERR-INVALID-COMMISSION u102)
(define-constant ERR-RECEIPT-EXISTS u103)
(define-constant ERR-RECEIPT-NOT-FOUND u104)
(define-constant ERR-ZERO-AMOUNT u105)
(define-constant ERR-AMOUNT-TOO-LARGE u106)
(define-constant ERR-BLACKLISTED u107)
(define-constant ERR-INVALID-OWNER u108)
(define-constant ERR-EMPTY-RECEIPT-ID u109)

;; Check if caller is contract owner
(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner)))

;; Check if principal is blacklisted
(define-private (is-blacklisted (address principal))
  (or
    (is-eq address BLACKLISTED_ADDR1)
    false)) ;; Add more blacklisted addresses as needed

;; Validate non-zero amount and maximum limit
(define-private (validate-amount (amount uint))
  (and (> amount u0) (<= amount MAX-TRANSACTION-AMOUNT)))

;; Validate receipt ID (check if non-empty)
(define-private (validate-receipt-id (receipt-id (buff 32)))
  (not (is-eq receipt-id 0x0000000000000000000000000000000000000000000000000000000000000000)))

;; Transfer contract ownership
(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-contract-owner) (err ERR-UNAUTHORIZED))
    ;; Validate new owner is not blacklisted
    (asserts! (not (is-blacklisted new-owner)) (err ERR-BLACKLISTED))
    ;; Validate new owner is not zero address
    (asserts! (not (is-eq new-owner 'SP000000000000000000002Q6VF78)) (err ERR-INVALID-OWNER))
    (ok (var-set contract-owner new-owner))))

;; Public function to register an influencer partner with commission rate (in basis points, 1% = 10)
(define-public (register-influencer (influencer principal) (commission-rate uint))
  (begin
    (asserts! (is-contract-owner) (err ERR-UNAUTHORIZED))
    ;; Validate commission rate
    (asserts! (and (>= commission-rate MIN-COMMISSION-RATE) (<= commission-rate MAX-COMMISSION-RATE)) 
              (err ERR-INVALID-COMMISSION))
    ;; Validate influencer is not blacklisted
    (asserts! (not (is-blacklisted influencer)) (err ERR-BLACKLISTED))
    ;; Check if influencer is already registered
    (asserts! (is-none (map-get? influencers {influencer: influencer})) 
              (err ERR-ALREADY-REGISTERED))
    (map-set influencers 
             {influencer: influencer} 
             {active: true, commission-rate: commission-rate})
    (print {event: "influencer-added", influencer: influencer, rate: commission-rate})
    (ok influencer)))

;; Public function to update an influencer's status or commission rate
(define-public (update-influencer (influencer principal) (active bool) (commission-rate uint))
  (begin
    (asserts! (is-contract-owner) (err ERR-UNAUTHORIZED))
    ;; Validate commission rate
    (asserts! (and (>= commission-rate MIN-COMMISSION-RATE) (<= commission-rate MAX-COMMISSION-RATE)) 
              (err ERR-INVALID-COMMISSION))
    ;; Validate influencer is not blacklisted
    (asserts! (not (is-blacklisted influencer)) (err ERR-BLACKLISTED))
    ;; Check if influencer exists
    (asserts! (is-some (map-get? influencers {influencer: influencer})) 
              (err ERR-NOT-REGISTERED))
    (map-set influencers 
             {influencer: influencer} 
             {active: active, commission-rate: commission-rate})
    (print {event: "influencer-updated", influencer: influencer, active: active, rate: commission-rate})
    (ok influencer)))

;; Public function to record a sale (conversion) for a registered influencer
(define-public (record-sale (influencer principal) (amount uint) (receipt-id (buff 32)))
  (begin
    ;; Validate amount
    (asserts! (> amount u0) (err ERR-ZERO-AMOUNT))
    (asserts! (<= amount MAX-TRANSACTION-AMOUNT) (err ERR-AMOUNT-TOO-LARGE))
    ;; Validate receipt-id
    (asserts! (validate-receipt-id receipt-id) (err ERR-EMPTY-RECEIPT-ID))
    ;; Validate influencer is not blacklisted
    (asserts! (not (is-blacklisted influencer)) (err ERR-BLACKLISTED))

    (let ((influencer-data (map-get? influencers {influencer: influencer})))
      (asserts! (is-some influencer-data) (err ERR-NOT-REGISTERED))
      (asserts! (get active (unwrap! influencer-data (err ERR-NOT-REGISTERED))) (err ERR-NOT-REGISTERED))
      (asserts! (is-none (map-get? sale-receipts {receipt-id: receipt-id})) (err ERR-RECEIPT-EXISTS))
      
      (let ((prev-amount (default-to u0 (map-get? affiliate-sales {influencer: influencer})))
            (new-amount (+ prev-amount amount)))
        
        (map-set affiliate-sales {influencer: influencer} new-amount)
        (map-set sale-receipts 
                {receipt-id: receipt-id} 
                {influencer: influencer, amount: amount, paid: false})
        
        (print {event: "sale-recorded", 
                influencer: influencer, 
                amount: amount, 
                receipt-id: receipt-id})
        (ok new-amount)))))

;; Mark a sale as paid
(define-public (mark-sale-paid (receipt-id (buff 32)))
  (begin
    ;; Validate receipt-id
    (asserts! (validate-receipt-id receipt-id) (err ERR-EMPTY-RECEIPT-ID))
    (asserts! (is-contract-owner) (err ERR-UNAUTHORIZED))
    
    (let ((receipt (map-get? sale-receipts {receipt-id: receipt-id})))
      (asserts! (is-some receipt) (err ERR-RECEIPT-NOT-FOUND))
      
      (map-set sale-receipts 
              {receipt-id: receipt-id} 
              (merge (unwrap-panic receipt) {paid: true}))
      
      (print {event: "sale-paid", receipt-id: receipt-id})
      (ok receipt-id))))

;; Read-only function to calculate the settlement (total affiliate sales) for an influencer
(define-read-only (calculate-settlement (influencer principal))
  (let ((influencer-data (map-get? influencers {influencer: influencer})))
    (asserts! (is-some influencer-data) (err ERR-NOT-REGISTERED))
    (ok (default-to u0 (map-get? affiliate-sales {influencer: influencer})))))

;; Read-only function to calculate the commission amount for an influencer
(define-read-only (calculate-commission (influencer principal))
  (let ((influencer-data (map-get? influencers {influencer: influencer}))
        (sales (default-to u0 (map-get? affiliate-sales {influencer: influencer}))))
    
    (asserts! (is-some influencer-data) (err ERR-NOT-REGISTERED))
    (let ((commission-rate (get commission-rate (unwrap-panic influencer-data))))
      (ok (/ (* sales commission-rate) u1000)))))

;; Get sale receipt details
(define-read-only (get-sale-receipt (receipt-id (buff 32)))
  (match (map-get? sale-receipts {receipt-id: receipt-id})
    receipt (ok receipt)
    (err ERR-RECEIPT-NOT-FOUND)))

;; Check if an influencer is registered and active
(define-read-only (is-active-influencer (influencer principal))
  (match (map-get? influencers {influencer: influencer})
    influencer-data (ok (get active influencer-data))
    (err ERR-NOT-REGISTERED)))
