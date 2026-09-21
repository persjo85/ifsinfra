targetScope = 'resourceGroup'
param namePrefix string
param origins array
param healthProbePath string
param customDomainName string
param customDomainReady bool
param enablePublicRoute bool
param allowDefaultFrontdoorDomain bool
param wafMode string
param workspaceId string
param tags object
resource profile 'Microsoft.Cdn/profiles@2024-02-01' = { name: 'afd-${namePrefix}', sku: { name: 'Premium_AzureFrontDoor' }, tags: tags }
resource endpoint 'Microsoft.Cdn/profiles/afdEndpoints@2024-02-01' = { parent: profile, name: 'afd-${namePrefix}', properties: { enabledState: 'Enabled' }, tags: tags }
resource originGroup 'Microsoft.Cdn/profiles/originGroups@2024-02-01' = { parent: profile, name: 'og-regional-app', properties: { healthProbeSettings: { probePath: healthProbePath, probeRequestType: 'GET', probeProtocol: 'Https', probeIntervalInSeconds: 30 }, loadBalancingSettings: { sampleSize: 4, successfulSamplesRequired: 3, additionalLatencyInMilliseconds: 50 }, sessionAffinityState: 'Disabled' } }
resource origin 'Microsoft.Cdn/profiles/originGroups/origins@2024-02-01' = [for originConfig in origins: {
  parent: originGroup
  name: 'origin-${originConfig.regionCode}'
  properties: {
    enabledState: originConfig.enabled ? 'Enabled' : 'Disabled'
    hostName: originConfig.hostName
    originHostHeader: empty(originConfig.originHostHeader) ? originConfig.hostName : originConfig.originHostHeader
    httpPort: 80
    httpsPort: 443
    enforceCertificateNameCheck: true
    priority: originConfig.priority
    weight: originConfig.weight
    sharedPrivateLinkResource: {
      privateLink: { id: originConfig.privateLinkServiceId }
      groupId: ''
      privateLinkLocation: originConfig.privateLinkLocation
      requestMessage: 'Bicep ${namePrefix}: review and approve this Front Door private origin connection.'
    }
  }
}]
resource waf 'Microsoft.Cdn/cdnWebApplicationFirewallPolicies@2024-02-01' = { name: 'waf${replace(namePrefix, '-', '')}', location: 'global', sku: { name: 'Premium_AzureFrontDoor' }, tags: tags, properties: { policySettings: { enabledState: 'Enabled', mode: wafMode }, managedRules: { managedRuleSets: [ { ruleSetType: 'Microsoft_DefaultRuleSet', ruleSetVersion: '2.1' }, { ruleSetType: 'Microsoft_BotManagerRuleSet', ruleSetVersion: '1.1' } ] } } }
resource domain 'Microsoft.Cdn/profiles/customDomains@2024-02-01' = if (!empty(customDomainName)) { parent: profile, name: 'regional-app-domain', properties: { hostName: customDomainName, tlsSettings: { certificateType: 'ManagedCertificate', minimumTlsVersion: 'TLS12' } } }
resource securityPolicy 'Microsoft.Cdn/profiles/securityPolicies@2024-02-01' = { parent: profile, name: 'waf-regional-app', properties: { parameters: { type: 'WebApplicationFirewall', wafPolicy: { id: waf.id }, associations: [ { domains: concat([ { id: endpoint.id } ], customDomainReady && !empty(customDomainName) ? [ { id: domain.id } ] : []), patternsToMatch: [ '/*' ] } ] } } }
resource route 'Microsoft.Cdn/profiles/afdEndpoints/routes@2024-02-01' = if (enablePublicRoute) { parent: endpoint, name: 'regional-app', properties: { enabledState: 'Enabled', originGroup: { id: originGroup.id }, supportedProtocols: [ 'Http', 'Https' ], patternsToMatch: [ '/*' ], forwardingProtocol: 'HttpsOnly', httpsRedirect: 'Enabled', linkToDefaultDomain: allowDefaultFrontdoorDomain ? 'Enabled' : 'Disabled', customDomains: customDomainReady && !empty(customDomainName) ? [ { id: domain.id } ] : [] } }
resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = { scope: profile, name: 'central-logs', properties: { workspaceId: workspaceId, logs: [ { category: 'FrontDoorAccessLog', enabled: true }, { category: 'FrontDoorHealthProbeLog', enabled: true }, { category: 'FrontDoorWebApplicationFirewallLog', enabled: true } ], metrics: [ { category: 'AllMetrics', enabled: true } ] } }
output frontDoor object = { profile: profile.name, endpointHostname: endpoint.properties.hostName, publicRouteExists: enablePublicRoute, customHostname: customDomainName, validationToken: empty(customDomainName) ? '' : domain.properties.validationProperties.validationToken }
