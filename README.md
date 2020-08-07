# Get-TeamsPSTNCallRecords
Retrieve Microsoft Teams PSTN call records for Calling Plan and Direct Routing users

![](https://www.lee-ford.co.uk/images/get-teamspstncallrecords/get-teamspstncallrecords.png)

_**Disclaimer:** This script is provided ‘as-is’ without any warranty or support. The Graph API endpoints in this script are marked as Beta by Microsoft. Use of this script is at your own risk and I accept no responsibility for any damage caused._

## Background ##
Within the **Teams Admin Centre** there is a PSTN usage report allowing you to report on PSTN calls for Calling Plan and Direct Routing users:

![](https://www.lee-ford.co.uk/images/get-teamspstncallrecords/pstnusagereport.png)

These reports can be a great source of information and one great feature is the ability to export the data to an Excel file. However, there is no way to automate this...

## Introducing Get-TeamsPSTNCallRecords ##

With [recently released Graph API endpoints](https://docs.microsoft.com/en-us/graph/api/callrecords-callrecord-getpstncalls?view=graph-rest-beta), it is now possible to obtain this information programatically.

This tool will allow you to obtain PSTN call records for a set amount of days and export to either JSON or CSV file format. In addition as this is not using user/delegated permissions, it is possible to run as park of a scheduled task/Azure Runbook.

> Note: Currently Microsoft only stores the last 365 days of PSTN call records

## Prerequisites ##

Before you can use the tool, you will need to create an Azure AD application with the relevant Graph API permissions:

1. Login to [Azure portal](https://portal.azure.com)
2. Go to **Azure Active Directory > App registrations** and select **New registration**
![](https://www.lee-ford.co.uk/images/get-teamspstncallrecords/prereq1.png)
3. Give the app an arbitrary **Name** and leave the rest as-is and click **Register**
![](https://www.lee-ford.co.uk/images/get-teamspstncallrecords/prereq2.png)
4. Take a copy of the **Application ID** and **Directory ID** from the **Overview** page
![](https://www.lee-ford.co.uk/images/get-teamspstncallrecords/prereq3.png)
5. Go to **Certificates and secrets** and create a **New client secret**. Again, take a copy of this
![](https://www.lee-ford.co.uk/images/get-teamspstncallrecords/prereq5.png)
6. Next, go to **API permissions** and **Add a permission**. Select **Microsoft Graph** and choose **Application permissions**. Search for CallRecords.Read.All and select **Add permissions**
![](https://www.lee-ford.co.uk/images/get-teamspstncallrecords/prereq6.png)
7. Finally, you need to **Grant admin consent for (tenant name)**
![](https://www.lee-ford.co.uk/images/get-teamspstncallrecords/prereq7.png)

> Note: For now, you need to use the CallRecords.Read.All Graph API permission - Microsoft are currently working on adding a more specific **CallRecords.Read.PstnCalls** permission, but this was not avaiable as of August 2020 - if that is available in your tenant, use that

With the **Application ID**, **Directory ID** and **Secret** to hand, place these in the relevant variables in the .ps1 script:
![](https://www.lee-ford.co.uk/images/get-teamspstncallrecords/prereq8.png)

## Usage ##

> I have tested this on PowerShell Core 7 - it may work with Windows PowerShell 5.1, but I have not tried!

Retreive call records for the last 10 days and save as JSON files:
```
.\Get-TeamsPSTNCallRecords.ps1 -SavePath C:\Temp -Days 10 -SaveFormat JSON
```

Retreive call records for the last 50 days and save as CSV files:
```
.\Get-TeamsPSTNCallRecords.ps1 -SavePath C:\Temp -Days 50 -SaveFormat CSV
```
