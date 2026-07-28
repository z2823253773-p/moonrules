# MoonRules agent contract

Read `.ai/TASK_STATE.md` and the approved design before editing.

Commands: `moon fmt --check`, `moon check`, `moon test`, `moon build --target native`.

Keep the reusable engine free of filesystem, network, environment, and process APIs. Native side effects belong only in `cmd/main`.

Follow TDD, keep commits small, and update `.ai/TASK_STATE.md` after each task. Do not add full JSONLogic compatibility, array-index paths, a server, a
database, a native desktop GUI, or credential files. The approved v0.2 static
local-only Web Playground is the only GUI exception; browser side effects stay
under `playground/`.
