{ lib
, bash
, pkgs
, writeShellApplication
}: writeShellApplication {
  name = "hyprec";
  runtimeInputs = with pkgs ; [
    jq
    libnotify
    slurp
    wl-clipboard
    wl-screenrec
    xdg-user-dirs
  ];
  text = builtins.readFile ./hyprec;
}
