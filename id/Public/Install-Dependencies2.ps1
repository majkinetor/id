<#
.SYNOPSIS
    Install dependencies from HashTable description.

.DESCRIPTION
    The function installs dependencies from given HashTable or packages.ps1 script which returns it. 
    Package is defined as item in the HashTable that is itself a HashTable with few mandatory keys.
    
    Package metadata:
    
        Repository - Mandatory, name of the repository. If invalid is used the function throws.
        Name       - The actual package name in the repository. If absent, Name is considered the same as the key.
        Tag        - Contains string array of tags.
        Options    - Passed as aditional parameters to native installers and is Repository specific.
        Test       - Script that returns $true to install the package or $false to mark it as installed.

    Repository specifics:

        Chocolatey
            - Params    (String)            passed to cinst as --params value
            - Version   (String)            passed to cinst as --version value
            - Options   (Array)             passed to cinst
        PSGallery       
            - Options   (HashTable)         passed to Install-Module
        Windows     
            - Options   (HashTable)         passed to Install-WindowsFeature
        Script
            - Script    [ScriptBlock] or
                        [String]            script that is run to install the package
            - Options   (HashTable)         are passed as parameters to given script   
        Pip
            - Options   (HashTable)         passed to pip.exe
            - Version   (String)            passed to pip as --version
            - Force     (Switch)            passed to pip as --force-reinstall
        RubyGems  
            - Options   (HashTable)         passed to gem
            - Version   (String)            passed to gem as --version
            - Force     (Switch)            passed to gem as --force
        VsCode
            - none

.EXAMPLE
    Install-Dependencies -Tags build, runtime

    Look into packages.ps1 in the current dir to get the HashTable. Select only those packages
    that contain tag 'buld' OR tag 'runtime'.
.EXAMPLE
    Install-Dependencies -Tags { build -and runtime }

    Look into packages.ps1 in the current dir to get the HashTable. Select only those packages
    that contain tag 'buld' AND tag 'runtime'
