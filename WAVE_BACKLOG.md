# Drips Wave issue backlog (draft for maintainer review)

These are draft GitHub issues. Nothing has been published. Review them, then create the ones you agree with as GitHub issues and set their complexity in the Drips Wave app. Delete this file once the issues exist.

Points follow the Drips Wave scale: **Trivial = 100**, **Medium = 150**, **High = 200**.

> **Decision needed first:** Wave Programs are ecosystem-specific (the current one is Stellar), and the docs ask maintainers to "only apply to Programs that are relevant to your ecosystem". This repo is Solidity/EVM, not Stellar Soroban. Before applying, confirm which Program this repo fits, or decide whether to port the contract to Soroban. See issue 15.

Unless a dependency is listed, every issue can start from current `main`. Each issue builds on this branch's contract (custom errors, `updateScore`, two-step admin).

## Summary

| # | Title | Type | Complexity | Points | Depends on |
|---|---|---|---|---|---|
| 1 | Add `removeStudent` for the admin | feature | Medium | 150 | – |
| 2 | Add `cancelAdminTransfer` | feature | Trivial | 100 | – |
| 3 | Add a Foundry deployment script with keystore-based signing | devex | Medium | 150 | – |
| 4 | Add invariant tests with a handler | testing | High | 200 | – |
| 5 | Add coverage reporting to CI | devex / testing | Trivial | 100 | – |
| 6 | Add gas snapshot check to CI | devex | Trivial | 100 | – |
| 7 | Add batch registration `addStudents` | feature | Medium | 150 | – |
| 8 | Support several graders (teacher role) | feature / security | High | 200 | – |
| 9 | Replace on-chain names with a hashed commitment | security / privacy | High | 200 | needs maintainer design sign-off |
| 10 | Add `isRegistered` for the admin and the student | feature | Trivial | 100 | – |
| 11 | Add a Slither config and document triaged findings | security / devex | Trivial | 100 | – |
| 12 | Add Dependabot for GitHub Actions and the forge-std submodule | devex | Trivial | 100 | – |
| 13 | Write an architecture and threat-model doc | docs | Medium | 150 | – |
| 14 | Add a pure `letterGrade(uint256)` helper | feature | Trivial | 100 | – |
| 15 | Spike: port the contract to Stellar Soroban (Rust) | decision / high effort | High | 200 | maintainer decision |

---

## 1. Add `removeStudent` for the admin

**Labels:** `enhancement`, `smart-contract`, `Stellar Wave`*  ·  **Complexity:** Medium (150)  ·  **Depends on:** none

**Problem.** Once a student is registered, there is no way to remove a record. A wrong address or a withdrawn student stays forever.

**Scope.**
- Add `removeStudent(address studentAddress)`, admin only.
- Delete the record (`delete students[addr]`) so `exists` becomes false and the slot is cleared.
- Emit `StudentRemoved(address indexed student)` with no name or score.
- Revert with `StudentNotFound(address)` if the student is not registered.
- After removal, the same address can be registered again.

**Acceptance criteria.**
- [ ] Only the admin can remove a student (`NotAdmin` otherwise).
- [ ] `getStudent` and `viewMyGrade` revert after removal.
- [ ] Re-registering the address works.
- [ ] README function table updated.

**Testing.** Unit tests for success, event, non-admin, student removing self, missing student, and re-registration. A fuzz test with random non-admin callers.

*Replace `Stellar Wave` with the label for whichever Program the repo is approved for.*

---

## 2. Add `cancelAdminTransfer`

**Labels:** `enhancement`, `smart-contract`, `good first issue`  ·  **Complexity:** Trivial (100)  ·  **Depends on:** none

**Problem.** After `transferAdmin`, the admin can only replace the nominee, not clear it. A wrong nominee stays able to accept until replaced.

**Scope.** Add `cancelAdminTransfer()`, admin only. It sets `pendingAdmin` to `address(0)` and emits `AdminTransferCancelled(address indexed cancelledPendingAdmin)`. Revert if there is no pending transfer (add a custom error).

