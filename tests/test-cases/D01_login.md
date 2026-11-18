# D01: Admin Login: Test Cases

**User story:** As a support administrator, I want to log in securely so that I can access support and operational tools. (Priority: Must)
**Screen under test:** `src/pages/LoginPage.jsx` (dev-web as of 18 Nov 2026)
**Automated in:** `tests/e2e/suites/D01_login.robot`. Each test name starts with the ID below.

## How the login works right now

- There is no real account check yet. Any non-blank username plus a password of 6 or more characters logs in.
- The login is only kept in memory, so reloading the page logs you out.
- There is no error message when a login is refused; the form just stays on screen.
- Test data used: username `angela.reyes`, password `secret123`. Swap them in `tests/e2e/resources/common.robot` once real accounts exist.

**Preconditions for every case:** the app is running (`npm run dev`), the browser is on the login page, and nobody is logged in.

## Status key

| Status | Meaning |
|---|---|
| Pass | Works as expected today |
| Known bug | D01 requires this, but the current login doesn't do it. The automated test reports it as SKIPPED until it's fixed. |

## Test cases

| ID | Title | Priority | Steps | Test data | Expected result | Status |
|---|---|---|---|---|---|---|
| TC-D01-01 | Valid credentials open the dashboard | Must | 1. Enter username 2. Enter password 3. Click **Sign In** | `angela.reyes` / `secret123` | Support cases page opens; username shown in the sidebar and the header | Pass |
| TC-D01-02 | Password of exactly 6 characters is accepted | Must | Log in with a 6-character password | `angela.reyes` / `abc123` | Dashboard opens (lowest allowed length) | Pass |
| TC-D01-03 | Password of 5 characters is refused | Must | Log in with a 5-character password | `angela.reyes` / `abc12` | Stays on the login page | Pass |
| TC-D01-04 | Empty username and password are refused | Must | Click **Sign In** with both fields empty | (blank) | Stays on the login page | Pass |
| TC-D01-05 | Empty username is refused | Must | Leave username blank, enter a password, click **Sign In** | (blank) / `secret123` | Stays on the login page | Pass |
| TC-D01-06 | Spaces-only username is refused | Must | Enter only spaces as the username, enter a password, click **Sign In** | `"   "` / `secret123` | Stays on the login page | Pass |
| TC-D01-07 | Empty password is refused | Must | Enter a username, leave password blank, click **Sign In** | `angela.reyes` / (blank) | Stays on the login page | Pass |
| TC-D01-08 | Username is trimmed before display | Should | Log in with spaces before and after the username | `"  angela.reyes  "` / `secret123` | Sidebar shows `angela.reyes` with no extra spaces | Pass |
| TC-D01-09 | Avatar shows the capitalized first letter | Could | Log in, look at the circle in the header | `angela.reyes` / `secret123` | Circle shows `A` | Pass |
| TC-D01-10 | Pressing Enter submits the form | Should | Fill both fields, press **Enter** in the password field | `angela.reyes` / `secret123` | Dashboard opens | Pass |
| TC-D01-11 | Password characters are hidden | Must | Type in the password field | any | Characters show as dots (field type is `password`) | Pass |
| TC-D01-12 | Sidebar Sign out returns to login with empty fields | Must | 1. Log in 2. Click **Sign out** in the sidebar | valid | Login page shows; both fields are empty | Pass |
| TC-D01-13 | Header Logout returns to login | Must | 1. Log in 2. Click **Logout** in the header | valid | Login page shows | Pass |
| TC-D01-14 | Reloading after logout stays on login | Must | 1. Log in 2. Sign out 3. Reload the page | valid | Still on the login page; no access to the dashboard | Pass |
| TC-D01-15 | Wrong password is refused | Must | Log in with a real username and the wrong password | `angela.reyes` / `wrongpass999` | Stays on the login page | **Known bug**: any 6+ character password works |
| TC-D01-16 | Unknown username is refused | Must | Log in with a username that has no account | `nobody.here` / `secret123` | Stays on the login page | **Known bug**: any username works |
| TC-D01-17 | Refused login shows an error message | Should | Log in with a 5-character password | `angela.reyes` / `abc12` | An error message explains why (e.g. "Invalid username or password") | **Known bug**: no message is shown |
| TC-D01-18 | Session survives a page reload | Should | 1. Log in 2. Reload the page | valid | Still logged in on the dashboard | **Known bug**: reload logs you out |
| TC-D01-19 | Forgot password link opens a reset flow | Could | Click **Forgot password?** | n/a | A reset page or form opens | **Known bug**: link goes to `#forgot` and does nothing |

## Not covered yet (add once the feature exists)

- **Separate admin roles:** support admin vs disbursement admin logins see the right tools. Right now everyone is shown as "Administrator".
- **Lockout or rate limit** after repeated wrong passwords.
- **Session expiry** after a period of inactivity.

## Last run

18 Nov 2026, dev-web: **19 tests, 14 passed, 0 failed, 5 skipped (known bugs).**
