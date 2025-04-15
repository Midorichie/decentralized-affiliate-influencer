;; Define a mapping for storing registered influencers
(define-map influencers {influencer: principal} bool)
;; Define a mapping for storing affiliate sales totals per influencer
(define-map affiliate-sales {influencer: principal} uint)
;; Public function to register an influencer partner
(define-public (register-influencer (influencer principal))
  (if (is-some (map-get? influencers {influencer: influencer}))
      (err u100)  ;; Error code u100: Influencer already registered
      (begin
        (map-set influencers {influencer: influencer} true)
        (print { event: "influencer-added", influencer: influencer })
        (ok influencer)
      )))
;; Public function to record a sale (conversion) for a registered influencer
(define-public (record-sale (influencer principal) (amount uint))
  (if (not (is-some (map-get? influencers {influencer: influencer})))
      (err u101)  ;; Error code u101: Influencer not registered
      (let
        (
          (prev-amount (default-to u0 (map-get? affiliate-sales {influencer: influencer})))
          (new-amount (+ prev-amount amount))
        )
        (map-set affiliate-sales {influencer: influencer} new-amount)
        (print { event: "sale-recorded", influencer: influencer, amount: amount })
        (ok new-amount)
      )))
;; Read-only function to calculate the settlement (total affiliate sales) for an influencer
(define-read-only (calculate-settlement (influencer principal))
  (if (not (is-some (map-get? influencers {influencer: influencer})))
      (err u102)  ;; Error code u102: Influencer not registered
      (ok (default-to u0 (map-get? affiliate-sales {influencer: influencer})))
  ))
