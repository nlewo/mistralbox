{
  description = "mistralbox - bash running in a bubblewrap sandbox";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.llm-agents.url = "github:numtide/llm-agents.nix";

  outputs = { self, nixpkgs, llm-agents }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          mistralbox = pkgs.writeShellApplication {
            name = "mistralbox";
            runtimeInputs = [ pkgs.bubblewrap pkgs.coreutils pkgs.curl pkgs.findutils pkgs.iputils pkgs.nix llm-agents.packages.${system}.mistral-vibe ];
            text = ''
              cmd=(vibe)
              bind_path=""
              
              while [[ $# -gt 0 ]]; do
                case "$1" in
                  --bind)
                    bind_path="$2"
                    shift 2
                    ;;
                  --bash)
                    shift
                    cmd=(${pkgs.bash}/bin/bash)
                    ;;
                  *)
                    break
                    ;;
                esac
              done

              mkdir -p "$HOME"/.vibe
              exec bwrap \
                ''${bind_path:+--bind "$bind_path" "$bind_path"} \
                --ro-bind /nix /nix \
                --ro-bind /etc/nix /etc/nix \
                --bind "$PWD" "$PWD" \
                --bind "$HOME"/.vibe "$HOME"/.vibe \
                --chdir "$PWD" \
                --proc /proc \
                --dev /dev \
                --tmpfs /tmp \
                --unshare-all \
                --share-net \
                --bind /nix/var/nix/daemon-socket /nix/var/nix/daemon-socket \
                --ro-bind /etc/resolv.conf /etc/resolv.conf \
                --ro-bind /etc/hosts /etc/hosts \
                --ro-bind /etc/nsswitch.conf /etc/nsswitch.conf \
                --ro-bind /run/current-system /run/current-system \
                --ro-bind /etc/ssl/certs /etc/ssl/certs \
                --ro-bind /etc/static/ssl/certs /etc/static/ssl/certs \
                --ro-bind /etc/nix /etc/nix \
                --setenv "$HOME" "$HOME" \
                --setenv USER "$USER" \
                --setenv PATH "$PATH" \
                --setenv TMPDIR /tmp \
                --setenv TEMPDIR /tmp \
                --setenv TEMP /tmp \
                --setenv TMP /tmp \
                --setenv NIX_SSL_CERT_FILE /etc/ssl/certs/ca-bundle.crt \
                --setenv NIX_CONF_DIR /etc/nix \
                --die-with-parent \
                -- "''${cmd[@]}" "$@"
            '';
          };

          default = self.packages.${system}.mistralbox;
        });
    };
}
