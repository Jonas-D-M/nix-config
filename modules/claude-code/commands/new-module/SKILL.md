---
name: new-module
description: Create a new Home Manager module with the standard skeleton and register it in shared.nix.
user-invocable: true
argument-hint: <module-name>
---

# New Module

Create and register a new Home Manager module.

## Steps

1. Read the module name from `$ARGUMENTS`. If empty, ask the user for a module name.

2. Verify `modules/$ARGUMENTS/default.nix` does not already exist. If it does, inform the user and stop.

3. Create `modules/$ARGUMENTS/default.nix` with this skeleton:

```nix
{
  config,
  pkgs,
  lib,
  ...
}:
{

}
```

4. Read `modules/shared.nix` and add `./$ARGUMENTS` to the `imports` list, maintaining alphabetical order among the module imports.

5. Run `nixfmt` on both files:
   ```
   nixfmt modules/$ARGUMENTS/default.nix modules/shared.nix
   ```

6. Confirm the module was created and registered.
