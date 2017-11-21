class Chocolatey
{
    [string[]] $ExtraArgs = $Env:ID_Chocolatey_ExtraArgs
    
    #...

    hidden [string[]] $choco_list

    Chocolatey() {}

    Init() {
        if (!( gcm choco.exe -ea 0)) { [Chocolatey]::InstallRepository() }
    }

    # Returns local version of the package.
    # If package is present but version can't be found return '?'
    # If package is not present, return ''
    [string] GetLocalVersion( $pkg ) {
        if (!$this.choco_list) { $this.choco_list = choco list --local-only --limit-output }
        if ($l = $this.choco_list -match "^$($pkg.Name)\|") { return ($l -replace '.+?\|') }
        return ''
    }

    Install([HashTable] $pkg) {
        $params = @(
            'install'
            '--yes'
            $pkg.Name
            if ( $pkg.Params  ) { '--params',  $pkg.Params  }
            if ( $pkg.Version ) { '--version', $pkg.Version }  
            if ( $pkg.Source  ) { '--source',  $pkg.Source  }
            $this.ExtraArgs
        ) + $pkg.Options
  
        Write-Host "choco.exe $params"
        & choco.exe $params *>&1 | Write-Host
        if ($LastExitCode) { throw "Failed to install dependency - exit code $LastExitCode" }
        $this.choco_list += choco list -l -r $pkg.Name
    }

    # Installs chocolatey in an idempotent way. 
    # If behind the proxy, set $env:http_proxy environment variable.
    static InstallRepository( [switch] $Latest ) {
        Write-Host "Installing repository: Chocolatey" -Foreground yellow
    
        if (gcm choco.exe -ea 0) { 
            if ($Latest) { choco.exe upgrade chocolatey } 
            else { Write-Host 'Chocolatey version:' $(choco.exe --version -r) -Foreground green }
        } else {
            iwr https://chocolatey.org/install.ps1 -Proxy $env:http_proxy -UseBasicParsing | iex 
        }
    
        . {
            choco feature enable -n=allowGlobalConfirmation
            choco feature enable -n=useRememberedArgumentsForUpgrades
        } *> $null
    }
}
