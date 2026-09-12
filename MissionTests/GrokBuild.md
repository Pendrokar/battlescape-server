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
• ActorRange and StartAbility / ActorStartAbility still do not fire without a joined player. Those subtests log Skipped requires_player and do not increment FailCount.

Not tested (need a joined player)

Per the manual and the instruction to skip anything that cannot run without a player: AwaitPlayers, Sync, FadeIn, SetCameraPath, transmissions, highlights, SetPlayerState, input/UI, objectives, waypoints, and the Player* / TargetSelected / ActorAimAt triggers.