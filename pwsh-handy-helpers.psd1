@{
    ModuleVersion = '1.0.0.0'
    RootModule = 'pwsh-handy-helpers.psm1'
    GUID = '5af3199a-e01b-4ed6-87ad-fdea39aa7e77'
    CompanyName = 'Unknown'
    Author = 'Jason Wohlgemuth'
    Copyright = '(c) 2020 Jason Wohlgemuth. All rights reserved.'
    Description = 'Helper functions, aliases and more'
    PowerShellVersion = '5.0'
    FileList = @()
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    FunctionsToExport = @(
        'Find-Duplicates',
        'Get-File',
        'Install-SshServer',
        'New-File',
        'New-SshKey',
        'Remove-DirectoryForce',
        'Take',
        'Test-Admin',
        'Test-Empty',
        'Test-Installed'
    )
    PrivateData = @{
        PSData = @{
            Tags = @('helpers')
            LicenseUri = 'https://github.com/jhwohlgemuth/pwsh-handy-helpers/blob/master/LICENSE'
            ProjectUri = 'https://github.com/jhwohlgemuth/pwsh-handy-helpers'
        }
    }
}
    