# D05 — Case notes and responses

The suite imports the D01 browser, admin login and display name from `tests/e2e/resources/common.robot`. Choose one editable QA ticket that the team allows you to annotate.

| Case | Type | Steps and expected results |
| --- | --- | --- |
| TC-D05-01 | Positive | Save a uniquely named note. Verify it appears and the input clears. Sign in again in a fresh browser and open the same ticket. Verify the note appears once with the configured admin name and a timestamp containing digits. Each run adds one note. |
| TC-D05-02 | Negative | Open the ticket. Verify Add note is disabled with empty input and with three spaces. Enter ordinary text and verify the button becomes enabled. This case submits nothing. |

## Run in PowerShell from the repo root

Install dependencies once using the Python interpreter you will run Robot with:

```powershell
python -m pip install -r tests/e2e/requirements.txt
```

In another terminal start the configured app with `npm run dev`. Confirm that the login page renders. In the test terminal enter the case ID from the same environment and run the suite:

```powershell
$env:D05_CASE_ID = Read-Host "Editable QA ticket ID from the Case column"
python -m robot -d tests/e2e/results/D05 tests/e2e/suites/D05_case_notes.robot
```

For headless Chrome, add `--variable BROWSER:headlesschrome` before `-d`. To target another configured QA build, add `--variable BASE_URL:https://your-qa-host`. To run only the read-only case, add `--test "TC-D05-02*"`. Review `tests/e2e/results/D05/log.html` for the detailed result.
