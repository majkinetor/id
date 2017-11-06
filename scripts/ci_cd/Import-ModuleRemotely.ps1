<#
.SYNOPSIS
    Import locally loaded module in remote session
#>
function Import-ModuleRemotely( [string] $ModuleName, [System.Management.Automation.Runspaces.PSSession] $Session)
{
    function remote( [scriptblock] $Script ) { Invoke-Command -Session $Session -ScriptBlock $Script -ErrorAction stop }

    if (!$Session) { throw 'Session parameter cant be null' }

    $module = Get-Module $ModuleName | select -First 1
    if ( !$module ) { 
        $module = Get-Module $ModuleName -ListAvailable | select -First 1
        if ( !$module ) { throw "Can't find local module '$ModuleName'" }
    }

    $module_path = Split-Path $module.Path

    $remote_path = remote { 
        $p = "$Env:TEMP\remote_module"
        rm "$p\$using:ModuleName" -Recurse -ea 0
        mkdir -Force $p | Out-Null
        $p
    }
 
    cp $module_path $remote_path\$ModuleName -ToSession $Session -Force -Recurse
    remote { import-module $using:remote_path\$using:ModuleName }
}