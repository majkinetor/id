class PackageManager {
    [string] $PackagesPath = "$pwd\packages.ps1"
    [System.Collections.Specialized.OrderedDictionary] $Packages
    [HashTable] $Plugins = @{}

    PackageManager() { [PackageManager]::new($null) }

    PackageManager( [System.Collections.Specialized.OrderedDictionary] $Packages ) {
       $this.Packages =  if ($Packages) { $Packages } else { $this.get_packages() }
    }

    load_plugins() {
        ls $PSScriptRoot\Plugins -Directory | % { 
            Write-Verbose 'Loading plugin' $_.Name
            . $_ 
            $this:Plugins.$_ = new-object $_
        }
    }

    [System.Collections.Specialized.OrderedDictionary] get_packages() {
        if (Test-Path $this.PackagesPath) { & $this.PackagesPath }
        else { 
            Write-Host -BackgroundColor red 'No packages specified and there is no packages.ps1 in the current dir' 
        }
        return $null
    }

    Install() {
        $this.load_plugins()
    }
}

$pm = [PackageManager]::new()
$pm.Install()