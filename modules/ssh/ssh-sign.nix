{ config, ... }:
{
  programs.ssh = {
    enable = true;
    # HM defaults will be removed; explicitly set what you want.
    enableDefaultConfig = false;

    # Safer default: don't forward the agent everywhere.
    extraConfig = ''
      # Use work key when inside ~/work or any subdir (macOS path normalization included)
      Match host github.com exec "pwd -P | sed -e 's|^/private||' -e 's|^/System/Volumes/Data||' | grep -Eq '^${config.home.homeDirectory}/work(/|$)'"
        HostName github.com
        User git
        IdentitiesOnly yes
        IdentityFile ${config.home.homeDirectory}/.ssh/id_ed25519_work
        IdentityAgent none
        ForwardAgent no

      # Fallback for everything else
      Host github.com
        HostName github.com
        User git
        IdentitiesOnly yes
        IdentityFile ${config.home.homeDirectory}/.ssh/id_ed25519
        AddKeysToAgent yes
        ForwardAgent no
    '';

    matchBlocks = {
      "*" = {
        forwardAgent = false;
      };

      # "github.com" = {
      #   hostname = "github.com";
      #   user = "git";

      # If you want to force specific identities, uncomment below
      # identityFile = [
      #   "~/.ssh/id_ed25519"
      #   "~/.ssh/id_ed25519_work"
      # ];
      # identitiesOnly = true;

      # OpenSSH option not modeled as a boolean in HM; set via extraOptions.
      # extraOptions = {
      #   AddKeysToAgent = "yes";
      # };

      # identitiesOnly = true;
      # identityFile = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];

      # # Forward the agent only for GitHub (replaces the old global forwardAgent).
      # forwardAgent = true;
      # };
    };

  };

}
