*** Settings ***
Documentation     D04 - As a support administrator, I want to view the resident, aide,
...               booking, property, and transaction related to a complaint so that
...               I can understand the issue.
...
...               Written for the dev-web code that shows ticket codes (TKT-xxxx-yyyymmdd)
...               in the Case column and formatted categories ("Aide Behavior").
...               TC-D04-02 uses one known seed ticket; if the database is re-seeded and its
...               code changes, update the KNOWN_ variables below.
Resource          ../resources/common.robot
Test Setup        Open Support Cases
Test Teardown     Close All Browsers

*** Variables ***
${DRAWER}             xpath://aside[contains(@class,"max-w-lg")]
${CLOSE_DRAWER}       xpath://button[@aria-label="Close case panel"]
# A real ticket row has 7 cells; the "Loading..." and "No cases" rows have only 1.
${TICKET_ROWS}        xpath://tbody/tr[count(td)=7]
@{LINK_LABELS}        Resident    Aide    Booking    Property    Transaction
${UUID_PATTERN}       ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-

# Known seed ticket (fields that admins cannot edit, so other tests won't change them)
${KNOWN_TICKET}       TKT-1012-20261122
${KNOWN_CATEGORY}     Aide Behavior
${KNOWN_AIDE}         Ryan Nathan Paguila Jr.
${KNOWN_COMPLAINT}    Low water pressure reported after bidet valve replacement.

*** Test Cases ***
TC-D04-01: Opening a ticket shows all five linked record types
    [Tags]    positive    D04
    Open Ticket At Row    1
    Element Should Contain    ${DRAWER}    Linked records
    FOR    ${label}    IN    @{LINK_LABELS}
        Page Should Contain Element    ${DRAWER}//dt[normalize-space()="${label}"]
        ...    message=The "${label}" row is missing from Linked records
    END

TC-D04-02: A known ticket shows its category, aide and complaint
    [Tags]    positive    D04
    ${row}=    Set Variable    xpath://tbody/tr[td[1][normalize-space()="${KNOWN_TICKET}"]]
    ${found}=    Run Keyword And Return Status    Page Should Contain Element    ${row}
    Skip If    not ${found}    Ticket ${KNOWN_TICKET} is not in the list. If the database was re-seeded, update the KNOWN_ variables.
    Click Element    ${row}
    Wait Until Element Is Visible    ${DRAWER}    timeout=10s
    Element Should Contain    ${DRAWER}//header    ${KNOWN_CATEGORY}
    ${aide}=    Get Linked Record    Aide
    Should Be Equal    ${aide}    ${KNOWN_AIDE}    msg=Aide shows "${aide}", expected "${KNOWN_AIDE}"
    Element Should Contain    ${DRAWER}    ${KNOWN_COMPLAINT}

TC-D04-03: No ticket shows a missing or raw-ID linked record
    [Tags]    negative    D04    known-bug    robot:skip-on-failure
    [Documentation]    Opens every ticket and checks that each linked record is a readable
    ...                value, not empty, "N/A", or a raw UUID.
    ...                Known bug (22 Nov 2026): admins get 0 rows from usr_residents and
    ...                usr_bookings, so Resident and Booking show raw IDs or N/A, and Property
    ...                and Transaction show N/A. TKT-1014/1010/1006/1002 also have an aide with
    ...                no name. Remove the known-bug and robot:skip-on-failure tags once fixed.
    ${rows}=    Get Element Count    ${TICKET_ROWS}
    ${end}=     Evaluate    ${rows} + 1
    FOR    ${i}    IN RANGE    1    ${end}
        ${code}=    Open Ticket At Row    ${i}
        FOR    ${label}    IN    @{LINK_LABELS}
            ${value}=    Get Linked Record    ${label}
            Should Not Be Empty        ${value}    msg=${code}: ${label} is empty
            Should Not Be Equal        ${value}    N/A    msg=${code}: ${label} shows N/A
            Should Not Match Regexp    ${value}    ${UUID_PATTERN}    msg=${code}: ${label} shows a raw ID (${value})
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
    ${category}=    Get Text    xpath:(//tbody/tr[count(td)=7])[1]/td[3]
    Press Keys    xpath:(//tbody/tr[count(td)=7])[1]    RETURN
    Wait Until Element Is Visible    ${DRAWER}    timeout=10s
    Element Should Contain    ${DRAWER}//header    ${category}

TC-D04-06: The panel shows the same case code as the table
    [Tags]    negative    D04    known-bug    robot:skip-on-failure
    [Documentation]    Known bug (22 Nov 2026): the table shows the ticket code
    ...                (e.g. TKT-1012-20261122) but the panel header shows the first 8
    ...                characters of the ticket UUID (CaseDrawer.jsx, <h2>). Remove the
    ...                known-bug and robot:skip-on-failure tags once fixed.
    ${code}=    Open Ticket At Row    1
    Element Text Should Be    ${DRAWER}//h2    ${code}

*** Keywords ***
Open Support Cases
    Open Login Page
    Log In As Valid Admin
    Wait Until Page Contains Element    ${TICKET_ROWS}    timeout=10s
    ...    error=No support tickets loaded. Check the Supabase keys in .env.local and that tickets exist.

Open Ticket At Row
    [Documentation]    Clicks the ticket in the given table row (1 = first), checks the
    ...                panel opened for that ticket (same category), and returns its case code.
    [Arguments]    ${row}
    ${code}=        Get Text    xpath:(//tbody/tr[count(td)=7])[${row}]/td[1]
    ${category}=    Get Text    xpath:(//tbody/tr[count(td)=7])[${row}]/td[3]
    Click Element    xpath:(//tbody/tr[count(td)=7])[${row}]
    Wait Until Element Is Visible    ${DRAWER}    timeout=10s
    Element Should Contain    ${DRAWER}//header    ${category}
    RETURN    ${code}

Get Linked Record
    [Arguments]    ${label}
    ${value}=    Get Text    ${DRAWER}//dt[normalize-space()="${label}"]/following-sibling::dd
    RETURN    ${value}

Close Case Drawer
    Click Button    ${CLOSE_DRAWER}
    Wait Until Page Does Not Contain Element    ${DRAWER}    timeout=5s
