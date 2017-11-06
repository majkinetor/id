<#
.SYNOPSIS
    Get HashTable that keeps service environment definition.

.DESCRIPTION
    The directory '_env' is searched in current directory and upward from the current location until it is found.
    Script _env\base.ps1 is called without argumetns to get the list of environments.
    Requested environment is then loaded and returned.

.PARAMETER Environment
    Environment name to load
#>
function Get-ServiceEnvironment( [string] $Environment ) {
    #$ProjectRoot = git rev-parse --show-toplevel

    foreach ( $i in 0..20 ) { $p = '../'*$i + '_env'; if (Test-Path $p) { $env_dir = $p; break } }
    if (!$env_dir) { throw "Can't find '_env' directory in the current and upward directories" }
    $environments = & "$env_dir\base.ps1"
    if ($Environment -notin $environments) { throw "Invalid environment '$Environment'.  Valid environments are $($environments -join ', ')"  }
    
    $env = & "$env_dir\$Environment.ps1"
    Write-Host 'Environment loaded:' $env.Name -ForegroundColor Green
    $env
}