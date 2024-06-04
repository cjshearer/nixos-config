{ lib, config, pkgs, ... }: lib.mkIf config.services.ollama.enable {
  environment.systemPackages = [
    pkgs.amdgpu_top
  ];
  services.ollama.acceleration = "rocm";
  services.ollama.environmentVariables = {
    HSA_OVERRIDE_GFX_VERSION = "10.3.0";
  };
}
