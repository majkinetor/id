class PSGallery
{
    [HashTable] $ExtraArgs = @{}
    
    #...

    [string] $init

    PSGallery() { }

    [string] GetLocalVersion( $pkg ) {
        $local = gmo $pkg.Name -ListAvailable | select -First 1
        return $local.Version
    }

    # Returns version
    Install([HashTable] $pkg) {
        $params = if ($pkg.Options) { $pkg.Options } else { @{} }
        $params += $this.ExtraArgs
        if ($Env:HTTP_PROXY) { $params.Proxy = $Env:HTTP_PROXY }
        Install-Module $pkg.Name @params
    }

    Init() {
        if ( !$this.psrepo() ) { [PSGallery]::InstallRepository() }
    }

    hidden [bool] psrepo() {
        Get-PSRepository | ? Name -eq 'PSGallery'  # Using -Name parameter is VERY slow. Without IE proxy gives warnings
        #Get-PackageSource PSGallery 
    }

    # Installs PSGallery if it doesn't exist and sets it to trusted repository
    static InstallRepository() {
        Write-Host "Installing repository: PSGallery" -Foreground yellow

        $proxy = @{}
        if ($env:http_proxy) { 
            Write-Host 'Using proxy:' $env:http_proxy
            $proxy.Proxy = $env:http_proxy 
        } else { Write-Host 'Not using proxy'}

        if (!(Get-PackageProvider Nuget -ea 0)) { Install-PackageProvider NuGet -MinimumVersion 2.8.5.201 -Force @proxy }
        Register-PSRepository -Default @proxy  
         
        #Looks like it requires IE proxy ?! It has Proxy argument but doesn't seem to use it.
        # if (((repo).InstallationPolicy -ne 'Trusted')) {  # Setting trust is VERY slow
        #     Write-Host "Setting trust"
        #     Set-PSRepository -Name PSGallery -InstallationPolicy Trusted @proxy    
        # }

        $repo = ( $this.psrepo() | select SourceLocation, Trusted | fl * | Out-String).Trim() -split "`n" 
        @("Repository info:`n") + ($repo | % { "  $_" }) | Write-Host
    }
}