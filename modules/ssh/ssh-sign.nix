{ ... }:
{
  programs.ssh = {
    enable = true;
    # HM defaults will be removed; explicitly set what you want.
    enableDefaultConfig = false;

    # Safer default: don't forward the agent everywhere.
    matchBlocks = {
      "*" = {
        forwardAgent = false;
      };

      "github.com" = {
        hostname = "github.com";
        user = "git";

        # If you want to force specific identities, uncomment below
        # identityFile = [
        #   "~/.ssh/id_ed25519"
        #   "~/.ssh/id_ed25519_work"
        # ];
        # identitiesOnly = true;

        # OpenSSH option not modeled as a boolean in HM; set via extraOptions.
        extraOptions = {
          AddKeysToAgent = "yes";
        };

        # Forward the agent only for GitHub (replaces the old global forwardAgent).
        forwardAgent = true;
      };
    };
  };
}
