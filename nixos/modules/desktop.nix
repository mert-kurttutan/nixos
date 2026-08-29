{
  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;

    # Configure keymap in X11.
    xkb = {
      layout = "tr";
      variant = "";
    };
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Enable the COSMIC login manager and COSMIC desktop environment.
  # services.displayManager.cosmic-greeter.enable = true;
  # services.desktopManager.cosmic.enable = true;

  # KDE Plasma 6.
  # services.desktopManager.plasma6.enable = true;
  # services.displayManager.sddm.enable = true;
  # services.displayManager.sddm.wayland.enable = true;

  services.flatpak.enable = true;
}
