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

    .\Get-TeamsPSTNRecords.ps1 -SavePath C:\Temp -Days 10 -SaveType JSON
    Retreive call records for the last 10 days and save as JSON files

    .\Get-TeamsPSTNRecords.ps1 -SavePath C:\Temp -Days 50 -SaveType JSON
    Retreive call records for the last 50 days and save as CSV files

#>

param (
    [Parameter(mandatory = $true)][string]$SavePath,
    [Parameter(mandatory = $true)][int]$Days,
    [Parameter(mandatory = $true)][ValidateSet("JSON", "CSV")]$SaveType
)

function Get-Calls {
    param (
        [Parameter(mandatory = $true)][string]$type
    )

    $currentUri = "https://graph.microsoft.com/beta/communications/callRecords/$type(fromDateTime=$fromDateTime,toDateTime=$toDateTime)"

    $content = while (-not [string]::IsNullOrEmpty($currentUri)) {

        $apiCall = Invoke-RestMethod -Method "GET" -Uri $currentUri -ContentType "application/json" -Headers @{Authorization = "Bearer $token" } -ErrorAction Stop
    
        $currentUri = $null

        if ($apiCall) {

            # Check if any data is left
            $currentUri = $apiCall.'@odata.nextLink'

            $apiCall.value

        }

    }

    return $content

}

# Start
Write-Host "`n----------------------------------------------------------------------------------------------
            `n Get-TeamsPSTNCallRecords.ps1 - Lee Ford - https://www.lee-ford.co.uk
            `n----------------------------------------------------------------------------------------------" -ForegroundColor Yellow

# Check Days is between 1 and 90 days
if ($Days -lt 0 -or $Days -gt 90) {

    Write-Host "Please specify a valid date range (between 0 and 90 days)" -ForegroundColor Red
    break

}

# Check Save Path exists
if (-not (Test-Path -Path $SavePath)) {

    Write-Host "$SavePath does not exist, please specify a valid path" -ForegroundColor Red
    break

}

# Application (client) ID, tenant ID and secret
$clientId = ""
$tenantId = ""
$clientSecret = ''

$uri = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
$body = @{
    client_id     = $clientId
    scope         = "https://graph.microsoft.com/.default"
    client_secret = $clientSecret
    grant_type    = "client_credentials"
}

# Get OAuth 2.0 Token
$tokenRequest = Invoke-WebRequest -Method Post -Uri $uri -ContentType "application/x-www-form-urlencoded" -Body $body -UseBasicParsing

# Access Token
$token = ($tokenRequest.Content | ConvertFrom-Json).access_token

# Create date range
$toDateTime = (Get-Date).AddDays(+1) | Get-Date -Format "yyyy-MM-dd" # Add one day to include today
$fromDateTime = (Get-Date).AddDays(-$Days) | Get-Date -Format "yyyy-MM-dd"

# Get Direct Routing calls
$directRoutingCalls = Get-Calls -type "getDirectRoutingCalls" 

# Get Calling Plan calls
$callingPlanCalls = Get-Calls -type "getPstnCalls"

# Save to files
if ($SaveType -eq "JSON") {

    $directRoutingCalls | ConvertTo-Json | Out-File -FilePath "$SavePath\DirectRoutingCalls.json"
    $callingPlanCalls | ConvertTo-Json | Out-File -FilePath "$SavePath\CallingPlanCalls.json"

} elseif ($SaveType -eq "CSV") {

    $directRoutingCalls | Export-Csv -Path "$SavePath\DirectRoutingCalls.csv"
    $callingPlanCalls | Export-Csv -Path "$SavePath\CallingPlanCalls.csv"

}