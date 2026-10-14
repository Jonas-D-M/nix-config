# modules/home/ssh/default.nix
# SSH, split by concern, all driven by the key registry in ./keys.nix:
#   keys.nix   — the registry (custom.ssh.keys) and derived facts
#   config.nix — client config: GitHub key routing (work key inside ~/work),
#                Azure DevOps RSA key
#   keygen.nix — the sshKeys activation script: generates missing keys (never
#                overwrites), derives .pub files, writes allowed_signers
{
  imports = [
    ./keys.nix
    ./config.nix
    ./keygen.nix
  ];
}
