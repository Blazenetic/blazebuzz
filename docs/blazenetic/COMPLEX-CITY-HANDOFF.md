# Complex City — Buzz preparation handoff

> **Status (13 November 2026):** Documentation and readiness only. Buzz is the preferred candidate for Complex City's internal staff-and-agent workspace; no deployment, pilot, production integration, custom client work or adoption has been authorised.

## Canonical planning source

The authoritative research, decisions and agent work packages live in the **restricted Google Drive Complex City workspace**:

- [Buzz research and preparation folder](https://drive.google.com/drive/folders/1HVuOv0bDVCNtsdYYdMmAXCBl7Cm6_2Xj)
- [06 — START HERE — Buzz Preparation & Agent Handoff](https://docs.google.com/document/d/1g6-tkv_kJAU3bT5Bo4_BJbdVWFeRMV4j9XWZAcd2WI8/edit)
- [05 — Recommendation and Decision Register](https://docs.google.com/document/d/1dc1OCX7uTXz2OMQFS_9OOU6SidBT_SUWwXQb2appofI/edit)

These links may require separately granted access. **This repository is public:** do not copy restricted Drive contents, credentials, business evidence, private contacts or internal operational records into GitHub. If Drive is unavailable, request access; do not infer decisions from stale fork notes.

## Intent and boundaries

Complex City is an internal operating environment for a small human-and-AI team (approximately seven human staff). Buzz would be the **daily communications home**, with shared, centrally managed agents first and personal agents later. Excellent Android and iPhone foreground chat is required. Routine background chat push may be delayed, but important operational alerts need a reliable path. Initial access is intended through NetBird on a Linux/OpenShip homelab, with possible VPS migration.

The founder initially owns staff identity/key recovery. The responsible business owner owns important operational alerts first; the founder is the initial fallback. Exact alert thresholds, acknowledgement deadlines and contact routes remain undecided.

**System-of-record boundaries:** Buzz owns conversation and membership; Complex City owns the business-facing brief/attention experience; Project Desk owns project work and decisions; T3 Code owns coding execution; GitHub owns code/CI; Agent Grove and Usage Atlas are separate specialist systems. Human authorisation remains required for consequential actions.

**Known caution:** Reviewed Buzz media access defaults are too broad to assume confidential attachments are safe in private rooms. Keep restricted files at their authoritative source and use permissioned links until enforcement is verified. Stock phone onboarding, reconnect, key recovery, active-session revocation and OpenShip compatibility are not yet proven in this environment.

## Preparation packages (no execution)

1. **WP-01 — Staff identity, recovery and offboarding:** key/device lifecycle, loss and revocation; founder-operated runbook.
2. **WP-02 — Important alerts and escalation:** business owner primary, founder fallback, acknowledgement at source, independent contact path; ntfy is optional, not approved.
3. **WP-03 — OpenShip/NetBird readiness:** private DNS, trusted HTTPS/WSS, durable volumes, backups, restore, rollback, mobile reconnection and host failure.
4. **WP-04 — First shared ACP agent:** one separately keyed, limited Linux agent; room/caller allowlist; source-linked, read-only responses; no inherited founder credentials or T3 dispatch.
5. **WP-05 — Founder readiness gate:** consolidate evidence, unresolved decisions and explicit authorisation requirements.

The full scope, acceptance criteria and delegation sequence are in the Drive handoff. WP-01 and WP-02 can be researched independently; WP-03/04 follow with bounded technical design; WP-05 is the liaison's reconciliation and founder review.

## Agent instructions

1. Read [BLAZEBUZZ.md](../../BLAZEBUZZ.md), [fork agent rules](AGENTS.md) and the Google Drive master handoff before work.
2. Distinguish upstream implementation, fork changes, research findings and untested proposals. Pin source revisions and cite evidence.
3. Keep fork-only documentation in `docs/blazenetic/`; avoid changes to upstream Buzz code, workflows or deployment files unless separately authorised.
4. Work in documentation only when assigned a preparation package. Do **not** deploy, run a pilot, connect real accounts, request credentials, purchase services, modify infrastructure or integrate production systems.
5. Save detailed deliverables and decisions in the restricted Drive folder. This public repo should retain only a minimal orientation and links. Never mark untested behaviour as verified.
6. Stop for founder approval before any implementation or rollout.

## Upstream relationship

This is the Blazenetic fork of [block/buzz](https://github.com/block/buzz), not a renamed product. Preserve upstream mergeability and follow [SYNC.md](SYNC.md) for fork updates.
