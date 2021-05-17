
# PurviewPS
A powershell module to interact with Microsoft Azure Purview via the Apache Atlas API's

## Prerequisites

 - A working purview instance. https://docs.microsoft.com/en-us/azure/purview/create-catalog-portal
 - Create a service principal and configure your purview catalog to trust it https://docs.microsoft.com/en-us/azure/purview/tutorial-using-rest-apis  
 
 ## Installation
 - Download a copy of the module and extract to a location if zipped.
 - `Import-Module <Path to extracted folder> -Verbose -Force `

## Client Setup
All module commands require a Client object to be passed into them, this is obtained from the `New-PurviewClient` command.

The `New-PurviewClient`command requires the following mandatory inputs to acquire an oauth token successfully.

 - [ ]  ClientID
 The Client GUID of the service principal name (SPN) configured in the prerequisites.
 - [ ]   ClientSecret
 The client secret of the SPN generated  in the prerequisites
 - [ ]   ApplicationID
The application GUID of the SPN configured in the prerequisites.
 - [ ]   TenantID
 The GUID of the tenant that contains the purview instance and SPN.
 - [ ]   PurviewName
The name of the purview instance. This is used in the generation of the URI for rest calls. If you are unsure of the correct value then you can obtain it from the Azure Portal by:
- Navigate to the Azure Portal.
- Search for "Purview Accounts", then select your instance.
- Click on the Properties option from the left hand navigation pane
- Locate the 'Atlas endpoint' value and extract the Purview name using this pattern: https://`Purview Name`.catalog.purview.azure.com

If configured correctly the `New-PurviewClient`command will return a Client object with a valid oauth Token attached, this client object is responsible for making all of the REST API calls to the purview atlas instance. 

If the first attempt call fails because the token is expired (401) the client will attempt to reobtain a token and resubmit the request, if the retry call fails an exception is thrown.

## Commands
This PowerShell module provides a command per grouping of HTTP method (aligned with recommended Powershell command prefixes), per each of the atlas endpoints:
(Entity, Glossary, Lineage, Relationship, Types).

### Entity
`Get-Entity`
Supporting all the API URI's available for api/atlas/v2/entity/* for the GET http method 

`Set-Entity`
Supporting all the API URI's available for api/atlas/v2/entity/* for the PUT http method 

`Add-Entity`
Supporting all the API URI's available for api/atlas/v2/entity/* for the POST http method 

`Remove-Entity`
Supporting all the API URI's available for api/atlas/v2/entity/* for the DELETE http method 


### TypeDefs
`Get-TypeDefs`
Supporting all the API URI's available for api/atlas/v2/type/* for the GET http method 

`Set-TypeDefs`
Supporting all the API URI's available for api/atlas/v2/type/* for the PUT http method 

`Add-TypeDefs`
Supporting all the API URI's available for api/atlas/v2/type/* for the POST http method 

`Remove-TypeDefs`
Supporting all the API URI's available for api/atlas/v2/type/* for the DELETE http method 


### Relationship
`Get-Relationship`
Supporting all the API URI's available for api/atlas/v2/relationship/* for the GET http method

`Set-Relationship`
Supporting all the API URI's available for api/atlas/v2/relationship/* for the PUT http method

`Add-Relationship`
Supporting all the API URI's available for api/atlas/v2/relationship/* for the POST http method

`Remove-Relationship`
Supporting all the API URI's available for api/atlas/v2/relationship/* for the DELETE http method


### Lineage
`Get-Lineage`
Supporting all the API URI's available for api/atlas/v2/lineage/* for the GET http method

### Glossary
`Get-Glossary`
Supporting all the API URI's available for api/atlas/v2/glossary/* for the GET http method

`Set-Glossary`
Supporting all the API URI's available for api/atlas/v2/glossary/* for the PUT http method

`Add-Glossary`
Supporting all the API URI's available for api/atlas/v2/glossary/* for the POST http method

`Remove-Glossary`
Supporting all the API URI's available for api/atlas/v2/glossary/* for the GET DELETE method

### Discovery
#### To Be Implemented
Support all api/atlas/v2/search/* API

To Do:
Implement discovery commands
Replicate all atlas objects as Powershell Classes
Refactor commands to use proper atlas classes
Test Everything
Create documentation for command parameter usage
