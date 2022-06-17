using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

$body = @{}
$status = [HttpStatusCode]::OK

try {
    Write-Host "PowerShell HTTP trigger function processed a request."
    $body = $Request.Body;
    # Interact with query parameters or the body of the request.
    # $Request.Body.Name
    #$wc = new-object System.Net.WebClient
    #$wc.DownloadFile("http://www.contoso.com/MyDoc.doc","c:\temp\MyDoc.doc")
    #@{Account="User01";Domain="Domain01";Admin="True"} | ConvertTo-Json -Compress

    #
    # environment
    $vaultName = ""
    $secretName = ""


    #
    # get - secret value
    $secret = Get-AzureKeyVaultSecret -VaultName $vaultName -Name $secretName

    #
    #
    # storage account context
    $storageAccountName = "pshtablestorage"
    $storageAccount = New-AzStorageAccount -ResourceGroupName $resourceGroup `
        -Name $storageAccountName `
        -Location $location `
        -SkuName Standard_LRS `
        -Kind Storage

    $ctx = $storageAccount.Context

    #
    # write event to table
    $tableName = "events"
    $cloudTable = (Get-AzStorageTable –Name $tableName –Context $ctx).CloudTable

    $invocationId = (New-Guid).Guid.ToString("N")
    $partitionKey1 = "requests"

    # add request body to table storage
    Add-AzTableRow `
        -table $cloudTable `
        -partitionKey $partitionKey1 `
        -rowKey ($invocationId) -property $Request.Body

    #
    #
    # publish to event grid
    $eventID = Get-Random 99999

    #Date format should be SortableDateTimePattern (ISO 8601)
    $eventDate = Get-Date -Format s

    #Construct body using Hashtable
    $htbody = @{
        id          = $eventID
        eventType   = "request"
        subject     = "myapp/vehicles/motorcycles"
        eventTime   = $eventDate   
        data        = @{
            make  = "Ducati"
            model = "Monster"
        }
        dataVersion = "1.0"
    }
    $event_body = "[" + (ConvertTo-Json $htbody) + "]"

    #
    #
    # publish event to event grid
    $topicname = ""
    $gridResourceGroup = ""
    $endpoint = (Get-AzEventGridTopic -ResourceGroupName gridResourceGroup -Name $topicname).Endpoint
    $keys = Get-AzEventGridTopicKey -ResourceGroupName gridResourceGroup -Name $topicname
    Invoke-WebRequest -Uri $endpoint -Method POST -Body $body -Headers @{"aeg-sas-key" = $keys.Key1 }Invoke-WebRequest -Uri $endpoint -Method POST -Body $body -Headers @{"aeg-sas-key" = $keys.Key1 }
}
catch [System.Net.WebException], [System.IO.IOException] {
    $body = "Unable to download MyDoc.doc from http://www.contoso.com."
}
catch {
    $body = "An error occurred that could not be resolved."
}

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $body
    })