*** Settings ***
Documentation     D01 - As a support administrator, I want to log in securely
...               so that I can access support and operational tools.
...               Written cases: tests/test-cases/D01_login.md
...
...               Tests tagged `known-bug` describe the behaviour D01 requires but the
...               current fake login does not have yet. They report as SKIPPED while
...               they fail, so the suite stays green, and start passing once fixed.
Resource          ../resources/common.robot
Test Setup        Open Admin Browser
Test Teardown     Close All Browsers
Test Tags         D01    login

*** Test Cases ***
TC-D01-01 Valid Credentials Open The Dashboard
    [Tags]    must    smoke
    Log In With    ${VALID_USER}    ${VALID_PASS}
    Admin Dashboard Should Be Visible
    Logged In User Should Be    ${VALID_USER}

TC-D01-02 Password Of Exactly 6 Characters Is Accepted
    [Tags]    must    boundary
    Log In With    ${VALID_USER}    abc123
    Admin Dashboard Should Be Visible

TC-D01-03 Password Of 5 Characters Is Refused
    [Tags]    must    boundary    negative
    Log In With    ${VALID_USER}    abc12
    Login Should Be Refused

TC-D01-04 Empty Username And Password Are Refused
    [Tags]    must    negative
    Click Button    ${SIGN_IN_BUTTON}
    Login Should Be Refused

TC-D01-05 Empty Username Is Refused
    [Tags]    must    negative
    Log In With    ${EMPTY}    ${VALID_PASS}
    Login Should Be Refused

TC-D01-06 Spaces-Only Username Is Refused
    [Tags]    must    negative
    Log In With    ${SPACE}${SPACE}${SPACE}    ${VALID_PASS}
    Login Should Be Refused

TC-D01-07 Empty Password Is Refused
    [Tags]    must    negative
    Log In With    ${VALID_USER}    ${EMPTY}
    Login Should Be Refused

TC-D01-08 Username Is Trimmed Before Display
    [Tags]    should
    Log In With    ${SPACE}${SPACE}${VALID_USER}${SPACE}${SPACE}    ${VALID_PASS}
    Admin Dashboard Should Be Visible
    Element Text Should Be    xpath://aside//p[contains(@class,"text-sm")]    ${VALID_USER}

TC-D01-09 Avatar Shows Capitalised First Letter
    [Tags]    could
    Log In As Valid Admin
    ${initial}=    Evaluate    "${VALID_USER}"[0].upper()
    Element Text Should Be    xpath://header//div[contains(@class,"rounded-full")]    ${initial}

TC-D01-10 Pressing Enter Submits The Form
    [Tags]    should
    Input Text        ${USERNAME_FIELD}    ${VALID_USER}
    Input Password    ${PASSWORD_FIELD}    ${VALID_PASS}
    Press Keys        ${PASSWORD_FIELD}    RETURN
    Admin Dashboard Should Be Visible

TC-D01-11 Password Characters Are Hidden
    [Tags]    must    security
    Element Attribute Value Should Be    ${PASSWORD_FIELD}    type    password

TC-D01-12 Sidebar Sign Out Returns To Login With Empty Fields
    [Tags]    must
    Log In As Valid Admin
    Click Button    ${SIDEBAR_SIGNOUT}
    Login Page Should Be Visible
    Textfield Value Should Be    ${USERNAME_FIELD}    ${EMPTY}
    Textfield Value Should Be    ${PASSWORD_FIELD}    ${EMPTY}

TC-D01-13 Header Logout Returns To Login
    [Tags]    must
    Log In As Valid Admin
    Click Button    ${HEADER_LOGOUT}
    Login Page Should Be Visible

TC-D01-14 Reloading After Logout Stays On Login
    [Tags]    must    security
    Log In As Valid Admin
    Click Button    ${SIDEBAR_SIGNOUT}
    Reload Page
    Login Page Should Be Visible

# ---- Expected by D01, not implemented yet ---------------------------------

TC-D01-15 Wrong Password Is Refused
    [Tags]    must    negative    security    known-bug    robot:skip-on-failure
    [Documentation]    Fails now: any password with 6+ characters logs in.
    Log In With    ${VALID_USER}    ${WRONG_PASS}
    Login Should Be Refused

TC-D01-16 Unknown Username Is Refused
    [Tags]    must    negative    security    known-bug    robot:skip-on-failure
    [Documentation]    Fails now: any username is accepted.
    Log In With    nobody.here    ${VALID_PASS}
    Login Should Be Refused

TC-D01-17 Refused Login Shows An Error Message
    [Tags]    should    negative    known-bug    robot:skip-on-failure
    [Documentation]    Fails now: a refused login gives no feedback at all.
    Log In With    ${VALID_USER}    abc12
    Wait Until Page Contains Element    css:[role="alert"]    timeout=2s

TC-D01-18 Session Survives A Page Reload
    [Tags]    should    known-bug    robot:skip-on-failure
    [Documentation]    Fails now: the login is only kept in memory, so a reload logs you out.
    Log In As Valid Admin
    Reload Page
    Admin Dashboard Should Be Visible

TC-D01-19 Forgot Password Link Opens A Reset Flow
    [Tags]    could    known-bug    robot:skip-on-failure
    [Documentation]    Fails now: the link points to "#forgot" and does nothing.
    Click Link    Forgot password?
    Page Should Not Contain Element    ${SIGN_IN_BUTTON}
