# Security Policy

## Status

This project is **experimental and has not been professionally audited**. Do not use it to store real student data or in production.

## Supported versions

Only the latest commit on `main` is supported.

## Reporting a vulnerability

Please **do not open a public GitHub issue** for security problems.

Report privately through GitHub's **[private vulnerability reporting](https://github.com/milah-247/StudentGrade-contract/security/advisories/new)** ("Security" tab → "Report a vulnerability").

> Maintainers: private vulnerability reporting must be enabled under *Settings → Code security* for this link to work.

Please include:

- a description of the problem and its impact
- steps to reproduce, ideally as a failing Foundry test
- the commit hash you tested

We aim to reply within 7 days. Please give us a reasonable amount of time to fix the issue before you disclose it publicly.

## Security model

| Role | Can do |
| --- | --- |
| Admin (one account) | Register students, update scores, nominate a new admin |
| Pending admin | Accept the admin role |
| Registered student | Read their own record |
| Anyone else | Read `admin`, `pendingAdmin` and the constants |

Notes:

- **The admin is fully trusted.** A compromised admin key can register fake students and change any score. Use a hardware wallet or multisig for the admin.
- The admin role moves in **two steps** (`transferAdmin` then `acceptAdmin`), so a typo in the new address cannot lock the contract.
- There is no way to remove a student, and no pause switch.

## Privacy limitations (important)

Blockchains are public by design. For this contract that means:

1. **Storage is public.** `students` is `private`, and `getStudent` only answers the admin or the student. But anyone can read raw storage (for example with `cast storage` or `eth_getStorageAt`). The test `test_Privacy_ScoreIsReadableFromRawStorage` demonstrates this.
2. **Transaction inputs are public.** The name and score passed to `addStudent` and `updateScore` are visible in the transaction data forever, including old scores after an update.
3. **Events** emit only the student's address, to avoid making names and scores easier to index. This reduces exposure but does not prevent it (see 1 and 2).
4. **Addresses can be linked to people.** Even without a name, a wallet address and a score can identify a student.

Because of this, **do not record real names or real grades on a public network.** Education-privacy laws (for example FERPA or GDPR) may apply. A safer design would keep records off-chain and store only a hash or commitment on-chain. This is tracked in the issue backlog.

## Known out of scope

- Gas-cost optimisations with no security impact
- Problems that need a compromised admin key
- Issues in `lib/forge-std` (report them upstream)
