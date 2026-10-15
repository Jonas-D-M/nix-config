# Global instructions

## Git and the Bash sandbox

Some git subcommands only work outside the Bash sandbox, through
`sandbox.excludedCommands`: `git commit/tag/merge/rebase/cherry-pick/revert`
(commits are SSH-signed, and the sandbox can't read `~/.ssh`) and `git
push/fetch/pull/clone` (SSH remotes).

An exclusion only applies to a plain call. The call stays sandboxed, and fails,
if it has any of:

- a leading `cd <dir> &&`, or `git -C <dir>`
- a redirect (`>`, `2>&1`, `<<EOF`) or a pipe
- a `$(...)` substitution, including `-m "$(cat <<'EOF' ... EOF)"`
- any chained command that isn't excluded itself, including `git add` and
  `git status`. Run `git add ...` as its own call, then `git commit ...` as
  a separate call.

So, from the working directory:

- **Commit messages**: pass one `-m` per paragraph:
  `git commit -m "type(scope): subject" -m "Body paragraph."`. A paragraph
  can span lines inside its quotes. If you need a file instead, write a new
  one in your session scratchpad directory, never a fixed shared path like
  `/tmp/claude/commit-msg.txt`: if the Write fails, `git commit -F` silently
  commits whatever an earlier session left there.
- **Push** with a bare `git push` / `git push -u origin <branch>`.

`gh` runs inside the sandbox and needs none of this; `gh pr create --body
"$(...)"` works.
