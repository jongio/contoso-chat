targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

// Optional parameters to override the default azd resource naming conventions. Update the main.parameters.json file to provide values. e.g.,:
// "resourceGroupName": {
//      "value": "myGroupName"
// }

param applicationInsightsName string = ''
param azureOpenAiResourceName string = ''
param containerRegistryName string = ''
param cosmosAccountName string = ''
param keyVaultName string = ''
param resourceGroupName string = ''
param searchLocation string = ''
param searchServiceName string = ''
param storageServiceName string = ''

param accountsContosoChatSfAiServicesName string = 'contoso-chat-sf-ai-aiservices'
param workspacesApwsContosoChatSfAiName string = 'apws-contoso-chat-sf-ai'

@description('Id of the user or app to assign application roles')
param principalId string = ''

var openaiSubdomain = '${accountsContosoChatSfAiServicesName}${resourceToken}'
var openaiEndpoint = 'https://${openaiSubdomain}.openai.azure.com/'
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : 'rg-${environmentName}'
  location: location
  tags: tags
}

module containerRegistry 'core/host/container-registry.bicep' = {
  name: 'containerregistry'
  scope: rg
  params: {
    name: !empty(containerRegistryName) ? containerRegistryName : 'acrcontoso${resourceToken}'
    location: location
    tags: tags
    sku: {
      name: 'Standard'
    }
    scopeMaps: [
      {
        name: '_repositories_pull'
        properties: {
          description: 'Can pull any repository of the registry'
          actions: [
            'repositories/*/content/read'
          ]
        }
      }
      {
        name: '_repositories_pull_metadata_read'
        properties: {
          description: 'Can perform all read operations on the registry'
          actions: [
            'repositories/*/content/read'
            'repositories/*/metadata/read'
          ]
        }
      }
      {
        name: '_repositories_push'
        properties: {
          description: 'Can push to any repository of the registry'
          actions: [
            'repositories/*/content/read'
            'repositories/*/content/write'
          ]
        }
      }
      {
        name: '_repositories_push_metadata_write'
        properties: {
          description: 'Can perform all read and write operations on the registry'
          actions: [
            'repositories/*/metadata/read'
            'repositories/*/metadata/write'
            'repositories/*/content/read'
            'repositories/*/content/write'
          ]
        }
      }
      {
        name: '_repositories_admin'
        properties: {
          description: 'Can perform all read, write and delete operations on the registry'
          actions: [
            'repositories/*/metadata/read'
            'repositories/*/metadata/write'
            'repositories/*/content/read'
            'repositories/*/content/write'
            'repositories/*/content/delete'
          ]
        }
      }
    ]
  }
}

module cosmos 'core/database/cosmos/sql/cosmos-sql-db.bicep' = {
  name: 'cosmos'
  scope: rg
  params: {
    accountName: !empty(cosmosAccountName) ? cosmosAccountName : 'cosmos-contoso-${resourceToken}'
    databaseName: 'contoso-outdoor'
    location: location
    tags: union(tags, {
      defaultExperience: 'Core (SQL)'
      'hidden-cosmos-mmspecial': ''
    })
    keyVaultName: keyvault.outputs.name
    containers: [
      {
        name: 'customers'
        id: 'customers'
        partitionKey: '/id'
      }
    ]
  }
}

module keyvault 'core/security/keyvault.bicep' = {
  name: 'keyvault'
  scope: rg
  params: {
    name: !empty(keyVaultName) ? keyVaultName : 'kvcontoso${resourceToken}'
    location: location
    tags: tags
    principalId: principalId
  }
}

module machinelearning 'app/ml.bicep' = {
  name: 'machinelearning'
  scope: rg
  params: {
    location: location
    storageAccountId: storage.outputs.id
    keyVaultId: keyvault.outputs.id
    appInsightId: monitoring.outputs.applicationInsightsId
    containerRegistryId: containerRegistry.outputs.id
    openAiEndpoint: openaiEndpoint
    openAiName: openai.outputs.name
    searchName: search.outputs.name
  }
}

module monitoring 'core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    logAnalyticsName: workspacesApwsContosoChatSfAiName
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${environmentName}-appi-contoso${resourceToken}'
    location: location
    tags: tags
  }
}


