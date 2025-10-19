;; Legacy Letters Contract
;; Allows people to write encrypted letters to future generations, unlockable after X years

;; constants
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-NOT-AUTHORIZED (err u403))
(define-constant ERR-ALREADY-UNLOCKED (err u409))
(define-constant ERR-TOO-EARLY (err u425))
(define-constant ERR-INVALID-TIME (err u400))

;; data vars
(define-data-var next-letter-id uint u1)

;; data maps
(define-map letters
  uint
  {
    sender: principal,
    recipient: (optional principal),
    encrypted-content: (string-ascii 2000),
    unlock-height: uint,
    created-at: uint,
    is-unlocked: bool
  }
)

(define-map letter-access
  { letter-id: uint, accessor: principal }
  bool
)

;; public functions

(define-public (create-letter (encrypted-content (string-ascii 2000)) (unlock-years uint) (recipient (optional principal)))
  (let (
    (letter-id (var-get next-letter-id))
    (current-height block-height)
    (unlock-height (+ current-height (* unlock-years u52560)))
    (validated-recipient (if (is-some recipient)
      recipient
      none
    ))
  )
    (asserts! (> unlock-years u0) ERR-INVALID-TIME)
    (asserts! (< (len encrypted-content) u2001) ERR-INVALID-TIME)

    (map-set letters letter-id {
      sender: tx-sender,
      recipient: validated-recipient,
      encrypted-content: encrypted-content,
      unlock-height: unlock-height,
      created-at: current-height,
      is-unlocked: false
    })

    (var-set next-letter-id (+ letter-id u1))
    (ok letter-id)
  )
)

(define-public (unlock-letter (letter-id uint))
  (let (
    (letter-data (unwrap! (map-get? letters letter-id) ERR-NOT-FOUND))
  )
    (asserts! (>= block-height (get unlock-height letter-data)) ERR-TOO-EARLY)
    (asserts! (not (get is-unlocked letter-data)) ERR-ALREADY-UNLOCKED)
    (asserts! 
      (or 
        (is-eq tx-sender (get sender letter-data))
        (match (get recipient letter-data)
          recipient-addr (is-eq tx-sender recipient-addr)
          true
        )
      ) 
      ERR-NOT-AUTHORIZED
    )

    (map-set letters letter-id (merge letter-data { is-unlocked: true }))
    (map-set letter-access { letter-id: letter-id, accessor: tx-sender } true)
    (ok true)
  )
)

;; read only functions

(define-read-only (get-letter (letter-id uint))
  (map-get? letters letter-id)
)

(define-read-only (get-letter-content (letter-id uint))
  (let (
    (letter-data (unwrap! (map-get? letters letter-id) ERR-NOT-FOUND))
  )
    (if (get is-unlocked letter-data)
      (if (or
        (is-eq contract-caller (get sender letter-data))
        (match (get recipient letter-data)
          recipient-addr (is-eq contract-caller recipient-addr)
          true
        )
        (default-to false (map-get? letter-access { letter-id: letter-id, accessor: contract-caller }))
      )
        (ok (get encrypted-content letter-data))
        ERR-NOT-AUTHORIZED
      )
      ERR-TOO-EARLY
    )
  )
)

(define-read-only (can-unlock-letter (letter-id uint))
  (match (map-get? letters letter-id)
    letter-data (ok (and 
      (>= block-height (get unlock-height letter-data))
      (not (get is-unlocked letter-data))
    ))
    ERR-NOT-FOUND
  )
)

(define-read-only (get-total-letters)
  (- (var-get next-letter-id) u1)
)

(define-read-only (blocks-until-unlock (letter-id uint))
  (match (map-get? letters letter-id)
    letter-data (let (
      (current-height block-height)
      (unlock-height (get unlock-height letter-data))
    )
      (ok (if (>= current-height unlock-height)
        u0
        (- unlock-height current-height)
      ))
    )
    ERR-NOT-FOUND
  )
)
