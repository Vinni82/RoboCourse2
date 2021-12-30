*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library    RPA.Browser.Selenium
Library    RPA.Tables
Library    RPA.Excel.Files
Library    RPA.HTTP
Library    RPA.PDF
Library    RPA.Archive
Library    RPA.FileSystem
Library    RPA.Dialogs
Library    RPA.Robocloud.Secrets

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${user_input}=  Ask for user input
    ${orders}=  Get orders  ${user_input}
    FOR  ${row}  IN  @{orders}
        Close the annoying modal
        Fill the form  ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts

*** Keywords ***
Open the robot order website
  ${url}=  Get Secret  cre
  Open Browser  ${url}[url]  browser=gc 
  Title Should Be  RobotSpareBin Industries Inc. - Intranet

Ask for user input
    Add text input    csv_link      Provide your CSV file link
    # Insert for the course the following url: https://robotsparebinindustries.com/orders.csv
    ${csv_link}=  Run dialog
    [Return]    ${csv_link.csv_link}

Get Orders
  [Arguments]  ${user_input}
  Download  ${user_input}  target_file=${CURDIR}/orders.csv  overwrite=True  
  ${csv}=  Read table from CSV    ${CURDIR}/orders.csv  
  [Return]  ${csv}

Close the annoying modal
  Wait Until Page Contains Element  XPATH=//p[contains(.,'By using this order form, I give up all my constitutional rights for the benefit')]  timeout=20
  Click Element  XPATH=//button[text()='OK']

Fill the form
  [Arguments]  ${row}
  # Select head
  Click Element  XPATH=//select[@name='head']/option[@value='${row}[Head]']
  # Select body
  Click Element  XPATH=//label[@for='id-body-${row}[Body]']
  # Type amount of Legs
  Input Text  css=[placeholder='Enter the part number for the legs']  ${row}[Legs]
  # Type Address
  Input Text  XPATH=//input[@placeholder='Shipping address']  ${row}[Address]

Preview the robot
  Click Element  XPATH=//button[text()='Preview']   

Click order button
  Click Element  XPATH=//button[text()='Order'] 
  Wait Until Page Contains Element    XPATH=//h3[.='Receipt']  timeout=5

Submit the order
  Wait Until Keyword Succeeds  2 min  5 sec  Click order button

Store the receipt as a PDF file
   [Arguments]  ${orderNo}
   ${outerHTML}=  Get Element Attribute  css=#receipt  outerHTML
   ${path}=  Set Variable  ${OUTPUT_DIR}${/}Receipts${/}OrderNo_${orderNo}.pdf
   Html To Pdf  ${outerHTML}  ${OUTPUT_DIR}${/}Receipts${/}OrderNo_${orderNo}.pdf
   [Return]  ${path}

Take a screenshot of the robot
  [Arguments]  ${orderNo}
  ${screenshot}=  Capture Element Screenshot  XPATH=//div[@id='robot-preview-image']  ${CURDIR}${/}OrderNo_${orderNo}.png    
  [Return]  ${screenshot}

Embed the robot screenshot to the receipt PDF file
  [Arguments]  ${screenshot}  ${pdf}          
  ${pdfFile}=  Open Pdf  ${pdf}
  Add Watermark Image To Pdf  ${screenshot}  ${pdf}  #append=True
  Close pdf  ${pdfFile}
  Remove File    ${screenshot}

Go to order another robot
  Click Element  id=order-another

Create a ZIP file of the receipts
  Archive Folder With Zip  ${OUTPUT_DIR}${/}Receipts${/}  ${OUTPUT_DIR}${/}Receipts.zip
