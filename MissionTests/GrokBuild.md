## Assistant

All seven mission scripts now finish with Test: COMPLETE Pass 0. Pass and Failure come from Condition / Else in Test_Assert.xml, not from me comparing log values by hand.

Each script was run on a dedicated server (PlayerActor as the stand-in ship, no client). That server was started and killed per script; nothing is running now.

Scripts

┌────────────────────┬───────────────────────────────────────────────────────────────────────────────────────┬────────────────────────────┐
│ Script             │ Manual coverage                                                                       │ Result                     │
├────────────────────┼───────────────────────────────────────────────────────────────────────────────────────┼────────────────────────────┤
│ Test_01_Values.xml │ Log, values, arithmetic, vectors, TransformValue, Overlap, actor/server params        │ Pass                       │
├────────────────────┼───────────────────────────────────────────────────────────────────────────────────────┼────────────────────────────┤
│ Test_02_           │ Execute + Local.ArgN, Include, EntryPoint, Replace, Wait, Loop, Break, Condition      │ Pass                       │
│ ControlFlow.xml    │ /Else, Stop                                                                           │                            │
├────────────────────┼───────────────────────────────────────────────────────────────────────────────────────┼────────────────────────────┤
│ Test_03_Actors.xml │ CreateActor, SetPosition/Rotation/Velocity, Parent frame, wing spawn, DeleteActor,    │ Pass (TeamID="255" reads   │
│                    │ KillActor                                                                             │ back as -1)                │
├────────────────────┼───────────────────────────────────────────────────────────────────────────────────────┼────────────────────────────┤
│ Test_04_AI.xml     │ CreatePath, SetAIState, bandit spawn, Timer WarpOut, SetAIPath, MoveAI, SetActorPath  │ Pass                       │
├────────────────────┼───────────────────────────────────────────────────────────────────────────────────────┼────────────────────────────┤
│ Test_05_Triggers   │ ActorCreated, ActorDestroyed, ActorProperty, Timer, Condition, ResetTrigger, Unique,  │ Pass                       │
│ .xml               │ DeleteTrigger, ActorLookAt, InterruptTrigger                                          │                            │
├────────────────────┼───────────────────────────────────────────────────────────────────────────────────────┼────────────────────────────┤
│ Test_06_Hardpoints │ Get/SetHardpointStatus, AmmoUsageRatio                                                │ Pass                       │
│ .xml               │                                                                                       │                            │
├────────────────────┼───────────────────────────────────────────────────────────────────────────────────────┼────────────────────────────┤
│ Test_07_           │ SaveToDB / LoadFromDB, server settings                                                │ Pass                       │
│ Persistence.xml    │                                                                                       │                            │
└────────────────────┴───────────────────────────────────────────────────────────────────────────────────────┴────────────────────────────┘

Logs: MissionTests/results/*_MissionRuntime.txt. Each subtest line is Test: <name> Pass|Failure|Skipped <actual>.

Comparison conditions that were wrong or weak

• DistanceValue with bare names (PlayerActor, Outpost) evaluates to 0. The manual’s “two actors” form needs Actor:PlayerActor and Actor:Outpost.
• Unique used 30s timers that never fired, so it did not test uniqueness. It now creates two Unique="true" timers; only the first runs (UniqueFired=1).
• In / NotIn / Lower / LowerEqual, case-insensitive In, and case-sensitive Equal were missing from the control-flow script and are now asserted.

Per the manual and the instruction to skip anything that cannot run without a player: AwaitPlayers, Sync, FadeIn, SetCameraPath, transmissions, highlights, SetPlayerState, input/UI, objectives, waypoints, and the Player* / TargetSelected / ActorAimAt triggers.

---

What the conditions showed

┌─────────────────────────────────────────┬────────────────────────────────────────────┬───────────────────────────────────────────┐
│ Subtest                                 │ Comparison                                 │ Result                                    │
├─────────────────────────────────────────┼────────────────────────────────────────────┼───────────────────────────────────────────┤
│ MineLauncher_ActorCreated               │ ActorCreated of class ProximityMine ≥ 1    │ Pass (OutValue=1, count 1)                │
├─────────────────────────────────────────┼────────────────────────────────────────────┼───────────────────────────────────────────┤
│ MineLauncher_classCount                 │ loop count of ProximityMine increased      │ Pass                                      │
├─────────────────────────────────────────┼────────────────────────────────────────────┼───────────────────────────────────────────┤
│ StartAbility_MissilePod_notAbility      │ OutValue=0 (weapon, not an ability)        │ Pass                                      │
├─────────────────────────────────────────┼────────────────────────────────────────────┼───────────────────────────────────────────┤
│ StartAbility_MissileLauncher_notAbility │ same for MissileLauncherMK3                │ Pass                                      │
├─────────────────────────────────────────┼────────────────────────────────────────────┼───────────────────────────────────────────┤
│ FireState_MissilePod_noClient           │ no extra LightMissile after FireState=1    │ Pass (did not occur)                      │
├─────────────────────────────────────────┼────────────────────────────────────────────┼───────────────────────────────────────────┤
│ Detonate_ownedMine                      │ ActorDestroyed on the launched mine        │ Skipped — OutValue=1, mine still there    │
├─────────────────────────────────────────┼────────────────────────────────────────────┼───────────────────────────────────────────┤
│ Detonate_scriptMissile                  │ ActorDestroyed on CreateActor LightMissile │ Skipped — OutValue=1, missile still there │
└─────────────────────────────────────────┴────────────────────────────────────────────┴───────────────────────────────────────────┘

Meaning

• Missile pods are weapons, not abilities. StartAbility Abilities="MissilePod" / "MissileLauncherMK3" returns 0 and spawns nothing.
• FireState does not launch a missile without a client. No LightMissile actor. AI MissileFrenzy also spawned none in an earlier pass.
• Detonate cannot be proven without a weapon-fired missile. The ability starts (OutValue=1) on an unoccupied ship, but it did not destroy the MineLauncher mine or a script-spawned LightMissile. Those are not “owned missiles” in the sense Detonate uses. A real fired missile never appeared without a client, so that subtest is skipped rather than failed.

Loadouts used (copied into the server Loadouts folder): MissionTests/Loadouts/MissionTest_Miner.xml (Destroyer + MineLauncher + Detonate) and MissionTest_Detonate.xml (Interceptor + MissilePod + Detonate). Log: MissionTests/results/Test_08_StartAbility_MissionRuntime.txt.