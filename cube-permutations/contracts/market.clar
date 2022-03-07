;; market place for sip-009 tokens 
;; payment can be made using stx or SIP-010 tokens 

(define-trait sip009-transfer-trait
	(
        (get-owner (uint) (response (optional principal) uint))
		(transfer (uint principal principal) (response bool uint))
	)
)

(define-trait sip010-transfer-trait
	(
		(transfer (uint principal principal (optional (buff 34))) (response bool uint))
	)
)

(define-constant contract-owner tx-sender)
(define-constant contract (as-contract tx-sender))

(define-constant err-owner-only (err u100))
(define-constant err-unauthorized (err u101))
(define-constant err-no-item (err u102))
(define-constant err-cube-exists (err u103))
(define-constant err-duplicate (err u200))
(define-constant err-invalid-price (err u201))
(define-constant err-invalid-offer (err u202))
(define-constant err-sale-expired (err u203))
(define-constant err-sale-not-expired (err u204))
(define-constant err-invalid-bid-id (err u205))
(define-constant err-no-offers (err u206))
(define-constant err-invalid-contract (err u207))

(define-data-var bid-id uint u0)

;; todo: need to re-think these maps for efficiency 
(define-map auction 
    {item-owner: principal, item-id: uint, item-contract: principal} 
    {bid-id: uint, min-price: uint, duration: uint})

;; bidder, bid-id -> offer (price)
(define-map offers 
    {bidder: principal, bid-id: uint} 
    {offer: uint, accepted: bool})

;; bid id -> item info 
;; todo: rename to auction-info?
(define-map item-info
    uint
    {item-owner: principal, item-id: uint, item-contract: principal})

;; bid id -> max offer
(define-map max-offer uint {bidder: principal, offer: uint})

(define-private (get-auction-info (id uint)) 
    (let ((item (map-get? item-info id)))
        (match item info (map-get? auction (unwrap-panic item)) none)
    )
)

(define-private (get-offer-info (bidder principal) (id uint))
    (default-to {offer: u0, accepted: false} (map-get? offers {bidder: bidder, bid-id: id}))
)

(define-read-only (get-max-offer (id uint))
    (map-get? max-offer id)
)

(define-private (transfer-tradable-to-escrow (tradables <sip009-transfer-trait>) (tradable-id uint))
    (contract-call? tradables transfer tradable-id tx-sender contract)
)

(define-private (transfer-tradable-from-escrow (tradables <sip009-transfer-trait>) (tradable-id uint) (owner principal))
    (as-contract (contract-call? tradables transfer tradable-id contract owner))
)

(define-public (put-on-sale (sip009-trait <sip009-transfer-trait>) (item-id uint) (min-price uint) (till-height uint)) 
    (let
        (
            (owner (unwrap! (unwrap! (contract-call? sip009-trait get-owner item-id) err-no-item) err-no-item))
            (id (var-get bid-id))
        )
        (asserts! (is-eq owner tx-sender) err-unauthorized)
        (asserts! (> min-price u0) err-invalid-price)
        (asserts! (< block-height till-height) err-sale-expired)
        (map-set item-info id {item-owner: owner, item-id: item-id, item-contract: (contract-of sip009-trait)})
        (if (map-insert auction {item-owner: owner, item-id: item-id, item-contract: (contract-of sip009-trait)} 
            {min-price: min-price, duration: till-height, bid-id: id}) 
            (begin 
                (var-set bid-id (+ u1 id))
                (ok id))
            err-duplicate
        )
    )
)

(define-public (cancel-sale (id uint)) 
    (ok true)
)

(define-public (bid (offer uint) (id uint)) 
    (let 
        (
            (auction-info (unwrap! (get-auction-info id) err-invalid-bid-id))
            (prev-offer (get-offer-info tx-sender id))
            (highest (map-get? max-offer id))     ;; todo
        )
        (asserts! (< block-height (get duration auction-info)) err-sale-expired)
        (asserts! (>= offer (get min-price auction-info)) err-invalid-offer)
        (asserts! (> offer (get offer prev-offer)) err-invalid-offer)
        (asserts! (not (get accepted prev-offer)) err-invalid-offer)

        (map-set offers {bidder: tx-sender, bid-id: id} {offer: offer, accepted: false})
        (stx-transfer? (- offer (get offer prev-offer)) tx-sender contract)
    )
)

(define-public (cancel-bid (id uint)) 
    (ok true)
)

;; complete an auction, when duration expires 
(define-public (complete-auction (trait <sip009-transfer-trait>) (id uint)) 
    (let 
        (
            (item-details (unwrap! (map-get? item-info id) err-invalid-bid-id))
            (auction-info (unwrap! (get-auction-info id) err-invalid-bid-id))
            (offer-info (unwrap! (get-max-offer id) err-no-offers))
            (bidder (get bidder offer-info))
        )
        (asserts! (is-eq (contract-of trait) (get item-contract item-details)) err-invalid-contract)
        (asserts! (> block-height (get duration auction-info)) err-sale-not-expired)
        (map-delete auction item-details)
        (map-delete item-info id)
        (map-delete offers {bidder: bidder, bid-id: id})
        (map-delete max-offer id)
        (try! (as-contract (stx-transfer? (get offer offer-info) contract (get item-owner item-details))))
        (try! (transfer-tradable-from-escrow trait (get item-id item-details) bidder))
        (ok true)
    )
)

(define-public (accept-offer) 
    (ok true)
)