{ pkgs ? import ./nix {} }:

let
  python3 = pkgs.python3.pkgs;
  pythonPath = python3.makePythonPath [
    python3.ipykernel
    python3.jupyter_contrib_core
    python3.jupyter_nbextensions_configurator
    python3.tornado
  ];

  # Kernel generators.
  kernels = pkgs.callPackage ./kernels {};
  kernelsDefault = [ (kernels.iPythonWith {}) ];
  mkKernelsString = pkgs.lib.concatMapStringsSep ":" (k: "${k}");

  directoryDefault = "${python3.jupyterlab}/share/jupyter/lab";

  # JupyterLab with the appropriate kernel and directory setup.
  jupyterlabWith = { directory ? directoryDefault, kernels ? kernelsDefault }:
      let
       jupyterlab=python3.toPythonModule (
           python3.jupyterlab.overridePythonAttrs (oldAttrs: {
             makeWrapperArgs = [
               "--set JUPYTERLAB_DIR ${directory}"
               "--set JUPYTER_PATH ${mkKernelsString kernels}"
               "--set PYTHONPATH ${pythonPath}"
             ];
           })
           );
       env=pkgs.mkShell {
             name="jupyterlab-shell";
             buildInputs=[ jupyterlab ];
             shellHook = ''
               export JUPYTERLAB=${jupyterlab}
               jupyter lab
             '';
           };
    in
      jupyterlab.override (oldAttrs: {
        passthru=oldAttrs.passthru or {} // {inherit env;};
      });

  mkDirectory = { extensions }:
    import ./generate-directory.nix { inherit pkgs extensions; };
in
  { inherit jupyterlabWith kernels mkDirectory; }
