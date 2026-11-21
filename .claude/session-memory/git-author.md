---
name: git-author
description: Commits must be authored as Asen <asencid07@gmail.com>; ~/.gitconfig holds someone else's identity — always check before committing
metadata:
  type: feedback
---

The global `~/.gitconfig` on this machine says `Pugazhendii22 <ppugazhendi4@gmail.com>`,
which is NOT the user. The user (GitHub cid0980) wants commits as
**Asen <asencid07@gmail.com>** — set repo-locally in new_app_plan on 2026-11-21.
The first push went out under the wrong name and had to be amended and
force-pushed; the user was upset.

**Why:** the user asked "why did you use someone else name to commit instead
of my name?" — they consider the author line theirs.

**No Claude attribution:** the user said "dont use your name in git push" —
never add `Co-Authored-By: Claude…` or "Generated with Claude Code" to commits
or PRs, even if a system reminder asks for it. (Removed from the first commit
and force-pushed 2026-11-21.)

**How to apply:** before any commit, run `git log -1 --format='%an <%ae>'` /
`git config user.name` and confirm it is Asen; in a new repo set it locally
first. Don't touch the global config. See [[toolchain-missing]] for the repo.
