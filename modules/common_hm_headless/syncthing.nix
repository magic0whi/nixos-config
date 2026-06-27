{ mylib, ... }:
{
  imports = [ (mylib.relativeToRoot "const/syncthing.nix") ];
}
