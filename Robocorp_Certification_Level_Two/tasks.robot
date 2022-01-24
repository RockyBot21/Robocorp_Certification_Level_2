*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           Collections
Library           RPA.Dialogs
Library           RPA.FileSystem
Library           RPA.Robocorp.Vault

# +
*** Variables ***
 #output dir
${url}            https://robotsparebinindustries.com/#/robot-order

${img_folder}     ${CURDIR}${/}image_files
${pdf_folder}     ${CURDIR}${/}pdf_files
${output_folder}  ${CURDIR}${/}output

${orders_file}    ${CURDIR}${/}orders.csv
${zip_file}       ${output_folder}${/}pdf_archive.zip
${csv_url}        https://robotsparebinindustries.com/orders.csv
# -

*** Test Cases ***
Order robots from RobotSpareBin Industries Inc
    Directories created
    Directory Cleanup
    
    Get The Program Author Name From Our Vault
    ${username}=    Get The User Name
    
    Open the robot order website

    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form           ${row}
        Wait Until Keyword Succeeds     10x     2s    Preview the robot
        Wait Until Keyword Succeeds     10x     2s    Submit The Order
        ${orderid}  ${img_filename}=    Take a screenshot of the robot
        ${pdf_filename}=                Store the receipt as a PDF file    ORDER_NUMBER=${order_id}
        Embed the robot screenshot to the receipt PDF file     IMG_FILE=${img_filename}    PDF_FILE=${pdf_filename}
        Go to order another robot
    END
    Create a ZIP file of the receipts

    Log Out And Close The Browser
    Display the success dialog    USER_NAME=${username}

*** Keywords ****
Directories created
 #Create directories for each ouput 
    Create Directory    ${output_folder}
    Create Directory    ${img_folder}
    Create Directory    ${pdf_folder}

*** Keywords ***
Directory Cleanup
    Log To console      Clear the content for each directory
    #Clear the content for each directory 
    Empty Directory     ${img_folder}
    Empty Directory     ${pdf_folder}
    Empty Directory     ${output_folder}

*** Keywords ***
Get The User Name
 #User name to execute the activities
    Add heading             I am a Robot
    Add text input          myname    label=What is your name?     placeholder=Give me some input here
    ${result}=              Run dialog
    [Return]                ${result.myname}

*** Keywords ***
Get The Program Author Name From Our Vault
 #Get info from config file
    Log To Console          Getting Secret from local Vault
    ${secret}=              Get Secret    mysecrets
    Log                     ${secret}[whowrotethis] wrote this program for you      console=yes

*** Keywords ***
Open the robot order website
    Open Available Browser    ${url}
    Maximize Browser Window

*** Keywords ***
Get orders
 #Download file of excel from the platform
    Download    url=${csv_url}         target_file=${orders_file}    overwrite=True
    ${table}=   Read table from CSV    path=${orders_file}
    [Return]    ${table}

*** Keywords ***
Close the annoying modal
    # Define local variables for the UI elements
    Set Local Variable              ${btn_yep}        //*[@id="root"]/div/div[2]/div/div/div/div/div/button[2]
    Wait And Click Button           ${btn_yep}

*** Keywords ***
Fill the form
    [Arguments]     ${myrow}
    Set Local Variable    ${order_no}   ${myrow}[Order number]
    Set Local Variable    ${head}       ${myrow}[Head]
    Set Local Variable    ${body}       ${myrow}[Body]
    Set Local Variable    ${legs}       ${myrow}[Legs]
    Set Local Variable    ${address}    ${myrow}[Address]
    # Extract info from excel file and store it
    Set Local Variable      ${input_head}       //*[@id="head"]
    Set Local Variable      ${input_body}       body
    Set Local Variable      ${input_legs}       xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input
    Set Local Variable      ${input_address}    //*[@id="address"]
    Set Local Variable      ${btn_preview}      //*[@id="preview"]
    Set Local Variable      ${btn_order}        //*[@id="order"]
    Set Local Variable      ${img_preview}      //*[@id="robot-preview-image"]

    Wait Until Element Is Visible   ${input_head}
    Wait Until Element Is Enabled   ${input_head}
    Select From List By Value       ${input_head}           ${head}

    Wait Until Element Is Enabled   ${input_body}
    Select Radio Button             ${input_body}           ${body}

    Wait Until Element Is Enabled   ${input_legs}
    Input Text                      ${input_legs}           ${legs}
    Wait Until Element Is Enabled   ${input_address}
    Input Text                      ${input_address}        ${address}

