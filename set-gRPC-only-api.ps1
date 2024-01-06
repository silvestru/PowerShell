$outputs = Get-Content $env:jsonPath | Out-String | ConvertFrom-Json 

foreach($prop in $json.psobject.properties) {
    Write-Host("##vso[task.setvariable variable=$($prop.Name);]$($prop.Value.value)")
}

# Extract subscription ID and resource group
$subscriptionId = $outputs.subscription_id.value
$resourceGroup = $outputs.resource_group.value
$webAppName = $outputs.web_app.value

$apiVersion = "2020-12-01"
$accessToken = (Get-AzAccessToken).Token # Acquire this token via Azure DevOps service connection or other authentication means
$headers = @{Authorization="Bearer $accessToken"}

# Endpoint URLs
$getUri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Web/sites/$webAppName/config/web?api-version=$apiVersion"
$putUri = $getUri

Invoke-WebRequest -Method GET -Headers $headers -Uri $putUri

# Get current configuration
$response = Invoke-RestMethod -Uri $putUri -Method Get -Headers $headers

# Modify the configuration
$response.properties.http20ProxyFlag = 2

# Update the configuration
Invoke-RestMethod -Uri $putUri -Method Put -Body ($response | ConvertTo-Json -Depth 32) -ContentType "application/json" -Headers $headers