**Acceptance criteria.**
- [ ] After cancelling, the old nominee's `acceptAdmin` reverts with `NotPendingAdmin`.
- [ ] Non-admins cannot cancel.
- [ ] Cancelling with nothing pending reverts.

**Testing.** Unit tests for each criterion, plus the event.

---

## 3. Add a Foundry deployment script with keystore-based signing

**Labels:** `devex`, `documentation`  ·  **Complexity:** Medium (150)  ·  **Depends on:** none

**Problem.** There is no deployment script, and the old README example used `--private-key`, which leaks keys into shell history.

**Scope.**
- `script/DeployStudentGrades.s.sol` using `vm.startBroadcast()`.
- README section: deploy to local `anvil` and to a testnet using `cast wallet import` + `--account`. No private keys on the command line.
- Optional: an env var for an initial admin to nominate with `transferAdmin` after deploy.
- No real RPC keys or addresses committed. Add `.env.example` if env vars are used.

**Acceptance criteria.**
- [ ] `forge script script/DeployStudentGrades.s.sol` succeeds against `anvil`.
- [ ] Docs contain no `--private-key` usage.
- [ ] CI compiles the script (`forge build` already covers `script/`).

**Testing.** A Foundry test that runs the script's `run()` and checks the deployed admin.

---

## 4. Add invariant tests with a handler

