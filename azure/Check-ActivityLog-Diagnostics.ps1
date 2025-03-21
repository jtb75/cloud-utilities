# Connect to Azure
Connect-AzAccount

# Get all subscriptions your account has access to
$subscriptions = Get-AzSubscription

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
            SubscriptionName   = $sub.Name
            SubscriptionId     = $sub.Id
            LoggingConfigured  = "Yes"
            DiagnosticSetting  = $diagSettings.Name
        }
    } else {
        $results += [PSCustomObject]@{
            SubscriptionName   = $sub.Name
            SubscriptionId     = $sub.Id
            LoggingConfigured  = "No"
            DiagnosticSetting  = "-"
        }
    }
}

# Output results
$results | Format-Table -AutoSize

# Optional: Export to CSV
$results | Export-Csv -Path "./subscriptions-activity-log-status.csv" -NoTypeInformation

Write-Host "`nDone! Results exported to subscriptions-activity-log-status.csv"
