{
  self,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
    ./server.nix
  ];

  environment.systemPackages = with pkgs; [
    # In case anything ever goes wrong, have the best
    # text editor ever around.
    neovim
  ];

  users.users.chai = {
    description = "chai daemon system user";
    group = "chai";
    isSystemUser = true;
  };
  users.groups.chai = {};

  age.identityPaths = ["/var/lib/persistent/agenix_key"];
  age.secrets.db-vars.file = ../secrets/db-vars.age;

  # May as well have double firewalls for redundancy. EC2
  # is already configured with one, but this doesn't hurt.
  networking.firewall.allowedTCPPorts = [80 443];

  system.configurationRevision = self.rev or "dirty";
  system.stateVersion = "24.05";
}
