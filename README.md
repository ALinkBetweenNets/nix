## ALinkbetweenNets's NixOS Infrastructure Configuration

[![Build and test](https://build.lounge.rocks/api/badges/23/status.svg)](https://build.lounge.rocks/repos/23)

[NixOS](https://nixos.org)

List of ressources: https://nixos.org/learn

Wiki: https://nixos.wiki

For available configuration options see https://search.nixos.org/options (unstable channel)

For list of packages see https://search.nixos.org/packages (by default the unstable channel is used)

For available ![Home-Manager](https://nixos.wiki/wiki/Home_Manager) options see https://nix-community.github.io/home-manager/options.html

Many thanks to ![@MayNiklas](https://github.com/MayNiklas) for teaching me the many ins and outs of NixOS as well as helping me to create the initial flake and rough structure of this repository.

Using this repository for AI-Training is prohibited.

### Temporary quiet cooling on the Framework Laptop 16

Run `sudo ./scripts/quiet-cooling start` to activate quiet cooling until reboot.
Use `sudo ./scripts/quiet-cooling status` to inspect it and
`sudo ./scripts/quiet-cooling stop` to restore automatic fans and the original CPU settings.
The script requires Python 3 and systemd. No NixOS rebuild is needed.

The fan caps are 936 and 867 RPM, 30% of the original 3120 and 2891 RPM readings.
CPU boost is disabled and frequency is capped at 1.2 GHz, with additional throttling
starting at 55°C. Automatic emergency cooling overrides the fan caps at 75°C.
Repeated starts keep the existing limits. The transient systemd unit is called
`temporary-quiet-cooling.service` and is not enabled at boot.
