class PackageManager {
    [string] $PackagesPath = "$pwd\packages.ps1"
    [System.Collections.Specialized.OrderedDictionary] $Packages
    [HashTable] $Plugins = @{}

    PackageManager( [string] $Path ) {
        if (Test-Path $Path) { $Path = Resolve-Path $Path}
        $this.PackagesPath = $Path
        $this.Packages = & $Path
    }

    PackageManager( [System.Collections.Specialized.OrderedDictionary] $Packages ) {
       $this.Packages = $Packages
    }

    load_plugins() {
        ls $PSScriptRoot\..\Plugins -Directory | ? Name -notlike '_*' | % { 
            Write-Verbose "Loading plugin $($_.Name)"
            . ('{0}\{1}.ps1' -f $_.FullName, $_.Name)
            $this.Plugins.$_ = new-object $_
        }
    }

    Install() {
        $this.load_plugins()
    }
}

$pm = [PackageManager]::new( '..\..\test\packages.ps1' )
$pm.Install()