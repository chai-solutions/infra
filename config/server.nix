{
  inputs,
  config,
  pkgs,
  ...
}: let
  chai = inputs.chai-backend.packages.${pkgs.system}.default;
  port = "6969";
in {
  # Reverse proxy and HTTPS certs
  services.caddy = {
    enable = true;
    virtualHosts."api.chai-solutions.org".extraConfig = ''
      reverse_proxy 127.0.0.1:${port}
    '';
  };

  systemd.services.chaid = {
    description = "Chai Solutions API server daemon";
    restartIfChanged = true;

    environment.APP_ENV = "prod";
    environment.APP_PORT = "6969";

    serviceConfig = {
      Restart = "always";
      ExecStart = "${chai}/bin/chai";
      EnvironmentFile = config.age.secrets.db-vars.path;
    };
  };
}
