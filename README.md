Scripts for running a local and dedicated server of Infinity: Battlescape video game.

# Skills

Two project skills are in .grok/skills/. They should show up in the slash menu within a few seconds.

┌─────────────────────┬───────────────────────────────────────────┬──────────────────────┐
│ Skill               │ Path                                      │ Slash                │
├─────────────────────┼───────────────────────────────────────────┼──────────────────────┤
│ mission-test-assert │ .grok/skills/mission-test-assert/SKILL.md │ /mission-test-assert │
├─────────────────────┼───────────────────────────────────────────┼──────────────────────┤
│ ib-mission-server   │ .grok/skills/ib-mission-server/SKILL.md   │ /ib-mission-server   │
└─────────────────────┴───────────────────────────────────────────┴──────────────────────┘

mission-test-assert is the recipe for a new MissionTests XML: include Test_Assert.xml, zero FailCount, PlayerActor, Execute helpers (Arg1 name / Arg2 actual / Arg3 expected), AssertDone, and when to AssertSkipped vs fail. Helper implementations stay in Test_Assert.xml; the skill only documents the call contract.

ib-mission-server is the run loop: kill_server.bat → copy loadouts → start_server.bat mission <abs-path> → poll MissionRuntime.txt for Test: COMPLETE → copy into MissionTests/results/ → kill_server.bat. It starts and kills only that dedicated server (no client unless the mission needs a join).

Each skill points at the other instead of repeating its steps. Also available via /skills mission-test-assert and /skills ib-mission-server, or automatically when you add tests or run a mission XML.