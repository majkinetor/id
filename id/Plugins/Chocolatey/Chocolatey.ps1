class Chocolatey
{
    [string[]] $ChocoArgs
    
    #...

    [string] $choco_list

    Chocolatey() {
    }

    # Returns version
    [string] Install([HashTable] $pkg) {

        function init() {
            if (!(gcm choco.exe -ea 0)) { InstallChocolatey }
            $this.choco_list = choco list --local-only --limit-output         
        }

        if (!$this.choco_list) { init }
        
        $name = $pkg.Name
        if ($l = $this.choco_list -match "^$name\|") { return ($l -replace '\|.+') }

        Write-Host "Installing dependency: $name" -ForegroundColor yellow

        $params = @(
            'install'
            '--yes'
            $name
            if ( $pkg.Params  ) { '--params',  $pkg.Params  }
            if ( $pkg.Version ) { '--version', $pkg.Version }  
            if ( $pkg.Source  ) { '--source',  $pkg.Source  }
            $this.ChocoArgs
        ) + $pkg.Options
  
        Write-Host "choco.exe $params"
        & choco.exe $params
        if ($LASTEXITCODE) { throw "Failed to install dependency '$name' - exit code $LastExitCode" }
        return 'latest'
    }

    # Installs chocolatey in an idempotent way. 
    # If behind the proxy, set $env:http_proxy environment variable.
    InstallChocolatey( [switch] $Latest ) {
        Write-Host "Install Chocolatey" -Foreground yellow
    
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

# $pkg = @{
#     Name = '7z.install'
# }
# $x = new-object Chocolatey 
# $x.Install($pkg)