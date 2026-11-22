*** Settings ***
Resource          ../resources/common.robot
Test Setup        Open Login Page And Sign In
Test Teardown     Close All Browsers
Test Tags         D07

*** Variables ***
${DRAWER}        css:aside:has(button[aria-label="Close case panel"])
${RESOLUTION}    css:aside textarea[placeholder="Describe how the issue was resolved"]
${ASSIGNEE}      xpath://aside//header//span[contains(normalize-space(), ', assigned to')]/following-sibling::button

*** Test Cases ***
TC-D07-01 Starting Review Assigns An Unassigned Case To The Admin
    [Tags]    positive
    ${id}=    Set Variable    %{D07_UNASSIGNED_CASE_ID=}
    Open QA Case    ${id}    Open
    Element Should Contain    ${ASSIGNEE}    Unassigned
    Click Button    xpath://aside//footer/button[normalize-space()="Start review"]
    Wait Until Case Status Is    In Review
    Wait Until Element Contains    ${ASSIGNEE}    ${VALID_DISPLAY_NAME}    timeout=15s
    Reload Page
    Open QA Case    ${id}    In Review
    Element Should Contain    ${ASSIGNEE}    ${VALID_DISPLAY_NAME}

TC-D07-02 A Case Cannot Be Resolved Without A Resolution
    [Tags]    negative
    Open QA Case    %{D07_IN_REVIEW_CASE_ID=}    In Review
    ${button}=    Set Variable    xpath://aside//footer/button[normalize-space()="Resolve case"]
    Element Attribute Value Should Be    ${RESOLUTION}    value    ${EMPTY}
    Element Should Be Disabled    ${button}
    Input Text    ${RESOLUTION}    ${SPACE}${SPACE}${SPACE}
    Element Should Be Disabled    ${button}
    Input Text    ${RESOLUTION}    QA validation text
    Element Should Be Enabled    ${button}

TC-D07-03 A Case Can Be Resolved And Closed With A Documented Resolution
    [Tags]    positive
    ${id}=    Set Variable    %{D07_LIFECYCLE_CASE_ID=}
    Should Not Be Equal    ${id}    %{D07_UNASSIGNED_CASE_ID=}    msg=Use separate tickets for TC-D07-01 and TC-D07-03.
    ${text}=    Set Variable    QA D07 resolution recorded after verifying the complaint.
    Open QA Case    ${id}    Open
    Click Button    xpath://aside//footer/button[normalize-space()="Start review"]
    Wait Until Case Status Is    In Review
    Input Text    ${RESOLUTION}    ${text}
    Click Button    xpath://aside//footer/button[normalize-space()="Resolve case"]
    Wait Until Case Status Is    Resolved
    Element Should Be Disabled    ${RESOLUTION}
    Element Attribute Value Should Be    ${RESOLUTION}    value    ${text}
    Click Button    xpath://aside//footer/button[normalize-space()="Close case"]
    Wait Until Case Status Is    Closed
    Reload Page
    Open QA Case    ${id}    Closed
    Element Attribute Value Should Be    ${RESOLUTION}    value    ${text}
    Element Should Contain    ${DRAWER}    This case is closed and kept in the support history.

TC-D07-04 A Closed Case Has No Editing Actions
    [Tags]    negative
    Open QA Case    %{D07_CLOSED_CASE_ID=}    Closed
    Element Should Be Disabled    ${ASSIGNEE}
    Element Should Be Disabled    ${RESOLUTION}
    Page Should Not Contain Element    css:aside input[placeholder="Add a note or response"]
    FOR    ${action}    IN    Start review    Resolve case    Close case    Add note
        Page Should Not Contain Element    xpath://aside//button[normalize-space()="${action}"]
    END
    Element Should Contain    ${DRAWER}    This case is closed and kept in the support history.

*** Keywords ***
Open Login Page And Sign In
    Open Login Page
    Log In As Valid Admin

Open QA Case
    [Arguments]    ${id}    ${status}
    Should Match Regexp    ${id}    ^([0-9a-fA-F]{8}|TKT-[0-9]+-[0-9]{8})$    msg=Set the case environment variable to a unique displayed QA case ID.
    ${row}=    Set Variable    xpath://tbody/tr[td[1][normalize-space()="${id}"]]
    Wait Until Element Is Visible    ${row}    timeout=15s
    Page Should Contain Element    ${row}    limit=1
    Click Element    ${row}
    Wait Until Element Is Visible    ${DRAWER}    timeout=10s
    Wait Until Case Status Is    ${status}

Wait Until Case Status Is
    [Arguments]    ${status}
    Wait Until Element Is Visible    xpath://aside//header//h2/following-sibling::*[normalize-space()="${status}"]    timeout=15s
