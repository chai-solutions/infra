{
  inputs,
  config,
  pkgs,
  ...
}: let
  chai = inputs.chai-backend.packages.${pkgs.system}.default;
in {
  systemd.services.chaid = {
    description = "Chai Solutions API server daemon";
    restartIfChanged = true;

    environment.APP_ENV = "prod";
    environment.APP_PORT = "80";

    serviceConfig = {
      Restart = "always";
      ExecStart = "${chai}/bin/chai";
      EnvironmentFile = config.age.secrets.db-vars.path;
    };
  };
}
