# Fork changes

Personal fork of [nikshriv/hass_navien_water_heater](https://github.com/nikshriv/hass_navien_water_heater),
forked at upstream commit `2d76924`. Bumped to version `1.0.3`.

These patches fix several open upstream issues and bugs found in review.

## Bug fixes

- **Background tasks leaked on every unload/reload.** `_start()` waited with
  `asyncio.FIRST_EXCEPTION`, but on a clean shutdown the poll task exits without
  raising, so the wait never returned and the connection-lost and 2 AM-refresh
  tasks were never cancelled (a stale refresh task would later call
  `disconnect()` on a dead client). Switched to `FIRST_COMPLETED`.
- **Unloading mid-reconnect didn't stop the reconnect loop.** `disconnect()`
  only set `shutting_down` inside its `client and connected` guard, so unloading
  while disconnected left the reconnect loop running. It now records a real
  shutdown unconditionally (and reconnect-driven calls never clear it).
- **Crash with multiple units on one channel (upstream #45).** `convert_channel_status`
  iterated `range(unitCount)` and indexed into `unitStatusList`, raising
  `IndexError` when the device reported a `unitCount` larger than the actual
  list. Both conversion loops now iterate over the list that is present.
- **Automations could not turn the heater on/off (upstream #40).** Added
  `async_turn_on` / `async_turn_off` (mapped to the power command) and the
  `ON_OFF` water-heater feature flag, so the `water_heater.turn_on` /
  `turn_off` services work instead of raising `NotImplementedError`.
- **Setup could hang HA boot / "Global task timeout" (upstream #46, #48).**
  `async_setup_entry` now fails fast with `ConfigEntryNotReady` (transient) or
  `ConfigEntryAuthFailed` (bad credentials) instead of looping forever inside
  setup. The runtime reconnect loop is unchanged. Added 30-second timeouts to
  the login and device-list HTTP calls.
- **Broken cross-unit temperature conversion.** `async_set_temperature` used
  `==` (comparison) instead of `=` (assignment) on two branches, so when the
  HA unit system differed from the heater's the raw value was sent unconverted.
- **`datetime.utcnow()`** (deprecated) replaced with a timezone-aware call.
- **Bare `except:`** blocks narrowed (notably one around `asyncio.wait_for`
  that could swallow `CancelledError` during shutdown).

## Usability / cleanup

- Password field is now masked in the config flow (password selector).
- The config flow distinguishes invalid credentials (`invalid_auth`) from a
  cloud-connection failure (`cannot_connect`) instead of reporting every
  failure as bad credentials.
- Removed unused imports (`asyncio.sleep`, `homeassistant.core.callback`).

## Not changed (and why)

- **Cumulative gas use "too high" (upstream #18):** verified the math — the
  reported cubic-feet total matches the app's therm total to within ~1%
  (therms are energy, ft³ are volume). Not a code bug.
- **Slow second config entry (upstream #53):** a successful-but-slow setup,
  not an error, so it needs profiling on a real multi-device account.
