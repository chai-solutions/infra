{
  pkgs,
  lib,
  inputs,
  ...
}: let
  chai = inputs.chai-backend.packages.${pkgs.system}.default;
in {
  systemd.services.chaid = {
    description = "Chai Solutions API server daemon";

    restartIfChanged = true;

    serviceConfig = {
      Restart = "always";
      ExecStart = "${lib.getExe chai}";
    };
  };
}
