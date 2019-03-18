@{
  ModuleVersion = '1.0.1'
  RootModule = 'domainAwsDSCResources.psm1'
  AliasesToExport = @()
  FunctionsToExport = @()
  CmdletsToExport = @()
  PowerShellVersion = '5.0.0.0'
  PrivateData = @{
    builtBy = 'Adrian.Andersson'
    moduleRevision = '1.0.0.2'
    builtOn = '2019-03-18T13:43:56'
    PSData = @{
      LicenseUri = 'https://github.com/DomainGroupOSS/domainAwsDSCResources/blob/master/LICENSE'
      ProjectUri = 'https://github.com/DomainGroupOSS/domainAwsDSCResources'
      ReleaseNotes = 'OpenSource version of some of our internal DSCresources'
    }
    bartenderCopyright = '2019 Domain Group'
    pester = @{
      time = '00:00:01.0732268'
      codecoverage = 0
      passed = '100 %'
    }
    bartenderVersion = '6.1.22'
    moduleCompiledBy = 'Bartender | A Framework for making PowerShell Modules'
  }
  GUID = '2000ae14-7927-4297-b82b-ecf4c1a05e3b'
  Description = 'DSC Resources for AWS EC2 Instances'
  Copyright = '2019 Domain Group'
  CompanyName = 'Domain Group'
  Author = 'Adrian.Andersson'
  DscResourcesToExport = @('dmAwsTagInstance','dmAwsTimeSync')
  ScriptsToProcess = @()
}
