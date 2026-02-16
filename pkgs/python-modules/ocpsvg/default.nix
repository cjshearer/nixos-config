{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools-scm,
  pytestCheckHook,
  cadquery-ocp,
  svgelements,
}:
buildPythonPackage (finalAttrs: {
  pname = "ocpsvg";
  version = "0.6.0";
  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-8I2kNHzJDs01ZTlem9pXRtRquKr9aiaBuwOpwyG1QDk=";
  };
  pyproject = true;

  build-system = [
    setuptools-scm
  ];

  nativeCheckInputs = [ pytestCheckHook ];

  dependencies = [
    cadquery-ocp
    svgelements
  ];

  meta = {
    description = "Translator between OCP and svgelements";
    homepage = "https://github.com/3MFConsortium/lib3mf_python";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ tnytown ];
  };
})
