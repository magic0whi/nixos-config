{
  config,
  lib,
  myvars,
  pkgs,
  ...
}:
{
  programs.zsh = lib.mkMerge [
    {
      # On macOS, this creates /etc/zshrc that loads the nix-darwin environment. Which is required if you want to use
      # macOS's default shell - zsh
      enable = true;
      interactiveShellInit = ''
        ## BEGIN Zsh Shell Coloring
        # Reset
        Color_Off=$'\e[m'       # Text Reset

        # Regular Colors
        Black=$'\e[0;30m'       # Black
        Red=$'\e[0;31m'         # Red
        Green=$'\e[0;32m'       # Green
        Yellow=$'\e[0;33m'      # Yellow
        Blue=$'\e[0;34m'        # Blue
        Purple=$'\e[0;35m'      # Purple
        Cyan=$'\e[0;36m'        # Cyan
        White=$'\e[0;37m'       # White

        # Bold
        BBlack=$'\e[1;30m'      # Black
        BRed=$'\e[1;31m'        # Red
        BGreen=$'\e[1;32m'      # Green
        BYellow=$'\e[1;33m'     # Yellow
        BBlue=$'\e[1;34m'       # Blue
        BPurple=$'\e[1;35m'     # Purple
        BCyan=$'\e[1;36m'       # Cyan
        BWhite=$'\e[1;37m'      # White

        # Underline
        UBlack=$'\e[4;30m'      # Black
        URed=$'\e[4;31m'        # Red
        UGreen=$'\e[4;32m'      # Green
        UYellow=$'\e[4;33m'     # Yellow
        UBlue=$'\e[4;34m'       # Blue
        UPurple=$'\e[4;35m'     # Purple
        UCyan=$'\e[4;36m'       # Cyan
        UWhite=$'\e[4;37m'      # White

        # Background
        On_Black=$'\e[40m'      # Black
        On_Red=$'\e[41m'        # Red
        On_Green=$'\e[42m'      # Green
        On_Yellow=$'\e[43m'     # Yellow
        On_Blue=$'\e[44m'       # Blue
        On_Purple=$'\e[45m'     # Purple
        On_Cyan=$'\e[46m'       # Cyan
        On_White=$'\e[47m'      # White

        # High Intensity
        IBlack=$'\e[0;90m'      # Black
        IRed=$'\e[0;91m'        # Red
        IGreen=$'\e[0;92m'      # Green
        IYellow=$'\e[0;93m'     # Yellow
        IBlue=$'\e[0;94m'       # Blue
        IPurple=$'\e[0;95m'     # Purple
        ICyan=$'\e[0;96m'       # Cyan
        IWhite=$'\e[0;97m'      # White

        # Bold High Intensity
        BIBlack=$'\e[1;90m'     # Black
        BIRed=$'\e[1;91m'       # Red
        BIGreen=$'\e[1;92m'     # Green
        BIYellow=$'\e[1;93m'    # Yellow
        BIBlue=$'\e[1;94m'      # Blue
        BIPurple=$'\e[1;95m'    # Purple
        BICyan=$'\e[1;96m'      # Cyan
        BIWhite=$'\e[1;97m'     # White

        # High Intensity backgrounds
        On_IBlack=$'\e[0;100m'  # Black
        On_IRed=$'\e[0;101m'    # Red
        On_IGreen=$'\e[0;102m'  # Green
        On_IYellow=$'\e[0;103m' # Yellow
        On_IBlue=$'\e[0;104m'   # Blue
        On_IPurple=$'\e[10;95m' # Purple
        On_ICyan=$'\e[0;106m'   # Cyan
        On_IWhite=$'\e[0;107m'  # White
        ## END Zsh Shell Coloring
      '';
      # Fallback prompt if starship doesn't work
      # %3~ Show folder levels max to 3
      promptInit = ''
        autoload -U promptinit && promptinit; setopt PROMPT_SUBST
        PS1='[%{$BRed%}%n%{$Color_Off%}@%{$BBlue%}%m%{$Color_Off%} %{$BBlue%}%3~%{$Color_Off%} %{$BCyan%}%{$Color_Off%}]%{$BGreen%}%(#.#.$)%{$Color_Off%} '
      '';
    }

    (lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
      autosuggestions = {
        enable = true;
        highlightStyle = "fg=60";
        strategy = [
          "match_prev_cmd"
          "history"
          "completion"
        ];
      };
      syntaxHighlighting.enable = true;
    })

    (lib.optionalAttrs pkgs.stdenv.isDarwin { enableSyntaxHighlighting = true; })
  ];
  environment.variables = lib.mkIf (config.home-manager.users.${myvars.username}.programs.helix.defaultEditor or false) {
    EDITOR = "hx";
  };
}
