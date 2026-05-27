{ myvars, ... }:
{
  environment.persistence."/persistent".directories = [ "/srv" ];
  environment.persistence."/persistent".users.${myvars.username}.directories = [
    "Games"
    "Secrets"
    "Works"

    # Others
    ".config/LDtk"

    # IM
    # ".config/QQ"
    # ".xwechat"
  ];
}
