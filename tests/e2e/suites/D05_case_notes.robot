*** Settings ***
Resource         ../resources/common.robot
Library          String
Test Setup       Open Editable QA Case
Test Teardown    Close All Browsers
Test Tags        D05

*** Variables ***
${CASE_ID}      %{D05_CASE_ID=}
${NOTE_BOX}     css:aside input[placeholder="Add a note or response"]
${ADD_NOTE}     xpath://aside//button[normalize-space()="Add note"]

*** Test Cases ***
TC-D05-01 Adding A Note Records It In Case History
    [Tags]    positive
    ${suffix}=    Generate Random String    12    [LOWER][NUMBERS]
    ${note}=    Set Variable    QA D05 follow-up ${suffix}
    ${entry}=    Set Variable    //aside//li[p[normalize-space()="${note}"]]
    Input Text    ${NOTE_BOX}    ${note}
    Click Button    ${ADD_NOTE}
    Wait Until Element Is Visible    xpath:${entry}    timeout=15s
    Textfield Value Should Be    ${NOTE_BOX}    ${EMPTY}
    Close All Browsers
    Open Editable QA Case
    Wait Until Element Is Visible    xpath:${entry}    timeout=15s
    Page Should Contain Element    xpath:${entry}    limit=1
    ${metadata}=    Get Text    xpath:${entry}/p[2]
    Should Start With    ${metadata}    ${VALID_DISPLAY_NAME},
    Should Match Regexp    ${metadata}    ,.*[0-9]

TC-D05-02 Empty And Spaces-Only Notes Cannot Be Added
    [Tags]    negative
    Textfield Value Should Be    ${NOTE_BOX}    ${EMPTY}
    Element Should Be Disabled    ${ADD_NOTE}
    Input Text    ${NOTE_BOX}    ${SPACE}${SPACE}${SPACE}
    Element Should Be Disabled    ${ADD_NOTE}
    Input Text    ${NOTE_BOX}    QA validation
    Element Should Be Enabled    ${ADD_NOTE}

*** Keywords ***
Open Editable QA Case
    Should Match Regexp    ${CASE_ID}    ^(TKT-[0-9]+-[0-9]{8}|CS-[0-9]+|[0-9a-fA-F]{8})$    msg=Set D05_CASE_ID to the full editable QA ticket ID shown in the Case column.
    Open Login Page
    Log In As Valid Admin
    ${row}=    Set Variable    xpath://tbody/tr[td[1][normalize-space()="${CASE_ID}"]]
    Wait Until Element Is Visible    ${row}    timeout=15s
    Page Should Contain Element    ${row}    limit=1
    Click Element    ${row}
    Wait Until Element Is Visible    ${NOTE_BOX}    timeout=10s
