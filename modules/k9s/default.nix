# modules/k9s/default.nix
{ ... }:
{
  programs.k9s = {
    enable = true;

    settings.k9s.ui.skin = "transparent";

    skins.transparent = ./transparent.yaml;

    # Robusta KRR plugin: resource (CPU/memory) request/limit recommendations
    # directly in k9s. Requires Prometheus in the cluster and the `krr` CLI on
    # PATH (installed via Homebrew in hosts/darwin/homebrew.nix). Press Shift-K
    # in a deployments/daemonsets/statefulsets/cronjobs or namespaces view.
    # Source: https://github.com/derailed/k9s/blob/master/plugins/resource-recommendations.yaml
    plugins = {
      krr = {
        shortCut = "Shift-K";
        description = "Get krr";
        scopes = [
          "deployments"
          "daemonsets"
          "statefulsets"
          "cronjobs"
        ];
        command = "bash";
        background = false;
        confirm = false;
        args = [
          "-c"
          ''
            LABELS=$(kubectl get $RESOURCE_NAME $NAME -n $NAMESPACE  --context $CONTEXT  --show-labels | awk '{print $NF}' | awk '{if(NR>1)print}')
            krr simple --cluster $CONTEXT --selector $LABELS
            echo "Press 'q' to exit"
            while : ; do
            read -n 1 k <&1
            if [[ $k = q ]] ; then
            break
            fi
            done
          ''
        ];
      };
      krr-ns = {
        shortCut = "Shift-K";
        description = "Get krr";
        scopes = [ "namespaces" ];
        command = "bash";
        background = false;
        confirm = false;
        args = [
          "-c"
          ''
            krr simple --cluster $CONTEXT -n $RESOURCE_NAME
            echo "Press 'q' to exit"
            while : ; do
            read -n 1 k <&1
            if [[ $k = q ]] ; then
            break
            fi
            done
          ''
        ];
      };
    };
  };
}
