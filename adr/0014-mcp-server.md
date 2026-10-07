# ADR-0014 — Applicable products ship an MCP server

**Status:** Accepted

## Context

More and more of the work our products support is done by an agent working for a person: Claude Code, the Agent SDK, any MCP client. A product that only offers a browser UI makes that agent drive the UI, scrape the page, or skip the product. The product stops being where the work happens.

`os` solved this in October 2026 (os ADR-0019, PRs #60 and #61; design: `os/docs/plans/2026-10-06-agent-mcp-server-design.html`). Agents log work, book transactions, triage the bank queue and run a month-end check over twelve MCP tools, with no clicking. Building it showed what makes this safe and useful rather than a second, weaker API:

- **The agent needs its own principal.** Session JWTs are short-lived, come from a browser and carry MFA (ADR-0009, ADR-0012). An MCP client cannot present one. `os` added org-scoped, scoped agent tokens that a member with a second factor mints, and a `requireAgentAccess` guard that resolves the token to the same context the person-facing guard returns.
- **Agent writes must follow the person's write paths.** Person and agent mutations call the same helpers (`insertWorkLog`, `insertTransaction`, `upsertAccountBalance`). `month_end_report` reuses the Cashflow page's roll-forward. If agent and person used separate code, they would reach different verdicts on the same data.
- **Agent input is free text, not a form.** It needs stricter validation, and every agent-made row needs provenance so a mistake can be found and undone.

## Decision

- **Every Rising Company product that holds a person's or an org's data, or does recurring work for them, ships an MCP server.** It has the same standing as the link preview card (ADR-0013): a per-product obligation, not a later add-on. A product is **not applicable** only if it has no per-user state and no actions. Example: a calculator whose state is entirely in the URL. Record that call in the project's `CLAUDE.md` so it is a decision, not something nobody got to.
- **Tools are shaped like the jobs a person does, not like database tables.** Name them after the work (`log_work`, `month_end_report`), not `insert_row`. Every server has a `get_context` tool to call first. It returns who the token acts for, its scopes, and the ids and keys the other tools take. Tool and argument names are `snake_case`. Descriptions are written for a model: say when to call the tool and where each id comes from.
- **The agent is a second principal and gets a separate guard.** A member mints a token in **Settings → Agents**, and minting requires a session with a second factor. Each token is bound to **one org** and a set of **scopes**. Only its SHA-256 is stored and the plaintext is shown once. A token stops working when it is revoked or its minter leaves the org. The guard takes the org from the token, never from arguments, and checks scope on **every call**, not only in `tools/list`. Reference: `os/convex/lib/agentAccess.ts`.
- **One write path.** Agent tools call the same domain helpers as the person-facing Server Actions (ADR-0003), passing a context that has already been authorized. They add stricter input checks on top. They never get a separate implementation.
- **Agents can delete only what they wrote.** Rows an agent creates record the token that wrote them (`agent_token_id`). Delete tools refuse other rows. Agents can do only what a person in that org could do by hand.
- **Transport:** stateless, JSON-only MCP Streamable HTTP at `POST /mcp` on the product's backend, with no sessions and no SSE. Refuse requests that carry an `Origin` header, which guards against DNS rebinding. This is the **one sanctioned HTTP endpoint** besides auth callbacks, and a deliberate exception to ADR-0003. Use the official MCP SDK where the runtime allows it. Hand-roll the JSON-RPC layer when it doesn't, as `os` did under Convex's V8 runtime (`os/convex/mcp/protocol.ts`).
- **Tested like everything else** (ADR-0006): protocol tests (`initialize`, `tools/list`, `tools/call`, malformed JSON-RPC), guard tests (unknown, revoked, lapsed-member and out-of-scope tokens), and one test per tool. Before declaring the work done, **connect a real MCP client** (`claude mcp add --transport http …`) and run a task end to end. For agent features, this is the equivalent of driving the UI with `agent-browser`.

## Consequences

- Products become **AI-native**. Anything a person can do in the UI, their agent can do with the same rules, the same audit trail and the same answers. New features ask "should agents have this?" the same way they ask about accessibility (ADR-0011).
- **Existing products need a retrofit**: `huddle`, `venue-map`, `safe` and `fc_tank` each need either their own tool set or a recorded "not applicable". Like the preview card, choosing the tools is a design task for each product, not a copy-paste. `os` is the reference.
- A leaked token acts as its minter, within one org and its scopes, until someone revokes it. Tokens don't expire on their own. Settings → Agents shows `last_used_at` so idle tokens can be revoked. Revoked rows are kept as an audit record (ADR-0010).
- claude.ai custom connectors need OAuth, which bearer tokens don't provide. When id.rising.company (ADR-0012) gets an OAuth provider, its access tokens should resolve to the same context at the same guard. Tool code shouldn't need to change.
- Every product now has a machine-facing surface to keep correct. Schema changes that touch a tool's inputs or outputs must update that tool and its tests in the same change.
