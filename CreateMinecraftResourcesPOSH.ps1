#### minecraft demo code

write-host -ForegroundColor Green "*** Initializing Minecraft Dedicated Server ***"

write-host -ForegroundColor Yellow "Setting Variables"
$randomNum=get-random -Maximum 200

# Set variables to match your scenario
$subscriptionName ="TEST" #Change the subscription name to match yours
$resourceGroupName = "minecraftserver"
$location = "eastus"
$StorageAccountName="gamestorage"+$randomNum
$ShareName="minecraftdata"
$containerGroupName = "minecraftservergroup"
$dnsNameLabel = "Minecraft"+$randomNum
$environmentVariables = @{ EULA = "TRUE"; OPS = "adminuser";} #Change adminuser to match your minecraft user account
#Ram and CPU settings for the minecraft server, this may change based on your play
$ramAmount=8
$cpuAmount=2

# login to Azure PowerShell if not logged in
$loggedIn=Get-AzContext
if (!$loggedIn)
{
    Connect-AzAccount
}
    

# select the subscription we want to use
Set-AzContext -SubscriptionName $subscriptionName | out-null  

# create a resource group
New-AzResourceGroup -Name $resourceGroupName -Location $location -Force


# Check if the storage Account exists and create if it does not exist
Write-Host -ForegroundColor Yellow "Checking For Storage Account...."
$storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName -ErrorAction SilentlyContinue
write-host $storageAccount
if ($storageAccount -eq $null) {
    # create the storage account
    write-host -ForegroundColor Green "Creating Storage Account!"
    $storageAccount = New-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageAccountName -SkuName Standard_LRS -Location $Location
}

# Check to see if the file share exists
Write-Host -ForegroundColor Yellow "Checking For File Share...."
$share = Get-AzStorageShare -Name $ShareName -Context $storageAccount.Context -ErrorAction SilentlyContinue
if ($share -eq $null) {
    # create the share
    write-host -ForegroundColor Green "Creating File Share!"
    $share = New-AzStorageShare -Name $ShareName -Context $storageAccount.Context
}

# get the credentials
$storageAccountKeys = Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $StorageAccountName
$storageAccountKey = $storageAccountKeys[0].Value
$storageAccountKeySecureString = ConvertTo-SecureString $storageAccountKey -AsPlainText -Force
$storageAccountCredentials = New-Object System.Management.Automation.PSCredential ($storageAccountName, $storageAccountKeySecureString)


#Creating the Azure Container Group
write-host -ForegroundColor Green "Creating Azure Container Instance!"
New-AzContainerGroup -ResourceGroupName $resourceGroupName `
    -Name $containerGroupName `
    -Image "itzg/minecraft-server" `
    -IpAddressType Public `
    -OsType Linux `
    -DnsNameLabel $dnsNameLabel `
    -Port 25565 `
    -EnvironmentVariable $environmentVariables `
    -AzureFileVolumeAccountCredential $storageAccountCredentials `
    -AzureFileVolumeShareName $shareName `
    -AzureFileVolumeMountPath "/data" `
    -MemoryInGB $ramAmount `
    -Cpu $cpuAmount `




