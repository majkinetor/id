[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [String] $ModulePath,

    [Parameter(Mandatory = $true)]
    [Version] $Version
)

$module_name = Split-Path -Leaf $ModulePath

Write-Verbose "Getting public module functions"
$functions = ls $ModulePath\Public\*.ps1 | % { $_.Name -replace '\.ps1$' }
if ($functions.Count -eq 0) { throw 'No public functions to export' }

Write-Verbose "Getting public module aliases"
try { import-module $ModulePath -force } catch { throw $_ }
$aliases = Get-Alias | ? { $_.Source -eq $module_name -and ($functions -contains $_.Definition) }

Write-Verbose "Generating module manifest"
$params = @{
    Guid              = '390867c5-7554-49b5-ae04-1d13adfee680'
    Author            = 'Miodrag Milic'
    PowerShellVersion = '5.0'
    Description       = 'Install dependencies via packages.ps1'
    HelpInfoURI       = 'https://github.com/majkinetor/id/blob/master/README.md'
    Tags              = 'dependency', 'install', 'devops'
    LicenseUri        = 'https://www.gnu.org/licenses/gpl-2.0.txt'
    ProjectUri        = 'https://github.com/majkinetor/di'
    ReleaseNotes      = 'https://github.com/majkinetor/di/blob/master/CHANGELOG.md'

    ModuleVersion     = $Version
    FunctionsToExport = $functions
    AliasesToExport   = $aliases        #better then * as each alias is shown in PowerShell Galery
    Path              = "$ModulePath\$module_name.psd1"
    RootModule        = "$module_name.psm1"

}
New-ModuleManifest @params
