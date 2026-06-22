# nix-config

Declarative macOS + Linux environment (Nix flakes, Home Manager, nix-darwin). This file records project-specific vocabulary — terms whose meaning here is sharper than their everyday use. General Nix/Home Manager concepts do not belong here.

## SSH

**SSH key registry**:
The single declarative list (`custom.ssh.keys`) of every managed key. The source of truth for key generation, `allowed_signers`, the work-context dir, and git commit-signing. SSH host routing reads key names and the work context from it, but the per-host blocks themselves are templated in `config.nix`.
_Avoid_: key list, keychain, key store

**Managed key**:
One entry in the SSH key registry — a key file plus its facts: type, comment, whether it signs commits, which host it serves, and its work context.
_Avoid_: keypair, credential, identity (overloaded with git "identity")

**Work context**:
The directory (`onlyInDir`, currently `~/work`) under which a managed key's work role activates. One fact that drives both SSH key selection and git signing-identity selection.
_Avoid_: work dir, work profile, gitdir
