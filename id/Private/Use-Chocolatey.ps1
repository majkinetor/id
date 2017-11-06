<#
.SYNOPSIS
    Ensure chocolatey is available.

.DESCRIPTION
    Installs chocolatey in an idempotent way. 
    If behind the proxy, set `$env:http_proxy` environment variable.
#>
function Use-Chocolatey {    
    param(
        # Ensure latest version of chocolatey is present
        [switch] $Latest
    )

    Write-Host "Use Chocolatey" -Foreground yellow

    if (gcm choco.exe -ea 0) { 
        if ($Latest) { choco.exe upgrade chocolatey } 
        else { Write-Host 'Chocolatey version:' $(choco.exe --version -r) -Foreground green }
    } else {
        if ($env:http_proxy) { Write-Host "Using proxy:" $env:http_proxy } else { Write-Host "Not using proxy" }        
        $env:chocolateyProxyLocation = $env:https_proxy = $env:http_proxy
        iwr https://chocolatey.org/install.ps1 -Proxy $env:http_proxy -UseBasicParsing | iex 
    }

    . {
        choco feature enable -n=allowGlobalConfirmation
        choco feature enable -n=useRememberedArgumentsForUpgrades
    } *> $null
}