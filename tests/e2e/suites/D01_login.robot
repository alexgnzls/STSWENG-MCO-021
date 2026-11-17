*** Settings ***
Documentation   D01 - Secure admin login.
Resource        ../resources/common.robot
Test Setup      Open Admin Browser
Test Teardown   Close All Browsers  
Force Tags      D01    login    must

*** Test Cases ***
TC-D01-01 Valid Support Admin Can log In
    Skip    Not implemented yet

TC-D01-02 Valid Disbursement Admin Can Log In
    Skip    Not implemented yet

TC-D01-03 Wrong Password Is Rejected
    Skip    Not implemented yet

TC-D01-04 Empty Credentials Are Rejected
    Skip    Not implemented yet

TC-D01-05 Protected Page Redirects When Logged Out
    Skip    Not implemented yet

TC-D01-06 Logout Ends The Session
    Skip    Not implemented yet
