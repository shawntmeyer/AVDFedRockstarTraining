@description('This is the location in which all the linked templates are stored.')
param assetLocation string = 'https://raw.githubusercontent.com/shawntmeyer/AVDFedRockstarTraining/master/AAD-Hybrid-Lab/'

@description('Username to set for the local User. Cannot be "Administrator", "root" and possibly other such common account names. ')
param adminUsername string = 'ADAdmin'

@description('When deploying the stack N times simultaneously, define the instance - this will be appended to some resource names to avoid collisions.')
@allowed([
  '0'
  '1'
  '2'
  '3'
  '4'
  '5'
  '6'
  '7'
  '8'
  '9'
])
param deploymentNumber string = '1'

@description('Password for the local administrator account. Cannot be "P@ssw0rd" and possibly other such common passwords. Must be 8 characters long and three of the following complexity requirements: uppercase, lowercase, number, special character')
@secure()
param adminPassword string

@description('IMPORTANT: Two-part internal AD name - short/NB name will be first part (\'contoso\'). The short name will be reused and should be unique when deploying this template in your selected region. If a name is reused, DNS name collisions may occur.')
param adDomainName string

param location string = resourceGroup().location

@description('JSON object array of users that will be loaded into AD once the domain is established.')
param usersArray array = [
  {
    FName: '1Bob'
    LName: 'Jones'
    SAM: '1bjones'
  }
  {
    FName: '1Bill'
    LName: 'Smith'
    SAM: '1bsmith'
  }
  {
    FName: '1Mary'
    LName: 'Phillips'
    SAM: '1mphillips'
  }
  {
    FName: '1Sue'
    LName: 'Jackson'
    SAM: '1sjackson'
  }
  {
    FName: '1Jack'
    LName: 'Petersen'
    SAM: '1jpetersen'
  }
  {
    FName: '1Julia'
    LName: 'Williams'
    SAM: '1jwilliams'
  }
  {
    FName: '2Bob'
    LName: 'Jones'
    SAM: '2bjones'
  }
  {
    FName: '2Bill'
    LName: 'Smith'
    SAM: '2bsmith'
  }
  {
    FName: '2Mary'
    LName: 'Phillips'
    SAM: '2mphillips'
  }
  {
    FName: '2Sue'
    LName: 'Jackson'
    SAM: '2sjackson'
  }
  {
    FName: '2Jack'
    LName: 'Petersen'
    SAM: '2jpetersen'
  }
  {
    FName: '2Julia'
    LName: 'Williams'
    SAM: '2jwilliams'
  }
  {
    FName: '3Bob'
    LName: 'Jones'
    SAM: '3bjones'
  }
  {
    FName: '3Bill'
    LName: 'Smith'
    SAM: '3bsmith'
  }
  {
    FName: '3Mary'
    LName: 'Phillips'
    SAM: '3mphillips'
  }
  {
    FName: '3Sue'
    LName: 'Jackson'
    SAM: '3sjackson'
  }
  {
    FName: '3Jack'
    LName: 'Petersen'
    SAM: '3jpetersen'
  }
  {
    FName: '3Julia'
    LName: 'Williams'
    SAM: '3jwilliams'
  }
  {
    FName: '4Bob'
    LName: 'Jones'
    SAM: '4bjones'
  }
  {
    FName: '4Bill'
    LName: 'Smith'
    SAM: '4bsmith'
  }
  {
    FName: '4Mary'
    LName: 'Phillips'
    SAM: '4mphillips'
  }
  {
    FName: '4Sue'
    LName: 'Jackson'
    SAM: '4sjackson'
  }
  {
    FName: '4Jack'
    LName: 'Petersen'
    SAM: '4jpetersen'
  }
  {
    FName: '4Julia'
    LName: 'Williams'
    SAM: '4jwilliams'
  }
]

@description('This needs to be specified in order to have a uniform logon experience within AVD')
param entraIdPrimaryOrCustomDomainName string

@description('Enter the password that will be applied to each user account to be created in AD.')
@secure()
param defaultUserPassword string

@description('Select a VM SKU (please ensure the SKU is available in your selected region).')
param vmSize string = 'Standard_B2ms'

@description('The subnet Resource Id to which the Domain Controller will be attached.')
param adSubnetResourceId string

var networkInterfaceName = 'NIC'
var addcVMNameSuffix = 'dc'
var companyNamePrefix = split(adDomainName, '.')[0]
var adVMName = toUpper('${companyNamePrefix}${addcVMNameSuffix}')
var adDSCTemplate = '${assetLocation}DSC/adDSC.zip'
var adDSCConfigurationFunction = 'adDSCConfiguration.ps1\\DomainController'
var imageOffer = 'WindowsServer'
var imagePublisher = 'MicrosoftWindowsServer'
var imageSKU = '2019-Datacenter'

var adNicName = '${adVMName}-${networkInterfaceName}-${deploymentNumber}'

resource adNic 'Microsoft.Network/networkInterfaces@2019-12-01' = {
  name: adNicName
  location: location
  tags: {
    displayName: 'adNIC'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig${deploymentNumber}'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: adSubnetResourceId
          }
        }
      }
    ]
  }
}

resource adVM 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: adVMName
  location: location
  tags: {
    displayName: 'adVM'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: adVMName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
        version: 'latest'
      }
      osDisk: {
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: adNic.id
        }
      ]
    }
  }
}

resource adVMName_Microsoft_Powershell_DSC 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = {
  name: 'Microsoft.Powershell.DSC'
  parent: adVM
  location: location
  tags: {
    displayName: 'adDSC'
  }
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.21'
    forceUpdateTag: '1.02'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: adDSCTemplate
      configurationFunction: adDSCConfigurationFunction
      properties: [
        {
          Name: 'adDomainName'
          Value: adDomainName
          TypeName: 'System.Object'
        }
        {
          Name: 'customupnsuffix'
          Value: entraIdPrimaryOrCustomDomainName
          TypeName: 'System.Object'
        }
        {
          Name: 'AdminCreds'
          Value: {
            UserName: adminUsername
            Password: 'PrivateSettingsRef:AdminPassword'
          }
          TypeName: 'System.Management.Automation.PSCredential'
        }
        {
          Name: 'usersArray'
          Value: usersArray
          TypeName: 'System.Object'
        }
        {
          Name: 'UserCreds'
          Value: {
            UserName: 'user'
            Password: 'PrivateSettingsRef:UserPassword'
          }
          TypeName: 'System.Management.Automation.PSCredential'
        }
      ]
    }
    protectedSettings: {
      Items: {
        AdminPassword: adminPassword
        UserPassword: defaultUserPassword
      }
    }
  }
}
