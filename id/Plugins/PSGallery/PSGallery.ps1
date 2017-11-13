class PSGallery
{
    [string[]] $ExtraArgs = @{}
    
    #...

    [string] $init

    PSGallery() { }

    # Returns version
    [string] Install([HashTable] $pkg) {
        function init() {
            #if (!(Get-PackageSource PSGallery -ea 0)) { InstallPSGallery } #faster, not sure if works always
            if (!(Get-PSRepository | ? Name -eq 'PSGallery')) { # Very slow and complains without proxy
                 InstallPSGallery 
            }
            $this.init = $true
        }

        if (!$this.init) { init }

        $name = $pkg.Name
        
        $local = gmo $name -ListAvailable | select -First 1
        if ($local) { return $local.Version }
    
        Write-Host "Installing dependency: $name" -ForegroundColor yellow
    
        $params = if ($pkg.Options) { $pkg.Options } else { @{} }
        if ($Env:HTTP_PROXY) { $params.Proxy = $Env:HTTP_PROXY }
        Install-Module $name @params
        return ''
    }

    # Installs PSGallery if it doesn't exist and sets it to trusted repository
    InstallPSGallery() {    
        function repo { Get-PSRepository | ? Name -eq 'PSGallery' } # Using -Name parameter is VERY slow. Without IE proxy gives warnings
        #function repo { Get-PackageSource PSGallery }

        Write-Host "Use PSGallery" -Foreground yellow

        $proxy = @{}
        if ($env:http_proxy) { 
            Write-Host 'Using proxy:' $env:http_proxy
            $proxy.Proxy = $env:http_proxy 
        } else { Write-Host 'Not using proxy'}
        
        
        if (!(repo)) { 
            if (!(Get-PackageProvider Nuget -ea 0)) { Install-PackageProvider NuGet -MinimumVersion 2.8.5.201 -Force @proxy }
            Register-PSRepository -Default @proxy  
        }
        
        #Looks like it requires IE proxy ?! It has Proxy argument but doesn't seem to use it.
        # if (((repo).InstallationPolicy -ne 'Trusted')) {  # Setting trust is VERY slow
        #     Write-Host "Setting trust"
        #     Set-PSRepository -Name PSGallery -InstallationPolicy Trusted @proxy    
        # }

        $repo = (repo | select SourceLocation, Trusted | fl * | Out-String).Trim() -split "`n" 
        @("Repository info:`n") + ($repo | % { "  $_" }) | Write-Host
    }
}

$pkg = @{
    Name = 'invoke-build'
}
$x = new-object PSGallery 
$x.Install($pkg)