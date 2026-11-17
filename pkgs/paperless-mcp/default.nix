{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_24,
}:
buildNpmPackage rec {
  pname = "paperless-mcp";
  version = "2.3.0";

  src = fetchFromGitHub {
    owner = "baruchiro";
    repo = "paperless-mcp";
    tag = "v${version}";
    hash = "sha256-r1Ffhr+Eq+XwMy8AbVbEwcpMhvrjmKc38o2X8fKXz6Q=";
  };

  nodejs = nodejs_24;

  npmDepsHash = "sha256-dwxhJEvh4q5zMT+oerrXPu7jicOTwzKyWUhrsJyVi9g=";

  # `prepack` builds the DXT bundle, which is not needed for the CLI.
  npmPackFlags = [ "--ignore-scripts" ];

  meta = {
    description = "MCP server for interacting with a Paperless-NGX API server";
    homepage = "https://github.com/baruchiro/paperless-mcp";
    license = lib.licenses.isc;
    mainProgram = "paperless-mcp";
  };
}
