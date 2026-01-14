{ ... }:

{
  home.file.".local/bin/ld-path-python" = {
    text = ''
      export LD_LIBRARY_PATH=/run/opengl-driver/lib:$LD_LIBRARY_PATH
    '';
    executable = true;
  };
}
