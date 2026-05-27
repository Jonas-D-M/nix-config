{ config, ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    extraConfig = ''
      # Use work key when inside ~/work or any subdir (macOS path normalization included)
      Match host github.com exec "pwd -P | sed -e 's|^/private||' -e 's|^/System/Volumes/Data||' | grep -Eq '^${config.home.homeDirectory}/work(/|$)'"
        IdentityFile ${config.home.homeDirectory}/.ssh/id_ed25519_work
        IdentityAgent none

      # Fallback for everything else
      Host github.com
        HostName github.com
        User git
        IdentitiesOnly yes
        IdentityFile ${config.home.homeDirectory}/.ssh/id_ed25519
        AddKeysToAgent yes
    '';

    settings = {
      "*" = {
        ForwardAgent = false;
      };

      "ssh.dev.azure.com" = {
        HostName = "ssh.dev.azure.com";
        User = "git";
        IdentitiesOnly = true;
        IdentityFile = [ "${config.home.homeDirectory}/.ssh/id_rsa_azure_devops" ];
        AddKeysToAgent = "yes";
      };
    };
  };
}
