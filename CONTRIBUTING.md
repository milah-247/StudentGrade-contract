# Contributing

Thanks for helping out! This guide covers how to pick up work, set up the project, and get a pull request merged.

## Picking an issue

1. Look for open issues, especially ones labelled `good first issue` or tagged for a Drips Wave.
2. Comment on the issue (or apply through the Drips Wave app during a Wave) and wait to be **assigned** before starting. This avoids two people doing the same work.
3. One pull request per issue. If you find something extra, open a new issue for it.
4. If an issue is unclear, ask in the issue before writing code.

## Setup

Follow **Getting started** in the [README](README.md). In short:

```shell
git clone --recurse-submodules https://github.com/milah-247/StudentGrade-contract.git
cd StudentGrade-contract
forge build && forge test
```

## Before you open a pull request

Run the same checks as CI. All of them must pass:

```shell
forge fmt --check
forge build --sizes
FOUNDRY_PROFILE=ci forge test -vvv
```

Slither is optional locally but runs in CI. See the README.

## Code guidelines

- **Tests are required.** Every behaviour change needs tests. That includes the success path, every revert path (checked with the exact custom error) and edge cases such as 0, the maximum and max + 1.
- **Don't weaken existing tests** to make them pass. If a test is wrong, explain why in the PR.
- Use custom errors (`error Foo();` + `revert Foo();`), not revert strings.
- Every external function that changes state must check access control and emit an event.
- Add NatSpec (`/// @notice`, `/// @param`) to public and external functions.
- **Privacy:** do not add features that put more personal data on-chain (for example emails, ID numbers or birth dates), or that put names or scores into events, without discussing it in an issue first.
- If you change the storage layout, update `test_Privacy_ScoreIsReadableFromRawStorage`.
- Keep changes focused. Don't reformat unrelated files.

## Commits and pull requests

- Branch from `main` with a descriptive name, for example `feat/remove-student` or `test/invariants`.
- Write clear commit messages, for example `feat: add removeStudent`.
- In the PR description, link the issue (`Closes #12`), summarise the change and paste the `forge test` summary.
- Keep PRs small. Large PRs are hard to review within a Wave cycle.

## Security issues

Do **not** open a public issue for a vulnerability. Follow [SECURITY.md](SECURITY.md).

## Code of conduct

Be respectful and constructive. Maintainers may close issues or PRs that are abusive or spam.
