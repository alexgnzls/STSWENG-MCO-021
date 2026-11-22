*** Settings ***
Resource          ../resources/common.robot
Library           Collections
Library           String
Test Setup        Open Assigned QA Complaint
Test Teardown     Close All Browsers
Test Tags         D06

*** Variables ***
${CASE_ID}          %{D06_CASE_ID=}
${START_ASSIGNEE}   %{D06_START_ASSIGNEE=}
${TARGET_ASSIGNEE}  %{D06_TARGET_ASSIGNEE=}
${ASSIGNEE}         xpath://aside//header//span[contains(normalize-space(), ', assigned to')]/following-sibling::button
${SEARCH}           css:aside input[placeholder="Type employee name..."]
${OPTIONS}          xpath://aside//header//ul/li/button/span[1]
${NO_MATCH}         xpath://aside//header//ul/li[normalize-space()="No matching employee found."]

*** Test Cases ***
TC-D06-01 Assign A Complaint To Another Staff Member
    [Tags]    positive
    Should Not Be Empty    ${TARGET_ASSIGNEE}    Set D06_TARGET_ASSIGNEE to the other QA employee's display name.
    Should Not Be Equal    ${TARGET_ASSIGNEE}    ${START_ASSIGNEE}    ignore_case=True
    Open Employee Picker
    Wait Until Keyword Succeeds    15s    500ms    Find Employee Option    ${START_ASSIGNEE}
    ${target}=    Search For Employee    ${TARGET_ASSIGNEE}
    TRY
        Click Element    ${target}
        Wait Until Element Is Not Visible    ${SEARCH}    timeout=15s
        Assignee Should Be    ${TARGET_ASSIGNEE}
        Reload Page
        Open QA Complaint
        Assignee Should Be    ${TARGET_ASSIGNEE}
    FINALLY
        Restore Starting Assignee
    END

TC-D06-02 Unknown Employee Search Leaves Assignee Unchanged
    [Tags]    negative
    Open Employee Picker
    Wait Until Keyword Succeeds    15s    500ms    Find Employee Option    ${START_ASSIGNEE}
    ${suffix}=    Generate Random String    16    [LOWER][NUMBERS]
    Input Text    ${SEARCH}    QA nonexistent employee ${suffix}
    Wait Until Element Is Visible    ${NO_MATCH}    timeout=10s
    Page Should Not Contain Element    ${OPTIONS}
    Click Element    ${ASSIGNEE}
    Wait Until Element Is Not Visible    ${SEARCH}    timeout=10s
    Assignee Should Be    ${START_ASSIGNEE}

*** Keywords ***
Open Assigned QA Complaint
    Should Match Regexp    ${CASE_ID}    ^[0-9a-fA-F]{8}$    msg=Set D06_CASE_ID to the unique eight-character QA Case value.
    Should Not Be Empty    ${START_ASSIGNEE}    Set D06_START_ASSIGNEE to the starting QA employee's display name.
    Open Login Page
    Log In As Valid Admin
    Open QA Complaint
    Assignee Should Be    ${START_ASSIGNEE}

Open QA Complaint
    ${row}=    Set Variable    xpath://tbody/tr[td[1][normalize-space()="${CASE_ID}"]]
    Wait Until Element Is Visible    ${row}    timeout=15s
    Page Should Contain Element    ${row}    limit=1
    Click Element    ${row}
    Wait Until Element Is Visible    ${ASSIGNEE}    timeout=10s

Assignee Should Be
    [Arguments]    ${expected}
    ${label}=    Get Text    ${ASSIGNEE}
    ${name}=    Remove String    ${label}    ▾
    ${name}=    Strip String    ${name}
    Should Be Equal As Strings    ${name}    ${expected}

Open Employee Picker
    Wait Until Element Is Enabled    ${ASSIGNEE}    timeout=10s
    Click Element    ${ASSIGNEE}
    Wait Until Element Is Visible    ${SEARCH}    timeout=10s

Search For Employee
    [Arguments]    ${name}
    Input Text    ${SEARCH}    ${name}
    ${option}=    Wait Until Keyword Succeeds    15s    500ms    Find Employee Option    ${name}
    RETURN    ${option}

Find Employee Option
    [Arguments]    ${name}
    @{options}=    Get WebElements    ${OPTIONS}
    ${matches}=    Create List
    FOR    ${option}    IN    @{options}
        ${label}=    Get Text    ${option}
        IF    $label == $name
            Append To List    ${matches}    ${option}
        END
    END
    Length Should Be    ${matches}    1    Expected exactly one assignment option for ${name}.
    RETURN    ${matches}[0]

Restore Starting Assignee
    Reload Page
    Open QA Complaint
    ${already_restored}=    Run Keyword And Return Status    Assignee Should Be    ${START_ASSIGNEE}
    IF    not $already_restored
        Assignee Should Be    ${TARGET_ASSIGNEE}
        Open Employee Picker
        ${original}=    Search For Employee    ${START_ASSIGNEE}
        Click Element    ${original}
        Wait Until Element Is Not Visible    ${SEARCH}    timeout=15s
        Reload Page
        Open QA Complaint
        Assignee Should Be    ${START_ASSIGNEE}
    END
