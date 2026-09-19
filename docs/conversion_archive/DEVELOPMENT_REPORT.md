# Development report — incidents and checkpoints

The conversion's working record of events that touched the repository
itself rather than the product: what happened, what was checked, and what
was not changed.

## 2026-09-19 — branch ref and index found zeroed (Ledger implementation)

**What was found.** While the Ledger implementation was being committed,
two things were found zeroed, most likely after an interrupted process:

- the branch ref `refs/heads/feat/master-spec-tool-system`;
- the index (`.git/index`).

**What was done.**

1. The zeroed ref and index were copied aside before anything was
   changed.
2. The reflog still recorded the valid tip, `b289405`. The branch ref was
   pointed back at it.
3. The index was rebuilt from `HEAD` (`git reset`, without `--hard`), so
   the working tree was not touched.
4. The tracked working-tree files were checked for zeroed content, and none
   was found.
5. `git fsck` reported the object store clean.

**Outcome.**

- No commit was lost: every commit from the base to `b289405` was present
  and reachable.
- History was not rewritten because of the incident. The Ledger commits
  were then made on top of `b289405` as normal.

**Checkpoint.** The branch is unpushed, so its only copy is this working
tree. After the Ledger closure corrections, a Git bundle of the branch was
written outside the repository and checked with `git bundle verify`. The
bundle is not committed, and its path is given in the closure report. A
bundle holds only the committed history: no working-tree files, no
`.env`, no signing material and no credentials.

## Named future decisions

- **Ledger Offset.** Opposite principals with one person stay open on their
  own, and a net of zero is "even", not settled. Nothing creates a
  fictional repayment or adjustment
  (`ledger_domain_test.dart`, *opposite principals are never offset*). An
  explicit Offset operation is a product decision of its own, with its own
  typed adjustment and audit model (`LEDGER_PROPOSAL.md`, final decision
  2). It is not scheduled.
