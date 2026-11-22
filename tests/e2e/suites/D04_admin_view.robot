*** Settings ***
Documentation     D04 - As a support administrator, I want to view the resident, aide,
...               booking, property, and transaction related to a complaint so that
...               I can understand the issue.
...
...               Tickets are loaded from Supabase. Rows are found by what the admin sees
...               (the Resident column), not by ticket ID, so the tests keep working
...               whether IDs are UUIDs or codes like CS-1042.
...               TC-D04-02 needs the seed ticket for ${TEST_RESIDENT}; it skips until the
...               database is updated to match the Vercel demo data.
Resource          ../resources/common.robot
Test Setup        Open Support Cases
Test Teardown     Close All Browsers

*** Variables ***
${DRAWER}           xpath://aside[contains(@class,"max-w-lg")]
${CLOSE_DRAWER}     xpath://button[@aria-label="Close case panel"]
# A real ticket row has 7 cells; the "Loading..." and "No cases" rows have only 1.
${TICKET_ROWS}      xpath://tbody/tr[count(td)=7]
@{LINK_LABELS}      Resident    Aide    Booking    Property    Transaction
${UUID_PATTERN}     ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-

# Seed ticket (CS-1042 in the Vercel demo). Values are checked with "contains",
# so extra details such as the unit number or amount don't break the test.
${TEST_RESIDENT}    Maria Santos
&{TEST_LINKS}       Resident=Maria Santos
...                 Aide=Ramon Dela Cruz
...                 Booking=BK-88231
...                 Property=Rise Residences
...                 Transaction=TX-55120

*** Test Cases ***
TC-D04-01: Opening a ticket shows all five linked record types
    [Tags]    positive    D04
    Open Ticket At Row    1
    Element Should Contain    ${DRAWER}    Linked records
    FOR    ${label}    IN    @{LINK_LABELS}
        Page Should Contain Element    ${DRAWER}//dt[normalize-space()="${label}"]
        ...    message=The "${label}" row is missing from Linked records
    END

TC-D04-02: Linked records show the correct resident, aide, booking, property and transaction
    [Tags]    positive    D04
    ${seeded}=    Run Keyword And Return Status
    ...    Page Should Contain Element    ${TEST_RESIDENT_ROW}
    Skip If    not ${seeded}    Seed data not loaded yet: no ticket for resident "${TEST_RESIDENT}".
    Click Element    ${TEST_RESIDENT_ROW}
    Wait Until Element Is Visible    ${DRAWER}    timeout=10s
    FOR    ${label}    ${expected}    IN    &{TEST_LINKS}
        ${actual}=    Get Linked Record    ${label}
        Should Contain    ${actual}    ${expected}    msg=${label} shows "${actual}", expected it to contain "${expected}"
    END

TC-D04-03: No ticket shows a missing or raw-ID linked record
    [Tags]    negative    D04    known-bug    robot:skip-on-failure
    [Documentation]    Opens every ticket in the list. A missing link shows as "N/A",
    ...                an empty value, or a raw UUID instead of a name.
    ...                Known bug (22 Nov 2026): the 3 current tickets show N/A for Resident
    ...                and Booking. Remove the known-bug and robot:skip-on-failure tags
    ...                after the database is updated.
    ${rows}=    Get Element Count    ${TICKET_ROWS}
    ${end}=     Evaluate    ${rows} + 1
    FOR    ${i}    IN RANGE    1    ${end}
        ${case_id}=    Open Ticket At Row    ${i}
        FOR    ${label}    IN    @{LINK_LABELS}
            ${value}=    Get Linked Record    ${label}
            Should Not Be Empty        ${value}    msg=Row ${i} (${case_id}): ${label} is empty
            Should Not Be Equal        ${value}    N/A    msg=Row ${i} (${case_id}): ${label} shows N/A
            Should Not Match Regexp    ${value}    ${UUID_PATTERN}    msg=Row ${i} (${case_id}): ${label} shows a raw ID (${value})
        END
        Close Case Drawer
    END

TC-D04-04: The complaint text is shown and the panel can be closed
    [Tags]    positive    D04
    Open Ticket At Row    1
    ${complaint}=    Get Text    ${DRAWER}//h3[normalize-space()="Complaint"]/following-sibling::p
    Should Not Be Empty    ${complaint}    msg=The complaint description is empty
    Close Case Drawer
    Page Should Not Contain Element    ${DRAWER}

TC-D04-05: A ticket can be opened with the keyboard
    [Tags]    positive    D04    accessibility
    ${case_id}=    Get Text    xpath:(//tbody/tr[count(td)=7])[1]/td[1]
    Press Keys    xpath:(//tbody/tr[count(td)=7])[1]    RETURN
    Wait Until Element Is Visible    ${DRAWER}    timeout=10s
    Element Should Contain    ${DRAWER}//h2    ${case_id}

*** Keywords ***
Open Support Cases
    Open Login Page
    Log In As Valid Admin
    Wait Until Page Contains Element    ${TICKET_ROWS}    timeout=10s
    ...    error=No support tickets loaded. Check the Supabase keys in .env.local and that tickets exist.
    Set Test Variable    ${TEST_RESIDENT_ROW}    xpath:(//tbody/tr[td[2][normalize-space()="${TEST_RESIDENT}"]])[1]

Open Ticket At Row
    [Documentation]    Clicks the ticket in the given table row (1 = first) and returns its Case ID.
    [Arguments]    ${row}
    ${case_id}=    Get Text    xpath:(//tbody/tr[count(td)=7])[${row}]/td[1]
    Click Element    xpath:(//tbody/tr[count(td)=7])[${row}]
    Wait Until Element Is Visible    ${DRAWER}    timeout=10s
    Element Should Contain    ${DRAWER}//h2    ${case_id}
    RETURN    ${case_id}

Get Linked Record
    [Arguments]    ${label}
    ${value}=    Get Text    ${DRAWER}//dt[normalize-space()="${label}"]/following-sibling::dd
    RETURN    ${value}

Close Case Drawer
    Click Button    ${CLOSE_DRAWER}
    Wait Until Page Does Not Contain Element    ${DRAWER}    timeout=5s
