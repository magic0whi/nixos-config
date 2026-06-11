_: {
  services.jupyter = {
    enable = true;
    password = "argon2:$argon2id$v=19$m=10240,t=10,p=8$myO6MIPWegVnDC3+pM1Rzg$xYuDOWot6FkeY51w1I6+7JKkwHjBiv9D+rMvnTwYcWs";
  };
}
