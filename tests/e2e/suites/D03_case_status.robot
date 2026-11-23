*** Settings ***
Library          Collections
Resource         ../resources/common.robot
Test Setup       Open Login Page
Test Teardown    Close All Browsers

*** Variables ***
@{VALID_STATUSES}    Open    In Review    Resolved    Closed
${CASE_DRAWER}       xpath://aside[.//button[@aria-label="Close case panel"]]

*** Keywords ***
Open Support Queue
    Log In As Valid Admin
    Wait Until Element Contains          css:header h1    Support cases    timeout=10s
    Wait Until Page Does Not Contain     Loading support tickets...        timeout=10s

Select Status Tab
    [Arguments]    ${status_label}
    ${tab}=    Set Variable    xpath://div[@role="tablist"]//button[@role="tab" and normalize-space()="${status_label}"]
    Click Button                         ${tab}
    Element Attribute Value Should Be    ${tab}    aria-selected    true

Verify Filtered Tab Shows Only Status
    [Arguments]    ${expected_status}
    Select Status Tab    ${expected_status}
    ${row_count}=    Get Element Count    css:table tbody tr[tabindex="0"]
    IF    ${row_count} == 0
        ${lower_status}=    Evaluate    "${expected_status}".lower()
        Page Should Contain    No ${lower_status} cases right now.
    ELSE
        FOR    ${index}    IN RANGE    1    ${row_count} + 1
            ${row_status}=    Get Text    css:table tbody tr[tabindex="0"]:nth-child(${index}) td:nth-child(5)
            Should Be Equal As Strings    ${row_status.strip()}    ${expected_status}
        END
    END

*** Test Cases ***
TC-D03-01: Every support case displays a valid lifecycle status in the queue
    [Tags]    positive    D03
    Open Support Queue
    Element Should Contain    css:table thead    Status
    ${row_count}=    Get Element Count    css:table tbody tr[tabindex="0"]
    Should Be True   ${row_count} >= 1
    FOR    ${index}    IN RANGE    1    ${row_count} + 1
        ${status}=    Get Text    css:table tbody tr[tabindex="0"]:nth-child(${index}) td:nth-child(5)
        List Should Contain Value    ${VALID_STATUSES}    ${status.strip()}
    END

TC-D03-02: Unresolved status tabs isolate Open and In Review cases
    [Tags]    positive    D03
    Open Support Queue
    Verify Filtered Tab Shows Only Status    Open
    Verify Filtered Tab Shows Only Status    In Review

TC-D03-03: Completed status tabs isolate Resolved and Closed cases
    [Tags]    positive    D03
    Open Support Queue
    Verify Filtered Tab Shows Only Status    Resolved
    Verify Filtered Tab Shows Only Status    Closed

TC-D03-04: Opening a case shows its matching status badge in the drawer header
    [Tags]    positive    D03
    Open Support Queue
    ${table_status}=    Get Text    css:table tbody tr[tabindex="0"]:first-child td:nth-child(5)
    Click Element       css:table tbody tr[tabindex="0"]:first-child
    Wait Until Element Is Visible     ${CASE_DRAWER}    timeout=5s
    Element Should Contain            ${CASE_DRAWER}//header    ${table_status.strip()}

TC-D03-05: Starting review transitions an Open case to In Review
    [Tags]    positive    D03    mutates-data
    Open Support Queue
    Select Status Tab    Open
    ${open_count}=       Get Element Count    css:table tbody tr[tabindex="0"]
    Skip If              ${open_count} == 0   No Open cases available in test database to transition.
    ${case_code}=        Get Text    css:table tbody tr[tabindex="0"]:first-child td:nth-child(1)
    Click Element        css:table tbody tr[tabindex="0"]:first-child
    Wait Until Element Is Visible     ${CASE_DRAWER}    timeout=5s
    Element Should Contain            ${CASE_DRAWER}//header    Open
    Click Button                      xpath://aside//footer//button[normalize-space()="Start review"]
    Wait Until Element Contains       ${CASE_DRAWER}//header    In Review    timeout=10s
    Click Button                      xpath://aside//button[@aria-label="Close case panel"]
    Wait Until Page Does Not Contain Element    ${CASE_DRAWER}    timeout=5s
    Select Status Tab                 In Review
    Page Should Contain               ${case_code.strip()}

TC-D03-06: Top status counters match the filtered row counts for each status
    [Tags]    positive    D03
    Open Support Queue
    FOR    ${status}    IN    @{VALID_STATUSES}
        ${counter_text}=    Get Text    xpath://p[normalize-space()="${status}"]/following-sibling::p[1]
        ${expected_count}=  Convert To Integer    ${counter_text.strip()}
        Select Status Tab   ${status}
        ${actual_rows}=     Get Element Count    css:table tbody tr[tabindex="0"]
        Should Be Equal As Integers    ${actual_rows}    ${expected_count}
    END