*** Settings ***
Documentation     Shared variables and keywords for all end-to-end suites.
Library           SeleniumLibrary

*** Variables ***
# Where the app runs. Start it first with `npm run dev`.
${BASE_URL}         http://localhost:5173
# Use `--variable BROWSER:chrome` to watch the tests run in a visible window.
${BROWSER}          headlesschrome
${CHROME_OPTIONS}   add_argument("--no-sandbox");add_argument("--disable-dev-shm-usage");add_argument("--window-size=1440,900")
${TIMEOUT}          5s

# Test accounts. Swap these for seeded accounts once real (Supabase) login exists.
${VALID_USER}       angela.reyes
${VALID_PASS}       secret123
${WRONG_PASS}       wrongpass999

# Locators
${USERNAME_FIELD}   id:username
${PASSWORD_FIELD}   id:password
${SIGN_IN_BUTTON}   css:button[type="submit"]
${PAGE_TITLE}       css:header h1
${SIDEBAR_SIGNOUT}  xpath://aside//button[normalize-space()="Sign out"]
${HEADER_LOGOUT}    xpath://header//button[normalize-space()="Logout"]

*** Keywords ***
Open Admin Browser
    Open Browser    ${BASE_URL}    ${BROWSER}    options=${CHROME_OPTIONS}
    Set Selenium Timeout    ${TIMEOUT}
    Login Page Should Be Visible

Log In With
    [Arguments]    ${username}    ${password}
    Input Text        ${USERNAME_FIELD}    ${username}
    Input Password    ${PASSWORD_FIELD}    ${password}
    Click Button      ${SIGN_IN_BUTTON}

Log In As Valid Admin
    Log In With    ${VALID_USER}    ${VALID_PASS}
    Admin Dashboard Should Be Visible

Login Page Should Be Visible
    Wait Until Page Contains Element    ${SIGN_IN_BUTTON}
    Page Should Contain    Sign in (Admin)

Admin Dashboard Should Be Visible
    Wait Until Element Contains    ${PAGE_TITLE}    Support cases
    Page Should Not Contain Element    ${SIGN_IN_BUTTON}

Login Should Be Refused
    # The login form is still showing and the dashboard never appeared.
    Sleep    0.5s    reason=give the app a moment to react to the submit
    Login Page Should Be Visible
    Page Should Not Contain Element    ${PAGE_TITLE}

Logged In User Should Be
    [Arguments]    ${name}
    Element Should Contain    css:aside    ${name}
    Element Should Contain    css:header    ${name}
