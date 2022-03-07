;; cube-permutations
(impl-trait .sip-009-nft-trait.nft-trait)

(define-constant contract-owner tx-sender)
(define-constant contract (as-contract tx-sender))

(define-constant mint-cost u100)

(define-constant err-owner-only (err u100))
(define-constant err-unauthorized (err u101))
(define-constant err-cube-not-found (err u102))
(define-constant err-cube-exists (err u103))
(define-constant err-illegal-permutation (err u104))

;; primes as color weights
(define-constant red u73)
(define-constant green u79)
(define-constant blue u83)
(define-constant white u89)
(define-constant yellow u97)
(define-constant orange u101)

;; fully solved cube arrangement  
(define-constant cube-arrangement (list 
    red red red red red red red red red                             ;; front
    blue blue blue blue blue blue blue blue blue                    ;; top
    white white white white white white white white white           ;; bottom
    green green green green green green green green green           ;; left
    yellow yellow yellow yellow yellow yellow yellow yellow yellow  ;; right
    orange orange orange orange orange orange orange orange orange  ;; back
))

;; positions starting from value 1
(define-constant indices (list 
    u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 
    u19 u20 u21 u22 u23 u24 u25 u26 u27 u28 u29 u30 u31 u32 u33 u34 
    u35 u36 u37 u38 u39 u40 u41 u42 u43 u44 u45 u46 u47 u48 u49 u50 
    u51 u52 u53 u54
))

;; cube tokens with hash as id 
(define-non-fungible-token rubiks-cube (buff 20))
(define-data-var last-token-id uint u1)

;; cube id -> cube hash
(define-map cube-hash uint (buff 20))
;; cube id -> block-height
(define-map cube-info uint uint)
;; cube id -> token uri
(define-map cubes-uri uint (optional (string-ascii 256)))

(define-private (get-cube-hash-by-id (cube-id uint)) 
    (default-to 0x (map-get? cube-hash cube-id))
)

;; SIP-009 trait starts
(define-read-only (get-last-token-id) 
    (ok (- (var-get last-token-id) u1))
)

;; todo
(define-read-only (get-token-uri (token-id uint)) 
    (ok none)
)

(define-read-only (get-owner (token-id uint)) 
    (ok (nft-get-owner? rubiks-cube (get-cube-hash-by-id token-id)))
)

(define-public (transfer (token-id uint) (owner principal) (recipient principal)) 
    (let 
        (
            (cube-owner (unwrap! (get-owner token-id) err-cube-not-found))
        ) 
        (asserts! (is-eq cube-owner (some owner)) err-unauthorized)
        (try! (nft-transfer? rubiks-cube (get-cube-hash-by-id token-id) owner recipient))
        (ok true)
    )
)
;; SIP-009 trait ends

(define-read-only (get-metadata (cube-id uint)) 
    (let
        (
            (uri (unwrap! (map-get? cubes-uri cube-id) err-cube-not-found))
            (cube (unwrap! (map-get? cube-info cube-id) err-cube-not-found))
            (hash (unwrap! (map-get? cube-hash cube-id) err-cube-not-found))
        ) 
        (ok {cube: cube, uri: uri, hash: hash})
    )
)

(define-public (set-token-uri (token-id uint) (uri (optional (string-ascii 256)))) 
    (begin
        (asserts! (is-eq (nft-get-owner? rubiks-cube (get-cube-hash-by-id token-id)) (some tx-sender)) err-unauthorized)
        (ok (map-set cubes-uri token-id uri))
    )
)

(define-private (multiply-value-with-position (number uint) (position uint)) 
    (* number position)
)

(define-read-only (calculate-hash (cube (list 54 uint)))
    (hash160 (fold + (map multiply-value-with-position cube indices) u0))
)

;; cube arrangement is legal and solvable ?
(define-private (is-legal (cube (list 54 uint)))
    ;; todo - mentioned in readme 
    true
)

;; mint a new pattern by paying fee
(define-public (mint (cube (list 54 uint)) (uri (optional (string-ascii 256)))) 
    (let 
        (
            (hash (calculate-hash cube))
            (id (var-get last-token-id))
        )
        (asserts! (is-legal cube) err-illegal-permutation)
        (map-set cube-hash id hash)
        (map-set cube-info id block-height)
        (map-set cubes-uri id uri)
        (var-set last-token-id (+ (var-get last-token-id) u1))
        (try! (nft-mint? rubiks-cube hash tx-sender))
        (ok {cube-hash: hash, cube-id: id, created-at: block-height})
    )
)