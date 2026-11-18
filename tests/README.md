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
python3 -m venv .venv                         # first time only
source .venv/bin/activate                     # every new terminal
pip install -r tests/e2e/requirements.txt     # first time only
robot --outputdir tests/e2e/results tests/e2e/suites
```

Run one story: `robot --outputdir tests/e2e/results tests/e2e/suites/D01_login.robot`
Run by tag:    `robot --outputdir tests/e2e/results --include must tests/e2e/suites`

## Known-bug tests

Some tests describe behaviour a user story requires but the app doesn't have yet
(e.g. TC-D01-15 "Wrong password is refused"). They're tagged `known-bug` and
`robot:skip-on-failure`, so while they fail they show as **SKIPPED** instead of
breaking the run. When the devs fix the feature, the test starts passing on its own;
then remove the two tags so a future regression shows up as a real failure.

## Troubleshooting

- `SessionNotCreatedException ... ChromeDriver only supports Chrome version X`:
  your ChromeDriver doesn't match your Chrome. Update Chrome, and remove any old
  `chromedriver` on your PATH so Selenium can fetch the right one automatically.
- Watch the browser instead of running headless:
  `robot --variable BROWSER:chrome --outputdir tests/e2e/results tests/e2e/suites`
