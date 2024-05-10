{ lib
, bash
, pkgs
, writeShellApplication
}: writeShellApplication {
  name = "hyprec";
  runtimeInputs = with pkgs ; [
    curl
    jq
    libnotify
    slurp
    wl-clipboard
    wl-screenrec
    xdg-user-dirs
  ];
  text = builtins.readFile ./hyprec;
}
