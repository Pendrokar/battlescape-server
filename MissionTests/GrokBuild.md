## Assistant

Seven dedicated-server mission scripts now live in `MissionTests/`. Each one logs `Test: $(Arg1) $(Arg2) $(Arg3)` so the actual value sits next to the expected value in `MissionRuntime.txt` and the server log.

A `PlayerActor` interceptor is the stand-in ship. Nothing waits for a real client. I started and killed only the test dedicated server for each run.

**`start_server.bat`:** `shift` after `mission <path>` was rewriting `%~dp0` to the mission folder, so `ib_launch.ps1` could not be found. The script directory is now captured before any `shift`.

### Scripts and results

| Script | Manual sections | Result |
|---|---|---|
| `Test_01_Values.xml` | Log, values, arithmetic, vectors, TransformValue, Overlap, actor/server params | Pass (unknown action `NotARealAction` skipped as documented) |
| `Test_02_ControlFlow.xml` | Execute + `Local.ArgN`, Include, EntryPoint, Replace, Wait, Loop, Break, Condition/Else, Stop | Pass |
| `Test_03_Actors.xml` | CreateActor, SetPosition/Rotation/Velocity, Parent frame, wing spawn loop, DeleteActor, KillActor | Pass (`TeamID="255"` reads back as `-1`) |
| `Test_04_AI.xml` | CreatePath, SetAIState, bandit spawn, Timer WarpOut, SetAIPath, MoveAI, SetActorPath | Pass |
| `Test_05_Triggers.xml` | ActorCreated, ActorDestroyed, ActorProperty, Timer, Condition, ResetTrigger, Unique, DeleteTrigger, ActorLookAt | Pass except ActorRange (below) |
| `Test_06_Hardpoints.xml` | Get/SetHardpointStatus, AmmoUsageRatio | Pass; StartAbility did not apply (below) |
| `Test_07_Persistence.xml` | SaveToDB / LoadFromDB, server settings | Pass |

Copied logs: `MissionTests/results/*_MissionRuntime.txt` and `*_ServerLog.txt`. Same `Test:` lines appear in both.

### Not tested (need a joined player)

Per the manual, these wait on a client or only fire for a connected player, so they were skipped: `AwaitPlayers`, `Sync`, `FadeIn`, `SetCameraPath`, `SendTransmission Wait`, `WaitTransmissions`, `Highlight`, `SetPlayerState`, input/UI, objectives, waypoints, transmissions/popups/tips, and the Player\* / `TargetSelected` / `ActorAimAt` triggers.

**Tried with `PlayerActor` and did not fire without a join:**
- `ActorRange` (enter/leave) — trigger created, ships teleported in/out, body never ran
- `StartAbility` / `ActorStartAbility` Stealth — `OutValue` stayed `0`

Run one yourself:

```bat
start_server.bat mission C:\Programming\grok-build\ib-server\MissionTests\Test_01_Values.xml
```

Then inspect `Documents\I-Novae Studios\Infinity Battlescape Server\Logs\MissionRuntime.txt` for `Test:` lines. Stop with `kill_server.bat`.