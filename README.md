## Documentation

For documentation and installation guides, please visit our Gitbook:  
[Gitbook](https://rscripts.gitbook.io/r_scripts-docs.)

## Support

For support, bug reports, or feature requests, please join our Discord server:  
[Discord](https://discord.gg/TR38cZFdQk)

## Boilerplate conventions

1. **Copy into a new resource folder** — this repo is a starting template. Build NUI inside the resource (`cd web && pnpm install && pnpm build`), then uncomment `ui_page` in `fxmanifest.lua`.

2. **Config split** — full config lives in server-only `config.lua`. Whitelist client-safe keys in `core/server/main.lua` (`getClientConfig`). NUI receives a further subset via `buildNuiConfig()` in `core/client/_util.lua`.

3. **Defer client init** — hook gameplay setup on `:clientConfigLoaded` (see `core/client/main.lua`) so client code runs after config arrives from the server.

4. **Server authority** — validate all net events and callbacks on the server. Use `IsRateLimited` / `SetRateLimit` from `core/server/main.lua` on spammable handlers.

5. **Shared config exception** — UI-only resources with no sensitive fields (e.g. killfeed) may keep `config.lua` in `shared_scripts`. Do not use that default for economy, locations, or payout data.

6. **Optional MySQL** — uncomment the oxmysql import and `buildDb()` block in `core/server/_util.lua` when the resource needs persistence.

7. **Logging** — use `log('debug' | 'warn' | 'error', ...)` from `core/shared/_util.lua`. A resource-wide logging migration for existing scripts is planned separately.
