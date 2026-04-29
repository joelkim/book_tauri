{ pkgs }: {
  deps = [
    pkgs.rustup
    pkgs.pkg-config
    pkgs.openssl
  ];
}
