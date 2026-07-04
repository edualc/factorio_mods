# Claude Code Instructions

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

## Multiplayer desync check

Before committing any change, review whether the change could cause desyncs when the mod runs on a multiplayer server.

Common desync sources to check:
- Reading non-deterministic state: `math.random` without a seeded RNG, `os.time`, `os.clock`, or Lua `table` iteration order on non-array tables
- Using `game.players` index directly instead of iterating `event.player_index` or a stable ordered list
- Storing references to Lua objects (closures, metatables) in `storage` instead of plain serialisable data
- Calling `rendering` or GUI APIs inside simulation-tick handlers that only run on one client
- Any conditional code path that depends on `script.active_mods`, feature flags, or settings that could differ between clients

If a change touches any of these areas, note it explicitly in the commit message.

---

## README maintenance

Before committing any change, update @README.md to reflect what was changed.

- New feature or fix → add or update the relevant bullet under the mod's **Changes from original** section
- If the change spans multiple mods, update each affected section
- Keep entries factual and specific (what changed and why), matching the tone and level of detail of the existing bullets