**Labels:** `testing`, `security`  ·  **Complexity:** High (200)  ·  **Depends on:** none (extend it if #1 or #8 land first)

**Problem.** Tests are unit and fuzz tests only. Nothing checks that properties hold across random sequences of calls.

**Scope.** Add `test/invariant/` with a handler contract that calls `addStudent`, `updateScore`, `transferAdmin` and `acceptAdmin` from random actors, plus ghost variables tracking registered students.

Invariants to cover:
- every registered student's score is `<= MAX_SCORE`
- a registered student's name is never empty or longer than `MAX_NAME_LENGTH`
- `admin` only changes through `acceptAdmin` by the pending admin
- `admin` is never `address(0)`
- calls from non-admins never change any record

**Acceptance criteria.**
- [ ] Invariant tests pass with `FOUNDRY_PROFILE=ci`.
- [ ] Each invariant has a comment explaining it.
- [ ] Invariant run and depth settings are added to `foundry.toml`.

**Testing.** The issue is the tests. Show in the PR that each invariant fails when you plant a deliberate bug locally (don't commit the bug).

---

## 5. Add coverage reporting to CI

**Labels:** `devex`, `testing`, `good first issue`  ·  **Complexity:** Trivial (100)  ·  **Depends on:** none

**Problem.** CI doesn't report coverage, so reviewers can't see untested lines.

**Scope.** Add a CI step that runs `forge coverage --report summary --report lcov --no-match-coverage "(test|script)"` and uploads `lcov.info` as an artifact. Do not add third-party upload services or secrets.

**Acceptance criteria.**
- [ ] The coverage summary appears in the CI log.
- [ ] The `lcov.info` artifact is attached to the run.
- [ ] README mentions how to run coverage locally.

**Testing.** Link a CI run from your fork in the PR.

---

## 6. Add gas snapshot check to CI

**Labels:** `devex`, `good first issue`  ·  **Complexity:** Trivial (100)  ·  **Depends on:** none

**Problem.** Gas regressions go unnoticed.

**Scope.** Commit a `.gas-snapshot` generated with `forge snapshot`, add `forge snapshot --check` to CI, and document how to update it.

**Acceptance criteria.**
- [ ] CI fails if gas changes without an updated snapshot.
- [ ] CONTRIBUTING explains `forge snapshot` for updates.
- [ ] Fuzz tests are excluded or seeded so the snapshot is deterministic.

**Testing.** Show a CI run that passes, and a local run that fails after a deliberate change.

---

## 7. Add batch registration `addStudents`

**Labels:** `enhancement`, `smart-contract`  ·  **Complexity:** Medium (150)  ·  **Depends on:** none

**Problem.** Registering a class takes one transaction per student.

**Scope.**
- `addStudents(address[] calldata, string[] calldata, uint256[] calldata)`, admin only.
- Revert on mismatched lengths, an empty batch or more than `MAX_BATCH_SIZE` (constant, for example 50).
- Apply the same validation as `addStudent` by sharing an internal function, not duplicating code.
- Atomic: one bad entry reverts the whole batch.

**Acceptance criteria.**
- [ ] Same errors as `addStudent` for invalid entries.
- [ ] A duplicate inside the same batch reverts.
- [ ] One `StudentAdded` event per student.

**Testing.** Unit tests for each revert path and for atomicity (nothing stored after a failing batch). A fuzz test for length mismatches.

---

## 8. Support several graders (teacher role)

**Labels:** `enhancement`, `security`, `smart-contract`  ·  **Complexity:** High (200)  ·  **Depends on:** none. Conflicts with #7 and #1 if they are developed at the same time; coordinate in comments.

**Problem.** One admin key does everything. Real schools need several teachers who can grade, while one admin manages who those teachers are.

**Scope.**
- Add a grader role: `addGrader` / `removeGrader` (admin only), and `isGrader` view.
- Graders can call `updateScore`. Decide in the issue whether graders can also register students.
- Events for role changes.
- Write it without new dependencies unless the maintainer approves adding OpenZeppelin.

**Acceptance criteria.**
- [ ] A removed grader immediately loses access.
- [ ] Graders cannot manage graders or transfer admin.
- [ ] SECURITY.md role table updated.

**Testing.** Unit and fuzz tests for every role/function pair. Extend #4 invariants if merged.

---

## 9. Replace on-chain names with a hashed commitment

**Labels:** `security`, `privacy`, `breaking-change`, `needs-design`  ·  **Complexity:** High (200)  ·  **Depends on:** maintainer sign-off on the design in the issue thread before coding

**Problem.** Names are stored in plain text, and both names and scores appear in calldata. All of that is public forever (see SECURITY.md).

**Scope.**
- Store `bytes32 recordCommitment` instead of `string name`, for example `keccak256(abi.encode(studentId, salt))` computed off-chain.
- Decide in the issue whether scores also move to commitments, and what then remains useful on-chain.
- Update the API, events, tests, README and SECURITY.md.
- Document the off-chain flow for verifying a record.

**Acceptance criteria.**
- [ ] No plain-text personal data is stored or passed in calldata.
- [ ] Commitments with zero values are rejected.
- [ ] Docs explain the salt handling and that a lost salt cannot be recovered.

**Testing.** Unit tests, plus a test showing a known (id, salt) pair verifies against the stored commitment and a wrong salt does not.

---

## 10. Add `isRegistered` for the admin and the student

**Labels:** `enhancement`, `good first issue`  ·  **Complexity:** Trivial (100)  ·  **Depends on:** none

**Problem.** The only way to check whether an address is registered is to call `getStudent` and catch the revert.

**Scope.** `isRegistered(address) external view returns (bool)`, callable by the admin or by that address (`NotAuthorized` otherwise), matching `getStudent`'s rule.

**Acceptance criteria.**
- [ ] Returns true or false correctly for the admin and for the student.
- [ ] Other callers get `NotAuthorized`.

**Testing.** Unit tests for each caller type and for registered and unregistered addresses.

---

## 11. Add a Slither config and document triaged findings

**Labels:** `security`, `devex`, `good first issue`  ·  **Complexity:** Trivial (100)  ·  **Depends on:** none

**Problem.** CI runs Slither with command-line flags only. Nobody has recorded which findings are accepted and why.

**Scope.** Add `slither.config.json` (filter paths, excluded detectors with reasons), run Slither, and record each low or informational finding with a short decision in `docs/` or SECURITY.md. Note that `docs/` is currently in `.gitignore`, so either change that or use another path.

**Acceptance criteria.**
- [ ] CI uses the config file.
- [ ] Every remaining finding has a written decision.
- [ ] No detector is silenced without a reason.

**Testing.** Paste the Slither output in the PR.

---

## 12. Add Dependabot for GitHub Actions and the forge-std submodule

**Labels:** `devex`, `good first issue`  ·  **Complexity:** Trivial (100)  ·  **Depends on:** none

**Problem.** Action versions and the `forge-std` submodule are never updated automatically.

**Scope.** Add `.github/dependabot.yml` with the `github-actions` and `gitsubmodule` ecosystems on a weekly or monthly schedule.

**Acceptance criteria.**
- [ ] The config is valid (GitHub shows it under Insights → Dependency graph → Dependabot).
- [ ] CONTRIBUTING mentions how dependency PRs are handled.

**Testing.** Link a screenshot or log from a fork showing Dependabot picked up the config.

---

## 13. Write an architecture and threat-model doc

**Labels:** `documentation`, `security`  ·  **Complexity:** Medium (150)  ·  **Depends on:** none

**Problem.** New contributors have no single place that explains roles, trust assumptions, storage layout and what an attacker could do.

**Scope.** Add `ARCHITECTURE.md` with:
- roles and permissions
- the storage layout table (slots), linked to the raw-storage privacy test
- a sequence diagram (Mermaid) for registration and the admin handover
- a threat model: compromised admin, wrong nominee, front-running, data exposure and griefing, each with its mitigation or "accepted"

**Acceptance criteria.**
- [ ] Every statement matches the current code. Reviewers will check this.
- [ ] Linked from the README.

**Testing.** None needed for code. The PR description should list how each claim was checked.

---

## 14. Add a pure `letterGrade(uint256)` helper

**Labels:** `enhancement`, `good first issue`  ·  **Complexity:** Trivial (100)  ·  **Depends on:** none

**Problem.** Frontends must each re-implement the score-to-letter mapping, and they may disagree.

**Scope.** `function letterGrade(uint256 score) external pure returns (bytes1)`, mapping A: 90–100, B: 80–89, C: 70–79, D: 60–69 and F: 0–59. Revert with `InvalidScore` above 100. Document the thresholds in NatSpec and the README.

**Acceptance criteria.**
- [ ] Every boundary (0, 59, 60, 69, 70, 79, 80, 89, 90, 100, 101) is tested.

**Testing.** Unit tests for the boundaries, plus a fuzz test against a reference implementation in the test.

---

## 15. Spike: port the contract to Stellar Soroban (Rust)

**Labels:** `needs-decision`, `soroban`, `enhancement`  ·  **Complexity:** High (200)  ·  **Depends on:** maintainer decision. Do **not** assign until the maintainer confirms the direction.

**Problem.** If this repo is meant for the Stellar Wave, the Solidity/EVM contract is likely out of ecosystem.

**Scope.**
- A new Soroban contract (`contracts/student-grades/`) with the same behaviour: admin with `require_auth`, register, update, self-read, two-step admin transfer, and the same validation.
- Use `soroban-sdk` with `testutils`, and `#[contracterror]` errors.
- Tests that match the Solidity suite case for case.
- CI: `cargo fmt --check`, `cargo clippy -- -D warnings`, `cargo test` and the wasm build.
- Decide in the issue whether the Solidity version is kept or removed.

**Acceptance criteria.**
- [ ] Feature parity table in the PR.
- [ ] Persistent storage TTL is handled (`extend_ttl`) and documented.
- [ ] The same privacy warning appears in the README.

**Testing.** `cargo test` covering every case in `test/StudentGrades.t.sol`.

---

## Notes for the maintainer

- The issues are written to be independent. #1, #7 and #8 touch the same functions, so assign them to different Waves or ask contributors to rebase.
- Issues added by GitHub label alone default to **Trivial** in the Drips app. Set Medium and High in the app.
- Check your Program's Points budget before adding everything at once (see the Drips "Points budgets" page).
