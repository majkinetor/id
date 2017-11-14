class PackageManager {
    [System.Collections.Specialized.OrderedDictionary] $Packages
    [string]    $PackagesPath = "$pwd\packages.ps1"
    [HashTable] $Plugins = @{}
    [Object]    $Tags
    [String[]]  $Names

    hidden [string] $tag_expression

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
        $selectedPackages = $this.SelectPackages()
        foreach ($package in $selectedPackages) {
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
    
    hidden [System.Collections.Specialized.OrderedDictionary] SelectPackages() {
        $res = [ordered]@{}
        foreach ($package in $this.Packages.GetEnumerator()) {
            $pkg = $package.Value
            if ( !$this.IsTagged($pkg) ) { Write-Verbose "Tag exlusion: $($pkg.Name)"; continue }
            if ( !$this.IsNamed($package.Key) ) { Write-Verbose "Name exlusion: $($pkg.Name)"; continue }

            $res[$package.Key] = $pkg
        }
        return $res
    }

    # private

    hidden [bool] IsNamed( $Name ) {
        if ( [string]::IsNullOrEmpty($this.Names) ) { return $true }
        if ( $Name -notin $this.Names ) { return $false }
        return $false
    }

    hidden [bool] IsTagged( $Pkg ) {
        if ($this.Tags -eq $null) { return $true }

        if ($this.Tags -is [array] -or $this.Tags -is [string]) {
            if ($this.Tags -and !(Compare-Object $Pkg.Tags $this.Tags -IncludeEqual | ? SideIndicator -eq '==')) { return $false }
            return $true
        }
        
        if ($this.Tags -is [ScriptBlock]) {     
            if (!$this.tag_expression) {
                $this.tag_expression = $this.Tags
                $this.Tags -split '\(|\)| |!' | ? {$_} | % { if (!$_.StartsWith('-')) {  
                    $this.tag_expression = $this.tag_expression -replace "\b$_\b", "`$t_$_" } 
                }
            }
            $Pkg.Tags | % { Set-Variable "t_$_" $true }
            return iex $this.tag_expression
        }

        return $false
    }

    hidden load_plugins() {
        ls $PSScriptRoot\..\Plugins -Directory | ? Name -notlike '_*' | % { 
            Write-Verbose "Loading plugin $($_.Name)"
            . ('{0}\{1}.ps1' -f $_.FullName, $_.Name)
            $this.Plugins[$_.Name] = new-object $_
        }
    }
}

$pm = [PackageManager]::new( '..\..\test\packages.ps1' )
$pm.Tags = { build -and !develop }
$pm.Install()