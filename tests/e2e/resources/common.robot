*** Settings ***
Documentation     Shared variables and keywords for all end-to-end suites.
Library           SeleniumLibrary

*** Variables ***
${BASE_URL}       http://localhost:5173
${BROWSER}        headlesschrome
${TIMEOUT}        10s

*** Keywords ***
Open Admin Browser
    Open Browser    ${BASE_URL}    ${BROWSER}
    Set Selenium Timeout    ${TIMEOUT}
