{
  lib,
  python3Packages,
  fetchPypi,
  callPackage,
}:
python3Packages.buildPythonApplication rec {
  pname = "pgn-to-sqlite";
  version = "2.4.0";
  pyproject = true;

  src = fetchPypi {
    pname = "pgn_to_sqlite";
    inherit version;
    hash = "sha256-jfilxDLEIrFs5RY7Hx56ifHFreGxK0Mxki6UtpnWIl4=";
  };

  # Upstream caps uv_build at <0.11.0; nixpkgs only carries 0.11.x, and the
  # build backend is API-compatible across that bump.
  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail 'uv_build>=0.9.6,<0.11.0' 'uv_build>=0.9.6'
  '';

  build-system = [ python3Packages.uv-build ];

  dependencies = [
    (callPackage ./berserk.nix { })
  ]
  ++ (with python3Packages; [
    click
    requests
    rich
  ]);

  pythonImportsCheck = [ "pgn_to_sqlite" ];

  meta = {
    description = "Pull chess games from chess.com and lichess.org into a SQLite database";
    homepage = "https://github.com/EndlessTrax/pgn-to-sqlite";
    license = lib.licenses.mit;
    mainProgram = "pgn-to-sqlite";
  };
}
