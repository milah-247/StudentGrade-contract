# StudentGrade-contract

A small Solidity smart contract for recording student scores, built and tested with [Foundry](https://book.getfoundry.sh/).

One admin account registers students and sets their scores (0–100). Each student can read their own record. The admin can hand over the role to another account in two steps.

> **Privacy warning.** Everything on a public blockchain is public. That includes contract storage, events and the inputs of every transaction. The read checks in this contract only limit what its own functions return. Anyone can still read the raw data. **Do not put real student names or real grades on a public network.** See [SECURITY.md](SECURITY.md).

> **Status:** experimental and unaudited. Not for production use.

## Tech stack

| Part | Choice |
| --- | --- |
| Language | Solidity `^0.8.24` (compiled with `0.8.28`, pinned in `foundry.toml`) |
| Framework | Foundry (`forge`) |
| Test library | [forge-std](https://github.com/foundry-rs/forge-std) (git submodule in `lib/`) |
| CI | GitHub Actions: format check, build, tests, Slither |

## Contract overview

Source: [`src/StudentGrades.sol`](src/StudentGrades.sol)

| Function | Who can call | What it does |
| --- | --- | --- |
| `addStudent(address, string name, uint256 score)` | admin | Registers a new student. Rejects the zero address, duplicates, empty names, names over 64 bytes and scores over 100. |
| `updateScore(address, uint256 newScore)` | admin | Changes a registered student's score. Rejects unknown students and scores over 100. |
| `getStudent(address)` | admin, or the student themselves | Returns `(name, score)`. |
| `viewMyGrade()` | any registered student | Returns the caller's own `(name, score)`. |
| `transferAdmin(address newAdmin)` | admin | Nominates a new admin. Calling it again replaces the nominee. |
| `acceptAdmin()` | the nominated admin | Completes the handover. |
| `admin()`, `pendingAdmin()`, `MAX_SCORE()`, `MAX_NAME_LENGTH()` | anyone | Public getters. |

Errors are custom errors (for example `NotAdmin()`, `InvalidScore(uint256)` and `StudentNotFound(address)`), defined at the top of the contract.

Events: `StudentAdded(student)`, `ScoreUpdated(student)`, `AdminTransferStarted(current, pending)` and `AdminTransferred(previous, new)`. Events leave out names and scores on purpose.

## Getting started

### Prerequisites

- [Git](https://git-scm.com/)
- Foundry. Install it with `foundryup`, following the [official guide](https://book.getfoundry.sh/getting-started/installation).

### Setup

```shell
git clone --recurse-submodules https://github.com/milah-247/StudentGrade-contract.git
cd StudentGrade-contract

# If you cloned without --recurse-submodules:
git submodule update --init --recursive
```

### Common commands

```shell
forge build              # compile
forge test -vvv          # run all tests
forge test --match-test test_UpdateScore -vvv   # run matching tests
forge fmt                # format code (CI runs `forge fmt --check`)
forge coverage           # coverage report
forge snapshot           # gas snapshot
```

To run the same fuzz settings as CI:

```shell
FOUNDRY_PROFILE=ci forge test
```

### Static analysis (optional)

```shell
python3 -m venv .venv && . .venv/bin/activate
pip install slither-analyzer==0.10.4
slither . --filter-paths "lib/|test/" --fail-medium
```

## Project layout

```
src/StudentGrades.sol        contract
test/StudentGrades.t.sol     Foundry tests (unit + fuzz)
lib/forge-std                test library (submodule)
.github/workflows/test.yml   CI
```

## Deployment

There is no deployment script yet; it is tracked as an open issue. If you deploy manually, use a local test network (`anvil`) or a testnet. Never pass a private key on the command line or commit one. Use `cast wallet import` and `--account` instead.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Security reports go through [SECURITY.md](SECURITY.md), not public issues.

## License

The source files carry `SPDX-License-Identifier: MIT`.
