
;; dao
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_NOT_TRUSTED_CONTRACT (err u402))

(define-data-var dao-owner principal tx-sender)

(define-map trusted-contracts {key: (string-ascii 80)} {contract-identifier: principal })

(define-read-only (get-dao-owner)
  (var-get dao-owner)
)

(define-read-only (get-contract-identifier (key (string-ascii 80)))
   (ok (unwrap! (get contract-identifier (map-get? trusted-contracts {key: key})) ERR_NOT_TRUSTED_CONTRACT))
)

(define-public (set-dao-owner (address principal))
  (begin
    (asserts! (is-eq contract-caller (var-get dao-owner)) ERR_UNAUTHORIZED)
    (ok (var-set dao-owner address))
  )
)

(define-public (set-contract-identifier (key (string-ascii 80)) (contract-identifier principal))
  (begin 
    (asserts! (is-eq (var-get dao-owner) contract-caller) ERR_UNAUTHORIZED)
    (ok (map-set trusted-contracts {key: key} {contract-identifier: contract-identifier}))
  )
)

(begin
  (map-set trusted-contracts {key: "cube-nft"} { contract-identifier: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.cube-permutations })
)