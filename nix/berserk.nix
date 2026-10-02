{
  lib,
  python3Packages,
  fetchPypi,
}:
python3Packages.buildPythonPackage rec {
  pname = "berserk";
  version = "0.14.0";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-FTyqxGNNEH9dPV11XfvtriAOWI4JVxTx4yDK4C+Biv4=";
  };

  build-system = [ python3Packages.hatchling ];

  dependencies = with python3Packages; [
    deprecated
    ndjson
    python-dateutil
    requests
    typing-extensions
  ];

  pythonImportsCheck = [ "berserk" ];

  meta = {
    description = "Python client for the lichess API";
    homepage = "https://github.com/lichess-org/berserk";
    license = lib.licenses.gpl3Plus;
  };
}
