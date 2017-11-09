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

    $pm = new-object PluginManager
    if ($pm.Packages.Count -eq 0) { Write-Host 'Empty package file'; return}
    
    if ($Packages) { 
       
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



}


