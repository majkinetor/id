import-module -force $PSScriptRoot\id.psm1

Install-Dependencies -Tags {build -and !develop -or test}