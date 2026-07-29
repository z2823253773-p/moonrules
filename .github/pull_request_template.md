## Goal

<!-- What problem does this PR solve? One or two sentences. -->

## Scope

<!-- Which modules, files, or concerns does this PR touch? -->

## Behavior

<!-- What changed? Include before/after when it helps reviewers. -->

## Verification

- [ ] `moon fmt --check`
- [ ] `moon check --deny-warn`
- [ ] `moon test --target native`
- [ ] `moon test --target wasm-gc`
- [ ] `moon build --target native`
- [ ] Playground tests and build pass when affected (`cd playground && npm test && npm run build`)

## Evidence

<!-- Paste terminal output, screenshots, or benchmark data that supports this change. -->

## Boundaries

- [ ] No DSL or three-state semantic change unless separately approved in the linked issue.
- [ ] No credentials, `.env` files, generated build artifacts, or unrelated files.
- [ ] `THIRD_PARTY_NOTICES.md` updated if new dependencies were added.
