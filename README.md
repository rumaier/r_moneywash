## Documentation

For documentation and installation guides, please visit our Gitbook:  
[Gitbook](https://rscripts.gitbook.io/r_scripts-docs.)

## Support

For support, bug reports, or feature requests, please join our Discord server:  
[Discord](https://discord.gg/TR38cZFdQk)

## Configuration notes

1. **Server-only config** — full settings live in `config.lua` (server scripts only). Client-safe keys are whitelisted in `core/server/main.lua` (`getClientConfig`). Teleport/ped coordinates are sent to clients so targeting and teleports work; treat them as public.

2. **Currency** — `Cfg.CurrencyType` is `'account'` (framework balance) or `'item'` (inventory). For QB marked bills, set `Cfg.Currency = 'markedbills'` (worth comes from item metadata; min/max amounts do not apply).

3. **Logging** — set `webhookUrl` in `core/server/_util.lua` for Discord wash logs. Use `log('debug' | 'warn' | 'error', ...)` from `core/shared/_util.lua` for console output.

4. **Defer client init** — gameplay setup runs on `:clientConfigLoaded` / `r_bridge:playerLoaded` after config arrives from the server.

5. **Debug** — `Cfg.Debug` may stay `true` while developing; set it `false` in the customer archive before shipping.
