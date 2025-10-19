📜 Legacy Letters Smart Contract

Overview

The Legacy Letters Contract enables users to write and store encrypted messages for future generations, which become accessible only after a specified number of years. Each message (“letter”) is securely recorded on the Stacks blockchain and can only be unlocked when the blockchain height passes the designated unlock time.

This contract preserves memories, personal reflections, or historical messages meant to be opened long after their creation — functioning as a time-locked vault for digital legacies.

🧩 Core Features

Letter Creation (create-letter)

Allows a sender to create a new letter.

Each letter includes:

The encrypted message content (up to 2000 ASCII characters)

An optional recipient (who can later unlock it)

The duration in years before it becomes unlockable

Auto-calculated unlock block height (unlock-years * 52560, assuming 10-minute blocks)

Validation checks:

unlock-years must be greater than 0

Message length must be within the limit

Unlocking Letters (unlock-letter)

Allows authorized users to unlock a letter after the unlock time.

Only the sender or recipient can unlock it.

Prevents double unlocking or early access.

On success, grants access rights to the unlocking principal.

Letter Access Tracking (letter-access)

Keeps a record of who has unlocked or been granted access to a particular letter.

Read-Only Functions

get-letter(letter-id) → Retrieve basic metadata about a letter.

get-letter-content(letter-id) → Returns the encrypted content only if unlocked and caller is authorized.

can-unlock-letter(letter-id) → Checks if a letter is eligible for unlocking.

get-total-letters() → Returns total number of letters ever created.

blocks-until-unlock(letter-id) → Shows how many blocks remain before the letter can be opened.

🔒 Error Codes
Code	Meaning	Description
u404	ERR-NOT-FOUND	Letter does not exist
u403	ERR-NOT-AUTHORIZED	Caller is not the sender or recipient
u409	ERR-ALREADY-UNLOCKED	Letter already unlocked
u425	ERR-TOO-EARLY	Unlock attempted before unlock time
u400	ERR-INVALID-TIME	Invalid unlock duration or content length

🧠 Data Structures
Data Variables

next-letter-id → Tracks the ID to assign to the next created letter

Data Maps

letters → Stores all letter data indexed by letter-id

letter-access → Maps access permissions by { letter-id, accessor }

⏳ Time Calculation

The contract uses block height as the measure of time.
Since the Stacks blockchain produces a block approximately every 10 minutes, one year is approximated as 52,560 blocks.

Formula:

unlock-height = current-block + (unlock-years * 52560)

⚙️ Example Flow

Alice creates a letter

(contract-call? .legacy-letters create-letter "Encrypted Hello Future!" u10 (some 'SP2C2...))


→ Creates a letter to be unlocked after 10 years.

Bob tries to unlock early

(contract-call? .legacy-letters unlock-letter u1)


→ Returns (err u425) since the unlock time hasn’t arrived.

After the unlock height passes

Alice or Bob can successfully unlock it using unlock-letter.

After unlocking, get-letter-content returns the encrypted message.

🧾 License
This smart contract is open-source under the MIT License.