{ pkgs }:
pkgs.devshell.mkShell {
  name = "devops";

  commands = [
    # k8s
    {
      package = pkgs.kubectl;
      category = "k8s";
    }
    {
      package = pkgs.kubernetes-helm;
      category = "k8s";
    }
    {
      package = pkgs.krew;
      category = "k8s";
    }
    {
      package = pkgs.k9s;
      category = "k8s";
    }
    {
      package = pkgs.kubeswitch;
      category = "k8s";
    }

    # containers
    {
      package = pkgs.docker-client;
      category = "containers";
    }

    # secrets
    {
      package = pkgs.sops;
      category = "secrets";
    }
    {
      package = pkgs.age;
      category = "secrets";
    }

    # tools
    {
      package = pkgs.gh;
      category = "tools";
    }
    {
      package = pkgs.direnv;
      category = "tools";
    }
    {
      package = pkgs.jq;
      category = "tools";
    }
    {
      package = pkgs.yq-go;
      category = "tools";
    }
    {
      package = pkgs.curl;
      category = "tools";
    }
    {
      package = pkgs.ripgrep;
      category = "tools";
    }
  ];

  env = [
    {
      name = "KUBECONFIG";
      eval = "$HOME/.config/kube/config";
    }
    {
      name = "PATH";
      prefix = "$HOME/.krew/bin";
    }
  ];
}
