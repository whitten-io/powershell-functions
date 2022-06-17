param($eventGridEvent, $TriggerMetadata)

# Make sure to pass hashtables to Out-String so they're logged correctly
$eventGridEvent | Out-String | Write-Host

try {
    #
    #
    # send REST Request
    
    #
    # if resource exists (handle it)
}
catch [System.Net.WebException], [System.IO.IOException] {
    $body = "Unable to download MyDoc.doc from http://www.contoso.com."
}
catch {
    $body = "An error occurred that could not be resolved."
}