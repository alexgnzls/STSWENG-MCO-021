*** Settings ***
Resource         ../resources/common.robot
Test Setup       Open Login Page
Test Teardown    Close All Browsers

*** Keywords ***
Open Support Queue
    Log In As Valid Admin
    Wait Until Element Contains          css:header h1    Support cases    timeout=10s
    Wait Until Page Does Not Contain     Loading support tickets...        timeout=10s

*** Test Cases ***
TC-D02-01: Support administrator sees incoming support requests in the queue
    [Tags]    positive    D02
    Open Support Queue
    Element Should Contain         css:table thead    Case
    Element Should Contain         css:table thead    Resident
    Element Should Contain         css:table thead    Category
    Element Should Contain         css:table thead    Booking
    Element Should Contain         css:table thead    Assigned to
    Element Should Contain         css:table thead    Received
    ${ticket_count}=               Get Element Count    css:table tbody tr[tabindex="0"]
    Should Be True                 ${ticket_count} >= 1
    ${case_code}=                  Get Text    css:table tbody tr[tabindex="0"]:first-child td:nth-child(1)
    ${resident_name}=              Get Text    css:table tbody tr[tabindex="0"]:first-child td:nth-child(2)
    Should Not Be Empty            ${case_code}
    Should Not Be Empty            ${resident_name}
    
TC-D02-02: Clicking a support request opens the drawer and displays the complaint
    [Tags]    positive    D02
    Open Support Queue
    Click Element                    css:table tbody tr[tabindex="0"]:first-child
    Wait Until Element Is Visible    ${CASE_DRAWER}    timeout=5s
    Element Should Be Visible        xpath://aside//h3[normalize-space()="Complaint"]
    ${complaint_text}=               Get Text    xpath://aside//section[.//h3[normalize-space()="Complaint"]]//p
    Should Not Be Empty              ${complaint_text}

TC-D02-03: Pressing Enter on a focused request row opens the complaint drawer
    [Tags]    positive    D02
    Open Support Queue
    Press Keys                       css:table tbody tr[tabindex="0"]:first-child    RETURN
    Wait Until Element Is Visible    ${CASE_DRAWER}    timeout=5s
    Element Should Be Visible        xpath://aside//h3[normalize-space()="Complaint"]

TC-D02-04: Closing the case drawer returns to the incoming requests list
    [Tags]    positive    D02
    Open Support Queue
    Click Element                        css:table tbody tr[tabindex="0"]:first-child
    Wait Until Element Is Visible        ${CASE_DRAWER}    timeout=5s
    Click Button                         xpath://aside//button[@aria-label="Close case panel"]
    Wait Until Page Does Not Contain Element    ${CASE_DRAWER}    timeout=5s
    Element Should Be Visible            css:table