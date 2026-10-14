{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.ssh;
  homeDir = config.home.homeDirectory;
  serves = host: lib.filter (k: k.serves == host) cfg.keys;

  fallbackKey = lib.findFirst (
    k: k.onlyInDir == null
  ) (throw "ssh: no fallback github key in registry") (serves "github.com");
  azureKey = lib.findFirst (_: true) (throw "ssh: no ssh.dev.azure.com key in registry") (
    serves "ssh.dev.azure.com"
  );

  # Resolved once in keys.nix and shared with ../git so routing and signing
  # cannot disagree on the work key or the work-context dir.
  workKey = cfg.workKey;
  workDir = cfg.workDir;
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    extraConfig = ''
      # Use work key when inside ~/work or any subdir (macOS path normalization included)
      Match host github.com exec "pwd -P | sed -e 's|^/private||' -e 's|^/System/Volumes/Data||' | grep -Eq '^${workDir}(/|$)'"
        IdentityFile ${homeDir}/.ssh/${workKey.name}
        IdentityAgent none

      # Fallback for everything else
      Host github.com
        HostName github.com
        User git
        IdentitiesOnly yes
        IdentityFile ${homeDir}/.ssh/${fallbackKey.name}
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
        IdentityFile = [ "${homeDir}/.ssh/${azureKey.name}" ];
        AddKeysToAgent = "yes";
      };
    };
  };
}
