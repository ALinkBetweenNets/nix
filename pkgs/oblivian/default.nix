{ lib, rustPlatform }:

rustPlatform.buildRustPackage {
  pname = "oblivian-server";
  version = "0.1.0";

  src = ./server;
  cargoLock.lockFile = ./server/Cargo.lock;

  meta = {
    description = "Live collaboration sync server for Obsidian vaults";
    license = lib.licenses.mit;
    mainProgram = "oblivian-server";
    platforms = lib.platforms.linux;
  };
}
