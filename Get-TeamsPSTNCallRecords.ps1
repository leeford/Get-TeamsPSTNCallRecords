<# 
.SYNOPSIS
 
    Get-TeamsPSTNCallRecords.ps1 - Retrieve Microsoft Teams PSTN call records for Calling Plan and Direct Routing users
 
.DESCRIPTION

    Author: Lee Ford

    This tool allows you retireve PSTN call records for Calling Plan and Direct Routing users and save to a file. You can request how many days far back (from now) you wish to retrieve

.LINK

    Blog: https://www.lee-ford.co.uk
    Twitter: http://www.twitter.com/lee_ford
    LinkedIn: https://www.linkedin.com/in/lee-ford/
 
.EXAMPLE 

    .\Get-TeamsPSTNCallRecords.ps1 -SavePath C:\Temp -Days 10 -SaveFormat JSON
    Retrieve call records for the last 10 days and save as JSON files

    .\Get-TeamsPSTNCallRecords.ps1 -SavePath C:\Temp -Days 50 -SaveFormat CSV
    Retrieve call records for the last 50 days and save as CSV files

#>

param (
    [Parameter(mandatory = $true)][string]$SavePath,
    [Parameter(mandatory = $true)][int]$Days,
    [Parameter(mandatory = $true)][ValidateSet("JSON", "CSV")]$SaveFormat
)

# Client (application) ID, tenant (directory) ID and secret
$clientId = "<application id goees here>"
$tenantId = "<directory id goes here>"
$clientSecret = '<secret goes here>'

function Get-Calls {
    param (
        [Parameter(mandatory = $true)][string]$type
    )

    $remainingDays = $Days

    # Set initial to date of date range to end of today/start of tomorrow
    $toDateTime = (Get-Date).AddDays(+1)

    while ($remainingDays -gt 0) {

        $totalRecords = 0

        # If remaining days is < 89 set specifically
        if ($remainingDays -lt 89) {
            $dayBatchSize = $remainingDays
        } else {
            $dayBatchSize = 89
        }

        # New remaining days based on new batch
        $remainingDays -= $dayBatchSize

        # Set from date to be minus day batch size from now
        $fromDateTime = ($toDateTime).AddDays(-$dayBatchSize)

        # Set dates to correctly formatted strings for query
        $toDateTimeString = $toDateTime | Get-Date -Format "yyyy-MM-dd"
        $fromDateTimeString = $fromDateTime | Get-Date -Format "yyyy-MM-dd"

        $currentUri = "https://graph.microsoft.com/beta/communications/callRecords/$type(fromDateTime=$fromDateTimeString,toDateTime=$toDateTimeString)"

        Write-Host "        - Checking for call records between $fromDateTimeString and $toDateTimeString..." -NoNewline

        $content += while (-not [string]::IsNullOrEmpty($currentUri)) {

            $apiCall = Invoke-RestMethod -Method "GET" -Uri $currentUri -ContentType "application/json" -Headers @{Authorization = "Bearer $token" } -ErrorAction Stop
    
            $currentUri = $null

            if ($apiCall) {

                # Check if any data is left
                $currentUri = $apiCall.'@odata.nextLink'

                # Count total records so far
                $totalRecords += $apiCall.'@odata.count'

                $apiCall.value

            }

        }

        # Set the to date to start from the previous from date
        $toDateTime = $fromDateTime

        if ($totalRecords -gt 0) {
            Write-Host " Retrieved $totalRecords call records" -ForegroundColor Green
        } else {
            Write-Host " No records found" -ForegroundColor Yellow
        }
        
        
    }

    return $content

}

# Start
Write-Host "`n----------------------------------------------------------------------------------------------
            `n Get-TeamsPSTNCallRecords.ps1 - Lee Ford
            `n https://github.com/leeford/Get-TeamsPSTNCallRecords - https://www.lee-ford.co.uk
            `n----------------------------------------------------------------------------------------------
            `n Disclaimer: This script is provided ‘as-is’ without any warranty or support. The Graph API 
            `n endpoints in this script are marked as Beta by Microsoft. Use of this script is at your own 
            `n risk." -ForegroundColor Yellow

# Check Days is a postive number
if ($Days -lt 0) {

    Write-Host "Please specify a valid date range (greater than 0 days)" -ForegroundColor Red
    break

}

if ($Days -gt 365) {

    Write-Warning "Call records are typically only stored for 365 days"

}

# Check Save Path exists
if (-not (Test-Path -Path $SavePath)) {

    Write-Host "$SavePath does not exist, please specify a valid path" -ForegroundColor Red
    break

}

$uri = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
$body = @{
    client_id     = $clientId
    scope         = "https://graph.microsoft.com/.default"
    client_secret = $clientSecret
    grant_type    = "client_credentials"
}

# Get OAuth Access Token
$tokenRequest = Invoke-WebRequest -Method Post -Uri $uri -ContentType "application/x-www-form-urlencoded" -Body $body -UseBasicParsing

# Set Access Token
$token = ($tokenRequest.Content | ConvertFrom-Json).access_token

Write-Host "`r`n- Retrieving PSTN call records for the last $Days days"

# Get Direct Routing calls
Write-Host "    - Retrieving Direct Routing call records"
$directRoutingCalls = Get-Calls -type "getDirectRoutingCalls" 

# Get Calling Plan calls
Write-Host "    - Retrieving Calling Plan call records"
$callingPlanCalls = Get-Calls -type "getPstnCalls"

# Save to file
Write-Host "`r`n- Saving PSTN call records to $SaveFormat files"

if ($SaveFormat -eq "JSON") {

    if ($directRoutingCalls) {
        try {
            Write-Host "    - Saving Direct Routing call records in JSON format to $SavePath\DirectRoutingCalls.json..." -NoNewline
            $directRoutingCalls | ConvertTo-Json | Out-File -FilePath "$SavePath\DirectRoutingCalls.json"
            Write-Host " SUCCESS" -ForegroundColor Green
        }
        catch {
            Write-Host " FAILED" -ForegroundColor Red
        }
    }

    if ($callingPlanCalls) {
        try {
            Write-Host "    - Saving Calling Plan call records in JSON format to $SavePath\CallingPlanCalls.json..." -NoNewline
            $callingPlanCalls | ConvertTo-Json | Out-File -FilePath "$SavePath\CallingPlanCalls.json"
            Write-Host " SUCCESS" -ForegroundColor Green
        }
        catch {
            Write-Host " FAILED" -ForegroundColor Red
        }
    }

}
elseif ($SaveFormat -eq "CSV") {

    if ($directRoutingCalls) {
        try {
            Write-Host "    - Saving Direct Routing call records in CSV format to $SavePath\DirectRoutingCalls.csv..." -NoNewline
            $directRoutingCalls | Export-Csv -Path "$SavePath\DirectRoutingCalls.csv"
            Write-Host " SUCCESS" -ForegroundColor Green
        }
        catch {
            Write-Host " FAILED" -ForegroundColor Red
        }

    }
 
    if ($callingPlanCalls) {
        try {
            Write-Host "    - Saving Calling Plan call records in CSV format to $SavePath\CallingPlanCalls.csv..." -NoNewline
            $callingPlanCalls | Export-Csv -Path "$SavePath\CallingPlanCalls.csv"
            Write-Host " SUCCESS" -ForegroundColor Green
        }
        catch {
            Write-Host " FAILED" -ForegroundColor Red
        }

    }

}