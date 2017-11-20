class PackageManager {
    [System.Collections.Specialized.OrderedDictionary] $Packages
    [string]    $PackagesPath
    [HashTable] $Plugins = @{}
    [Object]    $Tags
    [String[]]  $Names

    hidden [string] $tag_expression
    hidden [HashTable] $init = @{}

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
        $selectedPackages = $this.SelectPackages()
        foreach ($package in $selectedPackages.GetEnumerator()) {
            $pkg = $package.Value
            if (!$pkg.Name) { $pkg.Name = $package.Key }

            if (!$pkg.Repo) { throw 'Repo not specified' }
            if (!$this.Plugins[$pkg.Repo]) { $this.Plugins[$pkg.Repo] = [PackageManager]::LoadPlugin( $pkg.Repo ) }

            $repo = $this.Plugins[ $pkg.Repo ]
            $repo_name = $repo.GetType().Name

            if (!$this.init.$repo_name) { if ($repo.Init) { $repo.Init(); } $this.init.$repo_name = $true }

            if ($v=$repo.GetLocalVersion($pkg)) { Write-Host "Already installed: $($pkg.Name) | $v"; continue }
        
            Write-Host "Installing dependency:" $pkg.Name -ForegroundColor yellow
            $repo.Install( $pkg )
            Update-SessionEnvironment 6> $null
        }
    }

    [System.Collections.Specialized.OrderedDictionary] SelectPackages() {
        $res = [ordered]@{}
        foreach ($package in $this.Packages.GetEnumerator()) {
            $pkg = $package.Value
            if ( !$this.IsTagged($pkg) ) { Write-Verbose "Tag exlusion: $($package.Key)"; continue }
            if ( !$this.IsNamed($package.Key) ) { Write-Verbose "Name exlusion: $($package.Key)"; continue }

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

    static [Object] LoadPlugin( $Name ) {
        Write-Verbose "Loading plugin $Name"
        $plugin_root = Resolve-Path $PSScriptRoot\..\Plugins
        if (!(Test-Path $plugin_root\$Name\$Name.ps1)) { throw "Plugin not found: $Name" } 
        . ('{1}\{0}\{0}.ps1' -f $Name, $plugin_root)
        return new-object $Name
    }
}