*** Keywords ***
Preview the robot
    # Define local variables for the UI elements
    Set Local Variable              ${btn_preview}      //*[@id="preview"]
    Set Local Variable              ${img_preview}      //*[@id="robot-preview-image"]
    Click Button                    ${btn_preview}
    Wait Until Element Is Visible   ${img_preview}

*** Keyword ***
Submit the order
    # Aprove orders
    Set Local Variable              ${btn_order}        //*[@id="order"]
    Set Local Variable              ${lbl_receipt}      //*[@id="receipt"]

    #Do not generate screenshots if robot not works
    Mute Run On Failure             Page Should Contain Element 

    # Aprove the order if directory is not empty
    Click button                    ${btn_order}
    Page Should Contain Element     ${lbl_receipt}

*** Keyword ***
Take a screenshot of the robot
    # Store image for each robot
    Set Local Variable      ${lbl_orderid}      xpath://html/body/div/div/div[1]/div/div[1]/div/div/p[1]
    Set Local Variable      ${img_robot}        //*[@id="robot-preview-image"]

    #Get image until that appear
    Wait Until Element Is Visible   ${img_robot}
    Wait Until Element Is Visible   ${lbl_orderid}
    #get the order ID   
    ${orderid}=                     Get Text            //*[@id="receipt"]/p[1]

    # Create the image file by name
    Set Local Variable              ${fully_qualified_img_filename}    ${img_folder}${/}${orderid}.png

    #Take an screenshot
    Sleep   1sec
    Log To Console                  Capturing Screenshot to ${fully_qualified_img_filename}
    Capture Element Screenshot      ${img_robot}    ${fully_qualified_img_filename}
    
    [Return]    ${orderid}  ${fully_qualified_img_filename}


*** keyword ***
Go to order another robot
    # Orders of the robot
    Set Local Variable      ${btn_order_another_robot}      //*[@id="order-another"]
    Click Button            ${btn_order_another_robot}

*** keyword ***
Log Out And Close The Browser
    #Close current browser
    Close Browser

*** keyword ***
Create a Zip File of the Receipts
    #Create a zip file for each image downloaded
    Archive Folder With ZIP     ${pdf_folder}  ${zip_file}   recursive=True  include=*.pdf

*** Keyword ***
Store the receipt as a PDF file
    #Get orders
    [Arguments]        ${ORDER_NUMBER}

    Wait Until Element Is Visible   //*[@id="receipt"]
    Log To Console                  Printing ${ORDER_NUMBER}
    ${order_receipt_html}=          Get Element Attribute   //*[@id="receipt"]  outerHTML

    Set Local Variable              ${fully_qualified_pdf_filename}    ${pdf_folder}${/}${ORDER_NUMBER}.pdf

    Html To Pdf                     content=${order_receipt_html}   output_path=${fully_qualified_pdf_filename}

    [Return]    ${fully_qualified_pdf_filename}

*** Keyword ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]     ${IMG_FILE}     ${PDF_FILE}

    Log To Console                  Printing Embedding image ${IMG_FILE} in pdf file ${PDF_FILE}

    Open PDF        ${PDF_FILE}

    # Create a PDF file
    @{myfiles}=       Create List     ${IMG_FILE}:x=0,y=0

    # Add the files to the PDF }6 close all of them
    Add Files To PDF    ${myfiles}    ${PDF_FILE}     ${True}
    Close PDF           ${PDF_FILE}

*** Keyword ***
Display the success dialog
    [Arguments]   ${USER_NAME}
    Add icon      Success
    Add heading   Your orders have been processed
    Add text      User ${USER_NAME} - all orders have been processed. Good day!
    Run dialog    title=Success




