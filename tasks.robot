*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Desktop.Windows
Library             RPA.Archive
Library             RPA.FileSystem
Library             RPA.Dialogs
Library             Dialogs
Library             RPA.Robocorp.Vault


*** Variables ***
${TMP_OUTPUT}       ${OUTPUT_DIR}${/}output_tmp


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    #${input} =    Get Value From User    Please enter the URL to the Excel file
    ${RSBI_URL} =    Get URL from the Vault
    ${input} =    Prompt for input (dialog)
    ${orders} =    Get Orders    ${input}
    Create Directory    ${TMP_OUTPUT}
    Open the robot order website    ${RSBI_URL}
    FOR    ${order}    IN    @{orders}
        Close the popup
        Fill the from    ${order}
        Preview the robot
        Wait Until Keyword Succeeds    5x    0.1 sec    Submit the order
        ${pdf} =    Store receipt as a PDF    ${order}[Order number]
        ${screenshot} =    Take a screenshot of the robot    ${order}[Order number]
        Add screenshot to PDF    ${screenshot}    ${pdf}
        GO to next order?
    END
    Create ZIP file of all receipts
    [Teardown]    Close Browser


*** Keywords ***
Get URL from the Vault
    ${secret} =    Get Secret    RSBI
    RETURN    ${secret}[URL]

Open the robot order website
    [Arguments]    ${RSBI_URL}
    Open Available Browser    url=${RSBI_URL}    maximized=True
    Wait Until Page Contains Element    class:btn-danger

Get Orders
    [Arguments]    ${input}
    Download    url=${input}    overwrite=True    #https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${orders} =    Read table from CSV    orders.csv
    RETURN    ${orders}

Close the popup
    Click Button    class:btn-danger

Fill the from
    [Arguments]    ${order}
    Select From List By Index    id:head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    #Input Text    css:input[placeholder='Enter the part number for the legs']    ${Order}[Legs]
    Input Text    //*[@class="form-group"]/input    ${order}[Body]
    Input Text    address    ${order}[Address]

Preview the robot
    Click Button    preview

Submit the order
    Click Button    order
    Wait Until Page Contains Element    receipt    2.5 sec

Store receipt as a PDF
    [Arguments]    ${Order number}
    ${Receipt HTML} =    Get Element Attribute    receipt    outerHTML
    ${pdf path} =    Set Variable    ${TMP_OUTPUT}${/}receipt${Order number}.pdf
    Html To Pdf    ${Receipt HTML}    ${pdf path}
    RETURN    ${pdf path}

Take a screenshot of the robot
    [Arguments]    ${Order number}
    ${screenshot} =    Set Variable    ${TMP_OUTPUT}${/}screenshot${Order number}.png
    Capture Element Screenshot    //*[@id="robot-preview-image"]    ${screenshot}
    RETURN    ${screenshot}

Add screenshot to PDF
    [Arguments]    ${screenshot}    ${pdf}
    #${openedPDF} =    Open Pdf    ${pdf}
    ${files} =    Create List    ${screenshot}
    Add Files To Pdf    ${files}    ${pdf}    append=True
    #Save Pdf    ${pdf}    reader

GO to next order?
    Click Button    order-another

Create ZIP file of all receipts
    ${zip_file_name} =    Set Variable    ${OUTPUT_DIR}${/}Receipts.zip
    Archive Folder With Zip    ${TMP_OUTPUT}    ${zip_file_name}
    Remove Directory    ${TMP_OUTPUT}    recirsive=true

Prompt for input (dialog)
    Add heading    Provide the URL to the text file
    Add text input    ExcelFileName
    ...    label=URL
    ...    placeholder=https://robotsparebinindustries.com/orders.csv
    ${result} =    Run dialog
    ${length} =    Get Length    ${result.ExcelFileName}
    IF    ${length} == 0
        ${result.ExcelFileName} =    Set Variable    https://robotsparebinindustries.com/orders.csv
    END
    RETURN    ${result.ExcelFileName}
