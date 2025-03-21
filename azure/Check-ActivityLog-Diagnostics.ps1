param (
    [string]$SubscriptionId,
    [switch]$AllSubscriptions
)

# Auto-detect Cloud Shell
$runningInCloudShell = $false
if ($env.ACC_CLOUD) {
    $runningInCloudShell = $true
    Write-Host "Detected Cloud Shell environment. Skipping Connect-AzAccount..." -ForegroundColor Green
}

# Only connect if not in Cloud Shell
if (-not $runningInCloudShell) {
    Connect-AzAccount
}

# Get targeted subscriptions based on input
if ($AllSubscriptions) {
    $subscriptions = Get-AzSubscription
} elseif ($SubscriptionId) {
    $subscriptions = Get-AzSubscription -SubscriptionId $SubscriptionId
} else {
    Write-Host "Please specify either -SubscriptionId <id> or -AllSubscriptions" -ForegroundColor Yellow
    exit
}

# Create a list to hold results
$results = @()

foreach ($sub in $subscriptions) {
    Set-AzContext -SubscriptionId $sub.Id | Out-Null

    # Resource ID for Activity Log at subscription level
    $resourceId = "/subscriptions/$($sub.Id)/providers/microsoft.insights/eventtypes/management"

    # Get diagnostic settings for Activity Log
    $diagSettings = Get-AzDiagnosticSetting -ResourceId $resourceId -ErrorAction SilentlyContinue

    if ($diagSettings) {
        $results += [PSCustomObject]@{
            SubscriptionName     = $sub.Name
            SubscriptionId       = $sub.Id
            LoggingConfigured    = "Yes"
            DiagnosticSetting    = $diagSettings.Name
            EventHubNamespace    = if ($diagSettings.EventHubAuthorizationRuleId) { ($diagSettings.EventHubAuthorizationRuleId -split '/')[8] } else { "-" }
            EventHubName         = if ($diagSettings.EventHubName) { $diagSettings.EventHubName } else { "-" }
            EventHubAuthRule     = if ($diagSettings.EventHubAuthorizationRuleId) { ($diagSettings.EventHubAuthorizationRuleId -split '/')[10] } else { "-" }
        }
    } else {
        $results += [PSCustomObject]@{
            SubscriptionName     = $sub.Name
            SubscriptionId       = $sub.Id
            LoggingConfigured    = "No"
            DiagnosticSetting    = "-"
            EventHubNamespace    = "-"
            EventHubName         = "-"
            EventHubAuthRule     = "-"
        }
    }
}

# Output results to console
$results | Format-Table -AutoSize

# Optional: Export to CSV (Cloud Shell file system or local)
$outputPath = if ($runningInCloudShell) { "$HOME/subscriptions-activitylog-destinations.csv" } else { "./subscriptions-activitylog-destinations.csv" }
$results | Export-Csv -Path $outputPath -NoTypeInformation

Write-Host "`nDone! Results exported to $outputPath"
