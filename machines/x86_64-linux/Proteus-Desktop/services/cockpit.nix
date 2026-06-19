{
  config,
  lib,
  const,
  pkgs,
  ...
}:
{
  systemd.services.cockpit-wsinstance-http.environment = {
    # G_MESSAGES_DEBUG = "all";
    REQUESTS_CA_BUNDLE = config.security.pki.caBundle; # Use system CA for pkgs.python3Packages.requests
  };
  services.cockpit = {
    enable = true;
    allowed-origins = [ "https://cockpit-desktop.${const.domain}" ];
    settings = {
      WebService = {
        ProtocolHeader = "X-Forwarded-Proto";
        ForwardedForHeader = "X-Forwarded-For";
      };
      OAuth.URL =
        "https://auth.${const.domain}/api/oidc/authorization"
        + "?client_id=cockpit"
        + "&response_type=token"
        + "&response_mode=fragment"
        + "&scope=openid%20profile%20email%20groups"
        + "&state=1234abcedfdhf"
        + "&redirect_uri=https://cockpit-desktop.${const.domain}";
      # Refs:
      # https://github.com/cockpit-project/cockpit/blob/a7ae147258a8102069cb7caa94fce1332ea49af1/containers/ws/cockpit-auth-ssh-key
      # https://github.com/gbraad-redhat/podman-cockpit-desktop/issues/3#issuecomment-968581254
      Bearer.Command = "${pkgs.writers.writePython3 "cockpit-auth-bearer"
        {
          libraries = [ pkgs.python3Packages.requests ];
          flakeIgnore = [ "E501" ]; # ignores PEP8's line length limit of 79
        }
        ''
          import json
          import os
          import sys
          import time
          import requests


          IAM_USERINFO_URL = "https://auth.${const.domain}/api/oidc/userinfo"


          def send_frame(content):
              data = json.dumps(content).encode()
              os.write(1, str(len(data) + 1).encode())
              os.write(1, b"\n\n")
              os.write(1, data)


          def send_problem(problem, message):
              send_frame({
                  "command": "init",
                  "problem": problem,
                  "message": message
              })


          def read_size(fd):
              sep = b'\n'
              size = 0
              seen = 0

              while True:
                  t = os.read(fd, 1)
                  if not t:
                      return 0
                  if t == sep:
                      break

                  size = (size * 10) + int(t)
                  seen += 1

                  if seen > 7:
                      raise ValueError("Invalid frame: size too long")

              return size


          def read_frame(fd):
              size = read_size(fd)
              data = b""
              while size > 0:
                  d = os.read(fd, size)
                  size = size - len(d)
                  data += d

              return data.decode()


          def main():
              send_frame({
                  "command": "authorize",
                  "cookie": f"session{os.getpid()}{time.time()}",
                  "challenge": "*"
              })

              data = read_frame(0)  # 0 is stdout, 1 is stdin, 2 is stderr
              cmd = json.loads(data)
              response = cmd.get("response")

              if cmd.get("command") != "authorize" or \
                 not cmd.get("cookie") or not response:
                  raise ValueError("Did not receive a valid authorize command")

              if response.startswith("Bearer "):
                  token = response[7:]
              else:
                  token = response

              try:
                  req = requests.get(
                      IAM_USERINFO_URL,
                      headers={"Authorization": f"Bearer {token}"},
                      timeout=5
                      # verify=False  # debug
                  )

                  if req.status_code != 200:
                      msg = f"IAM rejected token: {req.text}"
                      send_problem("authentication-failed", msg)
                      sys.exit(1)

                  username = req.json().get("preferred_username")
                  if not username:
                      send_problem(
                          "authentication-failed",
                          f"No preferred_username in userinfo: {req.text}"
                      )
                      sys.exit(1)

                  # success
                  os.execvp(
                      "${lib.getExe' pkgs.cockpit "cockpit-bridge"}",
                      ["cockpit-bridge"]
                  )

              except Exception as e:
                  send_problem("internal-error", str(e))
                  sys.exit(1)


          if __name__ == '__main__':
              main()
        ''
      }";
    };
    plugins = with pkgs; [
      cockpit-machines
      # cockpit-zfs # broken
    ];
  };
  services.traefik.dynamicConfigOptions.http = {
    routers.immich = {
      rule = "Host(`cockpit-desktop.${const.domain}`)";
      entryPoints = [ "websecure" ];
      service = "cockpit";
      tls = { };
    };
    services.cockpit.loadBalancer = {
      servers = [ { url = "http://127.0.0.1:${toString config.services.cockpit.port}"; } ];
      healthCheck.path = "/ping";
    };
  };
}