module openai 'core/ai/cognitiveservices.bicep' = {
  name: 'openai'
  scope: rg
  params: {
    name: !empty(azureOpenAiResourceName) ? azureOpenAiResourceName : '${environmentName}-openai-contoso-${resourceToken}'
    location: location
    tags: tags
    kind: 'AIServices'
    customSubDomainName: openaiSubdomain
    deployments: [
      {
        name: 'gpt-35-turbo'
        model: {
          format: 'OpenAI'
          name: 'gpt-35-turbo'
          version: '0613'
        }
        sku: {
          name: 'Standard'
          capacity: 20
        }
      }
      {
        name: 'gpt-4'
        model: {
          format: 'OpenAI'
          name: 'gpt-4'
          version: '0613'
        }
        sku: {
          name: 'Standard'
          capacity: 10
        }
      }
      {
        name: 'text-embedding-ada-002'
        model: {
          format: 'OpenAI'
          name: 'text-embedding-ada-002'
          version: '2'
        }
        sku: {
          name: 'Standard'
          capacity: 20
        }
      }
    ]
  }
}

module search 'core/search/search-services.bicep' = {
  name: 'search'
  scope: rg
  params: {
    name: !empty(searchServiceName) ? searchServiceName : '${environmentName}-search-contoso${resourceToken}'
    location: searchLocation
    semanticSearch: 'free'
  }
}

module storage 'core/storage/storage-account.bicep' = {
  name: 'storage'
  scope: rg
  params: {
    name: !empty(storageServiceName) ? storageServiceName : 'stcontoso${resourceToken}'
    location: location
    blobs: [
      {
        name: 'default'
        properties: {
          cors: {
            corsRules: [
              {
                allowedOrigins: [
                  'https://mlworkspace.azure.ai'
                  'https://ml.azure.com'
                  'https://*.ml.azure.com'
                  'https://ai.azure.com'
                  'https://*.ai.azure.com'
                  'https://mlworkspacecanary.azure.ai'
                  'https://mlworkspace.azureml-test.net'
                ]
                allowedMethods: [
                  'GET'
                  'HEAD'
                  'POST'
                  'PUT'
                  'DELETE'
                  'OPTIONS'
                  'PATCH'
                ]
                maxAgeInSeconds: 1800
                exposedHeaders: [
                  '*'
                ]
                allowedHeaders: [
                  '*'
                ]
              }
            ]
          }
          deleteRetentionPolicy: {
            allowPermanentDelete: false
            enabled: false
          }
        }
      }
    ]
    files: [
      {
        name: 'default'
        properties: {
          protocolSettings: {
            smb: {}
          }
          cors: {
            corsRules: [
              {
                allowedOrigins: [
                  'https://mlworkspace.azure.ai'
                  'https://ml.azure.com'
                  'https://*.ml.azure.com'
                  'https://ai.azure.com'
                  'https://*.ai.azure.com'
                  'https://mlworkspacecanary.azure.ai'
                  'https://mlworkspace.azureml-test.net'
                ]
                allowedMethods: [
                  'GET'
                  'HEAD'
                  'POST'
                  'PUT'
                  'DELETE'
                  'OPTIONS'
                  'PATCH'
                ]
                maxAgeInSeconds: 1800
                exposedHeaders: [
                  '*'
                ]
                allowedHeaders: [
                  '*'
                ]
              }
            ]
          }
          shareDeleteRetentionPolicy: {
            enabled: true
            days: 7
          }
        }
      }
    ]
    queues: [
      {
        name: 'default'
        properties: {
          cors: {
            corsRules: []
          }
        }
      }
    ]
    tables: [
      {
        name: 'default'
        properties: {
          cors: {
            corsRules: []
          }
        }
      }
    ]
  }
}

// output the names of the resources
output AZURE_OPENAI_NAME string = openai.outputs.name
output AZURE_COSMOS_NAME string = cosmos.outputs.accountName
output AZURE_SEARCH_NAME string = search.outputs.name
output AZURE_WORKSPACE_NAME string = machinelearning.outputs.workspace_name
output AZURE_PROJECT_NAME string = machinelearning.outputs.project_name

output AZURE_RESOURCE_GROUP string = rg.name
output CONTOSO_AI_SERVICES_ENDPOINT string = openaiEndpoint
output COSMOS_ENDPOINT string = cosmos.outputs.endpoint
output CONTOSO_SEARCH_ENDPOINT string = search.outputs.endpoint
