---
title: AGENTS — where this repo ends and the thinking starts
kind: meta
updated: 2026-09-18
---

# How an AI works in this repo

This repo holds Santian's **code**. It has a sibling thinking space, Arcbyte,
which holds the product vocabulary, specs, and decisions. That split is
deliberate — see Arcbyte's own
[AGENTS.md](../../Arcbyte/AGENTS.md): "Arcbyte holds thinking, not code."
Neither repo's rules apply inside the other.

On this machine, Arcbyte lives at `~/Projects/Arcbyte`, this repo at
`~/Projects/Dev/Santian` — not siblings on disk, just two separate git repos.
The paths below (`../../Arcbyte/...`) are for a human or AI reading this file
locally, not a build dependency; nothing here should import across that path,
and CI must not assume Arcbyte is checked out.

## The domain model lives in Arcbyte, not here

`../../Arcbyte/ideas/santian/CONTEXT.md` is the one true glossary for
Santian's vocabulary — **Block**, **Routine**, **DayOfWeek**, **Day**,
**Clockface**, **Block list**. Use those exact names for types, files, and
variables wherever the code names a domain concept.

- **Code implements the domain model. It does not define it.** If you need a
  concept that glossary doesn't have a word for yet, don't invent one locally
  (a class name, a doc comment) and move on. Say so, and get the term added to
  `ideas/santian/CONTEXT.md` in Arcbyte first — then use it here.
- If a term already in the glossary stops fitting what the code actually
  needs, that's a signal the model is drifting, not a reason to quietly rename
  it in code. Flag it back to Arcbyte instead.
- Purely technical vocabulary that isn't a domain concept — a repository
  class, a DTO, a widget name — is exempt. This rule is about product
  meaning, not engineering nouns.

This is Arcbyte's own confirmed rule (its `CONTEXT.md`, entry **Domain
model**), and the drift signal to watch is named in
[decision 0008](../../Arcbyte/ideas/santian/decisions/0008-promote-santian-to-project.md):
vocabulary invented in code that never makes it back to Arcbyte.

## Specs and decisions live in Arcbyte too

- **What to build, precisely** — specs are `kind: spec` artifacts under
  `../../Arcbyte/ideas/santian/hipster/` and `.../hacker/`. Read the spec
  before implementing the feature it describes.
- **Why a product/design choice was made** — `../../Arcbyte/ideas/santian/decisions/`,
  numbered and dated. Don't re-litigate a settled decision here without
  checking whether one already exists.
- **Tickets/issues in this repo** track implementation status only. Link each
  one back to the Arcbyte spec or decision file it implements, so the "why"
  stays traceable from the code side.
- A decision that is purely about this repo's own code shape (a library
  choice already settled in Arcbyte doesn't need repeating; an internal
  architecture call with no product-facing consequence) can live here as a
  normal ADR if you want one. If it changes what the product does or how it
  behaves, it belongs in Arcbyte, not here.

## Everything else

Normal engineering rules apply here — tests, conventions, tooling — same as
any code repo. Nothing in Arcbyte's `AGENTS.md` (lenses, `evidence:` fields,
`status: draft`, etc.) is relevant on this side; that's for artifacts, and
this repo has none.
