---
name: ib-mission-server
description: >
  Start and stop the local Infinity Battlescape dedicated server to run a mission
  XML, then read MissionRuntime.txt. Use when executing MissionTests, running
  start_server.bat mission or entrypoint, or the user runs /ib-mission-server.
---

# Run a mission on the dedicated server

Repo-root scripts: `start_server.bat`, `kill_server.bat`, `ib_env.bat`. Paths and defaults live in `ib_env.bat` (`IB_EXE`, `IB_DOCS_SERVER`, `IB_SERVER_PID_FILE`).

Start and kill **only** this test server. Do not start `start_client.bat` unless the mission cannot run without a joined player.

## One mission

1. `kill_server.bat` if `server.pid` exists or an `Infinity Battlescape.exe` with `-server` is running.
2. Copy any custom loadouts from `MissionTests/Loadouts/` to `%IB_DOCS_SERVER%\Loadouts\` (create the folder if needed). The server reads loadouts by **name** at process start.
3. Start (absolute mission path). Defaults already match tests: nosteam, private, `-reboot` (no DB):

```bat
start_server.bat mission C:\Programming\grok-build\ib-server\MissionTests\Test_01_Values.xml
start_server.bat mission C:\Programming\grok-build\ib-server\MissionTests\Test_09_EntryPoint.xml entrypoint Custom
```

The bat waits until named event `ServerStarted` (30s) and writes `server.pid`. Exit 0 means the process is up. Instant mission work may already be done by then.

4. Poll `%IB_DOCS_SERVER%\Logs\MissionRuntime.txt` until a `Test: COMPLETE` line appears, or until the mission’s own `Wait` budget plus ~10s. Typical extra wait: a few seconds; `KillActor` / trigger tests can take ~5–8s. Timeout ~90s after start returns.
5. Copy that log to `MissionTests/results/<stem>_MissionRuntime.txt`.
6. `kill_server.bat`. Confirm no `-server` process and no leftover `server.pid`.

One process loads one `-mission` file. For several scripts: kill, start next, poll, copy, kill. Do not leave the server running.

`start_server.bat` refuses to start if `server.pid` still names a live IB process.

## Reading results

Missions that include `Test_Assert.xml` (see `mission-test-assert`) log:

```
Test: <subtest> Pass|Failure|Skipped <actual>
Test: COMPLETE Pass|Failure <FailCount>
```

`COMPLETE Pass 0` is success. `Skipped` does not fail the suite. Grep `Test:` only; ignore `Action N:` noise unless diagnosing a skip/fail.

`Invalid action found: ...` on an unknown element is expected when the test plants a bogus action.

If `ServerStarted` is not signaled, the process may still be running; check the log. A `-shared` client will not join until that event is set.

## Options (only when needed)

| Arg | When |
|---|---|
| `db` | Persistence that must load the previous DB (`SaveToDB` in-session still works with default `reboot`) |
| `public` | Public dedicated instead of private |
| `steam` | Add `-steam` |
| `config <xml>` | Alternate `-serverconfig` (default `PrivateSharedServerConfig.xml`) |
| `entrypoint <name>` | Pass `-entrypoint` so `Global.EntryPoint` is `<name>` instead of `Main`. Use when the script under test is gated on that name (see `mission-test-assert`). |
