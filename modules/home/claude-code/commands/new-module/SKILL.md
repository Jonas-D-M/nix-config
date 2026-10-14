---
name: new-module
description: Create a new Home Manager module with the standard skeleton and register it in modules/home/default.nix.
user-invocable: true
argument-hint: <module-name>
---

# New Module

Create and register a new Home Manager module.

## Steps

1. Read the module name from `$ARGUMENTS`. If empty, ask the user for a module name.

2. Verify `modules/home/$ARGUMENTS/default.nix` does not already exist. If it does, inform the user and stop.

3. Create `modules/home/$ARGUMENTS/default.nix` with this skeleton:

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

4. Read `modules/home/default.nix` and add `./$ARGUMENTS` to the `imports` list, maintaining alphabetical order among the module imports.

5. Run `nixfmt` on both files:
   ```
   nixfmt modules/home/$ARGUMENTS/default.nix modules/home/default.nix
   ```

6. Confirm the module was created and registered.
