{ myvars, ... }:
{
  environment.persistence."/persistent".directories = [ "/srv" ];
  environment.persistence."/persistent".users.${myvars.username} = {
    directories = [
      "Documents"
      "Downloads"
      "Games"
      "Music"
      "Pictures"
      "Secrets"
      "Videos"
      "Works"

      # Games
      ".steam" # Steam games

      # Remote desktop
      ".config/remmina"
      ".config/freerdp"

      # vscode
      ".vscode"
      ".vscode-insiders"
      ".config/Code/User"
      ".config/Code - Insiders/User"

      # zed editor
      ".config/zed"

      # Browsers
      ".mozilla"
      ".config/google-chrome"

      # Others
      ".config/blender"
      ".config/LDtk"

      # IM
      ".config/QQ"
      ".xwechat"

      # Cloud providers
      ".config/gcloud"
      ".terraform.d"
    ];
    files = [ ];
  };
}
