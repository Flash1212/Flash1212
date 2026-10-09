# Compaction Prompt

The following is a prompt for performing a CONTEXT CHECKPOINT COMPACTION. It is designed to help you summarize the current state of a conversation or project, so that another instance of yourself can seamlessly pick up where you left off.

---

You are performing a CONTEXT CHECKPOINT COMPACTION.
Write a handoff briefing for the desktop instance of yourself
that will seamlessly resume this conversation.

Use this exact structure:

# Handoff: [one-line task summary]

## Goal

[What the user is trying to accomplish, 1–3 sentences]

## Current State

- [Concrete artifacts produced — not narrative]
- [What is in progress]
- [What is blocked]

## Decisions Made (do not re-litigate)

- [Decision] — [one-line reason]

## User Preferences & Constraints

- [Tone, format, scope, hard limits discovered so far]

## Open Questions

- [Unresolved items the user hasn't answered]

## Next Step

[The single next thing the desktop instance should do]

## Key Data

[File paths, URLs, code snippets, error messages,
 variable names — anything verbatim the next instance needs]

Rules:

- Be ruthless. No pleasantries, no re-stating what was tried
  and rejected unless the rejection reason matters.
- The WHY behind decisions matters more than the WHAT.
- If a prior compaction summary exists in context, fold its
  key points into a "Historical Context" section at the top.
