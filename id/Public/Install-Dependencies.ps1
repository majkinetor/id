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

   
    $pm = [PackageManager]::new( '..\..\test\packages.ps1' )
    $pm.Install() 
    
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


