{
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

  system.stateVersion = "24.05";
}
