{
  lib,
  fetchFromGitHub,
  python3Packages,
}:

python3Packages.buildPythonApplication rec {
  pname = "wifit3";
  version = "0.1.4";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "derv82";
    repo = "wifit3";
    tag = "v${version}";
    hash = "sha256-8iKdUz4E6+dylZluMFnOAVCeYd5+CuPqMCNamYFVQio=";
  };

  # NixOS exposes pkexec without the setuid bit, so the upstream preference
  # for it makes the setup dialog fail before sudo is tried.
  patches = [ ./prefer-sudo.patch ];

  build-system = with python3Packages; [
    hatchling
  ];

  dependencies = with python3Packages; [
    libusb-package
    platformdirs
    pyusb
    rich
    textual
  ];

  pythonImportsCheck = [ "wifit3" ];

  meta = {
    description = "USB wireless auditor with userland drivers";
    homepage = "https://github.com/derv82/wifit3";
    license = lib.licenses.gpl2Only;
    maintainers = [ ];
    mainProgram = "wifit3";
  };
}
