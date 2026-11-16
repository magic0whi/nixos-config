---
name: nixos-search
description:
  Search NixOS, Home Manager, nix-darwin, nixpkgs packages, and third-party flake options.
  Use when the user asks to look up a NixOS option, a Home Manager option, a nix-darwin
  option, a package in nixpkgs, or an option provided by a flake. Builds links against the
  local mirror first and falls back to the upstream site.
---

# NixOS Search

## Host selection

1. Prefer the local mirror: `https://nixos-search.proteus.eu.org`
2. If it is unreachable (connection error, non-2xx, or timeout), fall back to
   `https://search.nixos.org`.

Check before handing links to the user:

```sh
curl -fsS -o /dev/null --max-time 5 https://nixos-search.proteus.eu.org/ \
  || echo "local down -> use search.nixos.org"
```

Path, query, and fragment are identical on both hosts, so only the origin changes.
Mention the fallback only when it was actually used.

## URL shape

```
https://<host>/<page>?channel=<channel>&query=<text>[&source=<source>]&type=<type>[#show=<kind>%253A<name>]
```

| Part      | Values                                                                       |
| --------- | ---------------------------------------------------------------------------- |
| `<page>`  | `options` (options), `packages` (nixpkgs packages), `flakes` (flake options) |
| `channel` | `unstable` (default here) or a release id such as `26.05`                    |
| `query`   | search text, spaces as `+`                                                   |
| `source`  | options only: `nixos` (default), `home_manager`, `darwin`, `modular_service` |
| `type`    | `options` for options, `packages` for packages                               |
| `show`    | optional deep link to one result (see below)                                 |

### `#show` encoding

`#show=<kind>%253A<dotted.name>`

| Result              | `<kind>`                     |
| ------------------- | ---------------------------- |
| NixOS option        | `option`                     |
| Home Manager option | `home-manager-option`        |
| nix-darwin option   | `darwin-option`              |
| Modular service     | `service`                    |
| nixpkgs package     | no kind: `#show=<attr.name>` |

The colon stays **double-encoded** as `%253A`. Do not "fix" it to `%3A` or `:` — the
fragment is decoded twice and the deep link breaks otherwise.

For flake options the page is `flakes` but `kind` stays `option`.

## Recipes

Home Manager option:

```
https://nixos-search.proteus.eu.org/options?channel=unstable&query=mcp&source=home_manager&type=options#show=home-manager-option%253Aprograms.mcp.servers
```

nix-darwin option:

```
https://nixos-search.proteus.eu.org/options?channel=unstable&query=aerospace&source=darwin&type=options#show=darwin-option%253Aservices.aerospace.settings
```

NixOS option:

```
https://nixos-search.proteus.eu.org/options?channel=unstable&query=nginx&source=nixos&type=options#show=option%253Aservices.nginx.enable
```

nixpkgs package:

```
https://nixos-search.proteus.eu.org/packages?channel=unstable&query=ripgrep&type=packages#show=ripgrep
```

Third-party flake option:

```
https://nixos-search.proteus.eu.org/flakes?channel=unstable&query=lanzaboote&type=options#show=option%253Aboot.lanzaboote.package
```

## Workflow

1. Decide page + source from the request (NixOS vs Home Manager vs nix-darwin vs flake).
   For flake options you usually do not know the flake name; put the option's distinctive
   word in `query` and link the `flakes` page.
2. Set `query` to a distinctive fragment of the name (e.g. `mcp`, `aerospace`), not the
   full dotted path — the deep link does the exact selection.
3. Build the URL, then (optionally) health-check the host with the `curl` above.
4. Present it as a normal markdown link and keep it clickable; do not wrap it in inline
   code if the user may want to click it.
5. Do not claim an option/package exists from an HTTP 200: the site is a client-rendered
   SPA, so `curl` only proves the page loads. Scrape the link with Firecrawl when you need
   to read or confirm the result (see below).

## Using Firecrawl

Prefer the `firecrawl` MCP over `curl` whenever you must read the page, because the SPA
renders results in the browser:

- `firecrawl_scrape` with `formats: ["markdown"]`, `onlyMainContent: true`,
  `waitFor: 3000`, `maxAge: 0` returns the rendered result list and details.
- Always pass `skipTlsVerification: true` for the local mirror. It serves a certificate
  from a private CA, and Firecrawl's Chromium ignores the system CA bundle that the API
  container trusts, so without this flag every HTML scrape fails with
  `SCRAPE_ALL_ENGINES_FAILED` (HTTP 500).
- For structured output, use `formats: ["json"]` with a schema such as
  `{"option": "string", "type": "string", "default": "string", "description": "string"}`
  and a prompt like "Extract the selected option's name, type, default, and description."
- Scrape the deep link including `#show=...`: the fragment is resolved client-side, so the
  rendered page opens on that exact option.
- If the first render is empty, retry with `actions: [{"type": "wait", "milliseconds": 3000}]`
  or `waitFor: 5000`.
- Use `firecrawl_search` only to discover a name you do not know (e.g.
  `site:search.nixos.org`); once the name is known, build the URL instead.

Example scrape (use the host chosen by the health check):

```json
{
  "url": "https://nixos-search.proteus.eu.org/options?channel=unstable&query=aerospace&source=darwin&type=options#show=darwin-option%253Aservices.aerospace.settings",
  "formats": ["markdown"],
  "onlyMainContent": true,
  "waitFor": 3000,
  "maxAge": 0,
  "skipTlsVerification": true
}
```

If Firecrawl fails (401, outage), degrade gracefully: give the user the link and say the
page could not be rendered. Never invent an option's type, default, or description.

Empty or truncated markdown is usually the same certificate problem, not a missing option:
retry with `skipTlsVerification: true` before concluding there are no results.

## Notes

- `#show` only preselects; `query` must still return the item for the deep link to show.
- Multiple lookups → one link per lookup, don't concatenate.
- Channel ids come from the deployment (`unstable`, `26.05`); if a channel shows nothing,
  retry on `unstable`.
- Don't call the raw Elasticsearch backend directly: index aliases and the mapping schema
  version change between deployments, so hand-built API queries are brittle.
