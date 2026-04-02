{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    mouse = true;
    escapeTime = 0;
    keyMode = "vi";
    terminal = "screen-256color";
    extraConfig = ''
      set -as terminal-features ",alacritty*:RGB"
      # Use Ctrl+p as the tmux prefix.
      unbind C-b
      set -g prefix C-a
      bind C-a send-prefix
      # Zellij-like default new pane (vertical) with Alt+n.
      bind -n M-n split-window -v
      # Explicit split directions: Ctrl+p then r (horizontal) or d (vertical).
      bind r split-window -h
      bind d split-window -v
      # Pane navigation with Alt+arrow keys.
      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D
      # Resize mode: Ctrl+n, then arrows resize until you exit.
      bind -n C-n switch-client -T resize
      bind -T resize Left resize-pane -L 5 \; switch-client -T resize
      bind -T resize Right resize-pane -R 5 \; switch-client -T resize
      bind -T resize Up resize-pane -U 3 \; switch-client -T resize
      bind -T resize Down resize-pane -D 3 \; switch-client -T resize
      # Exit resize mode.
      bind -T resize C-n switch-client -T root
      bind -T resize Escape switch-client -T root
      bind -T resize Enter switch-client -T root
      # Tab (window) mode: Ctrl+t, then n to open a new tab.
      bind -n C-t switch-client -T tab
      bind -T tab n new-window \; switch-client -T tab
      bind -T tab Left previous-window \; switch-client -T tab
      bind -T tab Right next-window \; switch-client -T tab
      bind -T tab Up previous-window \; switch-client -T tab
      bind -T tab Down next-window \; switch-client -T tab
      # Exit tab mode.
      bind -T tab C-t switch-client -T root
      bind -T tab Escape switch-client -T root
      bind -T tab Enter switch-client -T root
    '';
    plugins = with pkgs; [
      tmuxPlugins.gruvbox
      # {
      #   plugin = tmuxPlugins.resurrect;
      #   extraConfig = "set -g @resurrect-strategy-nvim 'session'";
      # }
      # {
      #   plugin = tmuxPlugins.continuum;
      #   extraConfig = ''
      # set -g @continuum-restore 'on'
      # set -g @continuum-save-interval '60' # minutes
      #   '';
      # }
    ];
  };
}
