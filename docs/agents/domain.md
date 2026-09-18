# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

This repo does not keep its own `CONTEXT.md` or `docs/adr/`. Per [AGENTS.md](../../AGENTS.md), Santian holds **code**; the product vocabulary, specs, and decisions live in a sibling repo, **Arcbyte** (`~/Projects/Arcbyte` on this machine, checked out separately — not a build dependency, and CI must not assume it's present).

## Before exploring, read these

- **`../../Arcbyte/ideas/santian/CONTEXT.md`** — the one true glossary for Santian's vocabulary (e.g. **Block**, **Routine**, **DayOfWeek**, **Day**, **Clockface**, **Block list**). Read it before naming or implementing a domain concept.
- **`../../Arcbyte/ideas/santian/hipster/`** and **`../../Arcbyte/ideas/santian/hacker/`** — specs (`kind: spec` artifacts). Read the spec before implementing the feature it describes.
- **`../../Arcbyte/ideas/santian/decisions/`** — numbered, dated ADRs for *why* a product/design choice was made. Don't re-litigate a settled decision without checking whether one already exists.

If Arcbyte isn't checked out locally, or a given file doesn't exist yet, **proceed silently** — don't flag the absence or suggest creating it from this repo. Arcbyte's own domain-modeling workflow owns creating and updating these files; this repo only reads them.

## Layout

Single-context, but hosted outside this repo:

```
Arcbyte/ideas/santian/
├── CONTEXT.md
├── decisions/
│   ├── 0007-....md
│   └── 0008-promote-santian-to-project.md
├── hipster/        ← specs
└── hacker/         ← specs
```

There is no local `CONTEXT.md`, `CONTEXT-MAP.md`, or `docs/adr/` in this repo for the product domain. A decision that's purely about this repo's own code shape (an internal architecture call with no product-facing consequence) *may* live here as a normal ADR under `docs/adr/` if one is created — see AGENTS.md — but that directory doesn't exist yet and skills should not assume it does.

## Use the glossary's vocabulary

When your output names a domain concept (in an issue title, a refactor proposal, a hypothesis, a test name), use the term as defined in Arcbyte's `CONTEXT.md`. Don't drift to synonyms, and don't invent a new term locally — if the concept isn't in the glossary yet, say so and get it added to Arcbyte first (see AGENTS.md, "Code implements the domain model. It does not define it.").

## Flag ADR/decision conflicts

If your output contradicts an existing Arcbyte decision, surface it explicitly rather than silently overriding:

> _Contradicts decision 0008 (promote-santian-to-project) — but worth reopening because…_
