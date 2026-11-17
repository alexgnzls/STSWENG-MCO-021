# Tests (QA)

Test code for the Mang Juan Admin Support side (Group 021, Team 4 user stories D01-D20).
The app itself stays at the repo root; everything QA-related lives here.

## Layout

```
tests/
├── e2e/                    Robot Framework + SeleniumLibrary (browser tests)
│   ├── requirements.txt    Python packages for the e2e suite
│   ├── resources/
│   │   └── common.robot    Shared variables (BASE_URL, BROWSER) and keywords
│   ├── suites/             One .robot file per user story, e.g. D01_login.robot
│   └── results/            Robot output (log/report/output.xml), git-ignored
├── unit/                   Vitest unit tests for pure logic (payroll math, status rules)
└── test-cases/             Written test case documents / exports
```

## Naming

- Suite files: `<StoryID>_<feature>.robot`, e.g. `D07_resolve_case.robot`
- Test case IDs: `TC-<StoryID>-<NN>`, e.g. `TC-D07-03`
- Tags: story ID, feature, and priority (`must` / `should` / `could`)
- Branches for PRs into dev-web: `test/<StoryID>-<short-name>`, e.g. `test/D01-login`

## Running the e2e suite

```bash
# 1. Start the app (from the repo root)
npm install
npm run dev            # serves http://localhost:5173

# 2. In another terminal
pip install -r tests/e2e/requirements.txt
robot --outputdir tests/e2e/results tests/e2e/suites
```

Run one story: `robot --outputdir tests/e2e/results tests/e2e/suites/D01_login.robot`
Run by tag:    `robot --outputdir tests/e2e/results --include must tests/e2e/suites`
