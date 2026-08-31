{ lib, ... }: {
  imports = [
    ./host.nix
    ./router.nix
    ./vms.nix
  ];
}
