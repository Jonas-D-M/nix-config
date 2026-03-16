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

      Host ssh.dev.azure.com
        HostName ssh.dev.azure.com
        User git
        IdentitiesOnly yes
        IdentityFile ${config.home.homeDirectory}/.ssh/id_rsa_azure_devops
        AddKeysToAgent yes
        ForwardAgent no
    '';

    matchBlocks = {
      "*" = {
        forwardAgent = false;
      };
    };

  };

}
