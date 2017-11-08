function psgallery( [HashTable] $pkg ) {
    if (!(Get-PSRepository | ? Name -eq 'PSGallery')) { Use-PSGallery } # Very slow and complains without proxy
    #if (!(Get-PackageSource PSGallery -ea 0)) { Use-PSGallery }
    $name = $pkg.Name
    
    $local = gmo $name -ListAvailable | select -First 1
    if ($local) {
        "Already installed: $name|$($local.Version)"
        return
    }

    Write-Host "Installing dependency: $name" -ForegroundColor yellow

    if ($Env:HTTP_PROXY) { $params.Proxy = $Env:HTTP_PROXY } 
    $params = $pkg.Options
    Install-Module $name @params 
}