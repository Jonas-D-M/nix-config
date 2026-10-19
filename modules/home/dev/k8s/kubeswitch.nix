# modules/home/dev/k8s/kubeswitch.nix
# kubeswitch: fast kubeconfig context switching, integrated into zsh.
# Home Manager's zsh integration is unconditional, so its shell files are
# generated here the same way and sourced from the interactive layer.
{
  config,
  pkgs,
  ...
}:
let
  cfg = config.programs.kubeswitch;

  zshFiles =
    pkgs.runCommand "kubeswitch-${cfg.commandName}-shell-files-for-zsh"
      {
        nativeBuildInputs = [ cfg.package ];
      }
      ''
        mkdir -p $out/share
        switcher init zsh | sed "s/switch(/${cfg.commandName}(/" > "$out/share/${cfg.commandName}_init.zsh"
        switcher --cmd "${cfg.commandName}" completion zsh > "$out/share/${cfg.commandName}_completion.zsh"
      '';
in
{
  programs.kubeswitch = {
    enable = true;
    enableZshIntegration = false;
  };

  custom.zsh.interactiveInit = ''
    source ${zshFiles}/share/${cfg.commandName}_init.zsh
    source ${zshFiles}/share/${cfg.commandName}_completion.zsh
  '';
}
