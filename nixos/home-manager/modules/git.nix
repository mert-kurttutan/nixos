{
  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user = {
        name = "mert-kurttutan";
        email = "kurttutan.mert@gmail.com";
      };
      init.defaultBranch = "main";
    };
  };
}