#>
function Install-Dependencies {
    param(
        # Package description
        [System.Collections.Specialized.OrderedDictionary] $Packages,
        
        # String[] or ScriptBlock
        #  - String[]:      Install only packages that contain at least 1 of the tags in the list
        #  - ScriptBlock:   Tag expression, for example { build -and (docs -or service) }      
        $Tags, 

        # Install only packages that match provided names
        [string[]] $Names
    ) 
    


    function windows( [HashTable] $pkg ) {
        $name = $pkg.Name

        $f = Get-WindowsFeature $name
        if (!$f) { throw "Windows feature '$name' cant be found" }
        if ($f.Installed) { "Already installed: $name"; return }
        
        Write-Host "Installing dependency: $name" -ForegroundColor yellow
        $params = $pkg.Options
        Install-WindowsFeature -Name $name @params -Verbose
    }

    function rubygems( [HashTable] $pkg) {
        $name = $pkg.Name
        $p = (gem list -e $name) -split "`n" | select -Last 1
        if ($p) { 
            $version =  $p -split '[()]' | select -Last 1 -Skip 1
            "Already installed: $name|$($version)"
            return
        }

        $params = @(
            'install'
            $name
            '--no-ri'
            '--no-rdoc'
            if ( $pkg.Version ) { '--version', $pkg.Version }  
            if ( $pkg.Force   ) { '--force' }
        ) + $pkg.Options
        
        Write-Host "Installing dependency: $name" -ForegroundColor yellow
        & gem $params
    }

    function pip( [HashTable] $pkg) {
        $name = $pkg.Name

        if (!$script:pip_list) { 
            Write-Verbose 'Get local pip packages'
            $script:pip_list = pip.exe list --format=legacy
        }
        $p = $script:pip_list | ? { $_ -match "^$name \((.+?)\)" }
        if ($p) {
            $version = $Matches[1]
            "Already installed: $name|$($version)" 
            return
        }

        $params = @(
            'install'
            $name
            if ( $pkg.Version ) { '--version', $pkg.Version }  
            if ( $pkg.Force   ) { '--force-reinstall' }
        ) + $pkg.Options
        
        Write-Host "Installing dependency: $name" -ForegroundColor yellow
        & pip.exe $params
    }

    function script( [HashTable] $pkg ) {
        $name = $pkg.Name
        Write-Host "Installing dependency: $name" -ForegroundColor yellow

        if ( $pkg.Script -isnot [ScriptBlock] ) { $pkg.Script = [ScriptBlock]::Create($pkg.Script) }
        $options = $pkg.Options
        & $pkg.Script @options
    }

    function vscode( [HashTable] $pkg ) {

        if (!$script:vscode_list) { 
            Write-Verbose 'Get local chocolatey packages'
            $script:vscode_list = code --list-extensions --show-versions
        }
        
        $name = $pkg.Name
        $p = $script:vscode_list -like "$name@*"
        if ($p) { 
            "Already installed: $($p.Replace('@', '|'))"
            return
        }

        Write-Host "Installing dependency: $name" -ForegroundColor yellow
        code --install-extension $name
    }

    function is_tagged( $Pkg ) {
        if ($Tags -is [array] -or $Tags -is [string]) {
            if ($Tags -and !(Compare-Object $Pkg.Tags $Tags -IncludeEqual | ? SideIndicator -eq '==')) { return $false }
            return $true
        }
        
        if ($Tags -is [ScriptBlock]) {     
            if (!$script:Tag_Expression) {
                $script:Tag_Expression = $Tags
                $Tags -split '\(|\)| |!' | ? {$_} | % { if (!$_.StartsWith('-')) {  
                    $script:Tag_Expression = $script:Tag_Expression -replace "\b$_\b", "`$t_$_" } 
                }
            }
            $Pkg.Tags | % { Set-Variable "t_$_" $true }
            return iex $script:Tag_Expression
        }
    }

    $repos = 'Chocolatey', 'PSGallery', 'Windows', 'Script', 'RubyGems', 'Pip', 'VsCode'
    $script:chocolatey_list = $script:pip_list = $script:vscode_list = $script:Tag_Expression = $null
    
    if (!$Packages) {
        if (Test-Path packages.ps1) { $Packages = & .\packages.ps1 }
        else { 
            Write-Host -BackgroundColor red 'No packages specified and there is no packages.ps1 in the current dir' 
            return
        }
    }
    if (!$Names) { $Names = $Packages.Keys }
 
    $filtered_packages = [ordered]@{}
    foreach( $pkg in $Packages.GetEnumerator() ) {
        $name = if ($pkg.Value.Name) { $pkg.Value.Name } else { $pkg.Key }
        $key_name = $pkg.Key
        $pkg  = $pkg.Value
        $pkg.Name = $name
        if ($repos -notcontains $pkg.Repository) { throw "Invalid repository '$($pkg.Repository)' for package '$name'" }

        if ( ! (is_tagged $pkg) ) {  Write-Verbose "Tag exlusion: $name"; continue  }
    
        if ($key_name -notin $Names) { 
            Write-Verbose "Name exlusion: $name"
            continue 
        }   
        $filtered_packages.$key_name = $pkg
    }

    Write-Host "Requesting installation of" ("{0}/{1}" -f $filtered_packages.Keys.Count, $Packages.Keys.Count) "dependencies:" -ForegroundColor green
    if ($Env:HTTP_PROXY) {  Write-Host  "Proxy:" $Env:HTTP_PROXY -ForegroundColor green }
    Write-Host "Tags: $Tags    Packages: $($filtered_packages.Keys)`n" -ForegroundColor green
    
    foreach( $pkg in $filtered_packages.GetEnumerator() ) { 
        $pkg = $pkg.Value 
        $b = if ( $pkg.Test ) { $pkg.Test | iex } else { $false }    
        if (!$b) {
            & $pkg.Repository $pkg
            Update-SessionEnvironment 6> $null
         } else { "Already installed: $($pkg.Name)" }
    }
}

# cd c:\Work\_trezor\website\next
# Install-Dependencies -Tags { develop -and !docs -or basic } -Verbose