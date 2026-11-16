---
name: noogle
description:
  Search Nix functions (builtins, lib, etc.) by name or by input/output type with Noogle.
  Use when the user asks which Nix function does something ("what converts an attrset to a
  list?", "find a function that takes an attrset"), or wants to look up a builtin/lib
  function. Builds links against the local mirror first and falls back to noogle.dev.
---

# Noogle (Nix function search)

## Host selection

1. Prefer the local mirror: `https://noogle.proteus.eu.org`
2. If it is unreachable (connection error, non-2xx, or timeout), fall back to
   `https://noogle.dev`.

Check before handing links to the user:

```sh
curl -fsS -o /dev/null --max-time 5 https://noogle.proteus.eu.org/ \
  || echo "local down -> use noogle.dev"
```

Path and query are identical on both hosts, so only the origin changes. Mention the
fallback only when it was actually used.

## URL shape

```
https://<host>/q/?term=<query>[&from=<type>][&to=<type>][&page=<n>][&limit=<n>]
```

| Param   | Meaning                                              | Values                                                        |
| ------- | ---------------------------------------------------- | ------------------------------------------------------------- |
| `term`  | name or words describing the function; spaces as `+` | free text                                                     |
| `from`  | filter by the function's **input** type              | `any`, `attrset`, `bool`, `list`, `number`, `string`          |
| `to`    | filter by the function's **return** type             | `any`, `attrset`, `bool`, `list`, `never`, `number`, `string` |
| `page`  | result page (default `1`)                            | integer                                                       |
| `limit` | results per page (default `10`)                      | integer                                                       |

- `any` (or omitting the param) disables that filter.
- `never` means the function never returns normally (throws/aborts).
- Keep the trailing slash: `/q?term=...` redirects with a 308, so use `/q/?term=...`.

Only the listed filter values are valid. Omit `from`/`to` rather than guessing.

## Recipes

By name:

```
https://noogle.proteus.eu.org/q/?term=foldlAttrs
```

Name + return type (something that produces a list):

```
https://noogle.proteus.eu.org/q/?term=map+attrs&to=list
```

Input type (something that consumes an attrset):

```
https://noogle.proteus.eu.org/q/?term=map&from=attrset
```

Input + output type (attrset -> list):

```
https://noogle.proteus.eu.org/q/?term=map&from=attrset&to=list
```

## Workflow

1. Turn the request into search words plus type constraints:
   - "convert / produce a list" → `to=list`
   - "takes / consumes an attrset" → `from=attrset`
   - an identifier the user named → put it in `term` verbatim.
2. Do not put type words into `term` when a `from`/`to` filter expresses them.
3. Build the URL, then (optionally) health-check the host with the `curl` above.
4. Present it as a normal markdown link; keep it clickable.
5. Results are rendered client-side, so `curl` only proves the page loads. To answer
   "which function should I use", scrape the link with Firecrawl (see below) or give the
   user the link instead of inventing a result.

## Using Firecrawl

Noogle renders results in the browser, so use the `firecrawl` MCP when you need the actual
matches:

- `firecrawl_scrape` with `formats: ["markdown"]`, `onlyMainContent: true`,
  `waitFor: 3000`, `maxAge: 0` returns the rendered result cards (name, signature,
  description, source links).
- For structured output, use `formats: ["json"]` with a schema such as

  ```json
  {
    "results": [
      { "name": "string", "signature": "string", "description": "string" }
    ]
  }
  ```

  and a prompt like "Extract every search result: function name, type signature, and
  description."

- If the first render is empty, retry with
  `actions: [{"type": "wait", "milliseconds": 3000}]` or `waitFor: 5000`.
- Use `firecrawl_search` (optionally `includeDomains: ["noogle.dev"]`) only to discover an
  identifier you do not know; then rebuild the `/q/?term=` URL.

Example scrape (use the host chosen by the health check):

```json
{
  "url": "https://noogle.proteus.eu.org/q/?term=map&from=attrset&to=list",
  "formats": ["markdown"],
  "onlyMainContent": true,
  "waitFor": 3000,
  "maxAge": 0
}
```

If Firecrawl fails (401, outage), degrade gracefully: give the user the link and say the
page could not be rendered. Never invent a function name or signature.

## Notes

- Exact identifiers (`foldlAttrs`, `mapAttrs`, `lib.lists.foldr`) are the most reliable
  searches; use plain words when the name is unknown.
- The filters are about **types**, not names: `map` + `from=attrset&to=list` means
  "functions called/related to map that take an attrset and return a list".
- Results include `builtins`, `lib`, and primops; check the signature and description
  before recommending a function.
- One focused link per question is better than several overlapping ones; offer an
  alternative link only when the request is ambiguous.
