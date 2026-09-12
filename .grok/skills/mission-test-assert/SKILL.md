---
name: mission-test-assert
description: >
  Write Infinity Battlescape mission-script tests with MissionTests/Test_Assert.xml
  so Condition helpers log Pass/Failure/Skipped. Use when adding or editing
  MissionTests XML, asserting runtime values, or the user runs /mission-test-assert.
---

# Mission script asserts

Judge results from `Condition` helpers in `MissionTests/Test_Assert.xml`. Do not eyeball expected values in the log. Launch and stop the dedicated server with the `ib-mission-server` skill.

## Skeleton

Every test mission:

```xml
<Mission ID="9xx" Category="Workshop" Title="Test_NN_Name" Descr="..." Tags="TEST" GameMode="Custom">
	<Include Target="$Current/Test_Assert.xml" />
	<SetValue Target="Global.FailCount" Source="0" />
	<Log Text="Test: $(Arg1) $(Arg2) $(Arg3)" Arg1="BEGIN" Arg2="Test_NN_Name" Arg3="ok" />

	<CreateActor Name="PlayerActor" Class="Interceptor" TeamID="1" Loadout="Default" AI="false" DisplayName="PlayerActor" />
	<SetPosition Target="PlayerActor" X="0" Y="0" Z="0" />

	<!-- Execute Target="Assert..." Arg1="subtest" Arg2="actual" Arg3="expected" /> -->

	<Execute Target="AssertDone" />
</Mission>
```

`Arg1`..`Arg7` on `Execute` become `Local.ArgN` in the group (evaluated in the caller). `Test_Assert.xml` is an include fragment (several `<Actions>` roots), not a `<Mission>`.

## Helpers

Call with `Execute`. Contract: `Arg1` = subtest name, `Arg2` = actual, `Arg3` = expected (unused by `AssertSkipped` / `AssertDone`).

| Group | Pass when |
|---|---|
| `AssertEqual` | `Arg2` Equal `Arg3` (numeric with tolerance, else case-sensitive text) |
| `AssertNotEqual` | NotEqual |
| `AssertHigher` / `AssertHigherEqual` / `AssertLowerEqual` | numeric order |
| `AssertIn` | `Arg2` In `Arg3` (list or text; case-insensitive) |
| `AssertNear` | `\|Arg2 - Arg3\| ≤ 0.01` |
| `AssertVec3` | `DistanceValue(Arg2, Arg3) ≤ 0.01` (use this for positions/vectors, not `AssertEqual`) |
| `AssertSkipped` | always; logs `Skipped`; does **not** increment `FailCount` |
| `AssertDone` | `Global.FailCount` Equal `0` → `Test: COMPLETE Pass 0`, else `Failure` and the count |

Failure logs `Test: <name> Failure <actual>` and adds 1 to `Global.FailCount`. Pass logs `Test: <name> Pass <actual>`.

Do not add a new helper when an existing comparison already fits. If you must, put it in `Test_Assert.xml` and keep the same `Test: $(Arg1) $(Arg2) $(Arg3)` log line.

## What to assert

- Observable world or memory: class names, counts, flags, `ActorCreated` / `ActorDestroyed` counters, hardpoint totals.
- `StartAbility` that creates an actor: count the new class (e.g. `ProximityMine`), not only `OutValue`.
- Vectors via `AssertVec3`. `TeamID="255"` reads back as `-1`.
- `Timer` / `Condition` triggers default to `Players` and do nothing with nobody in game. Set `Target="Actor:Name"` (often `PlayerActor`).

## Skip vs fail

`AssertSkipped` when the example cannot run without a joined player (HUD, `SetPlayerState`, transmissions, `Player*` triggers, `FireState` missiles, `Detonate` of a weapon-fired missile). Keep the PDF actions if useful, then skip the comparison.

Fail when the example should work on a dedicated server with `PlayerActor` only (`StartAbility` that spawns an actor, such as `MineLauncher` → `ProximityMine`, does).

Custom loadouts: keep XML under `MissionTests/Loadouts/` and copy into the server Documents `Loadouts` folder **before** start (see `ib-mission-server`).
