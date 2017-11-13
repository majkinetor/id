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
       $this.PackagesPath = ''
    }

    Install() {
        $this.load_plugins()
        foreach ($package in $this.Packages.GetEnumerator()) {
            $pkg = $package.Value
            if (!$pkg.Name) { $pkg.Name = $package.Key }
            if (!$pkg.Repo) { throw 'Repo not specified' }

            if ( !$this.Plugins[$pkg.Repo] ) { throw 'Invalid repo' }
            $repo = $this.Plugins[ $pkg.Repo ]

            if ($v=$repo.GetLocalVersion($pkg)) { Write-Host "Already installed: $($pkg.Name) | $v"; continue }

            Write-Host "Installing dependency:" $pkg.Name -ForegroundColor yellow
            $repo.Install( $pkg )
        }
    }

    # private

    load_plugins() {
        ls $PSScriptRoot\..\Plugins -Directory | ? Name -notlike '_*' | % { 
            Write-Verbose "Loading plugin $($_.Name)"
            . ('{0}\{1}.ps1' -f $_.FullName, $_.Name)
            $this.Plugins[$_.Name] = new-object $_
        }
    }
}

$pm = [PackageManager]::new( '..\..\test\packages.ps1' )
$pm.Install()