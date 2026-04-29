{ pkgs }: {
  deps = [
    pkgs.quarto
    pkgs.uv
    pkgs.rustup
    pkgs.pkg-config
    pkgs.openssl
  ];
}
