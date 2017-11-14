function Install-Dependencies {
    param(
        # Package description:
        #   [string]  - path to ps1 files with packages
        #   [ordered] - ordered hashtable with packages
        $Packages = 'packages.ps1',
        
        # String[] or ScriptBlock
        #  - String[]:      Install only packages that contain at least 1 of the tags in the list
        #  - ScriptBlock:   Tag expression, for example { build -and (docs -or service) }      
        $Tags, 

        # Install only packages that match provided names
        [string[]] $Names 
    )

    $pm = [PackageManager]::new( $Packages )
    $pm.Tags  = $Tags
    $pm.Names = $Names
    
    $selected = $pm.SelectPackages()
    Write-Host "Selecting" ("{0} of {1}" -f $selected.Keys.Count, $pm.Packages.Keys.Count) "dependencies" -ForegroundColor green
    if ($Env:HTTP_PROXY) {  Write-Host  "Proxy:" $Env:HTTP_PROXY -ForegroundColor green }
    Write-Host "  Tags:      $Tags" -ForegroundColor green
    Write-Host "  Packages:  $($selected.Keys)" -ForegroundColor green
    Write-Host

    $pm.Install() 
    # $b = if ( $pkg.Test ) { $pkg.Test | iex } else { $false }
}