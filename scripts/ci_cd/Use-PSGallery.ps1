<#
.SYNOPSIS
    Ensure PSGallery is available

.DESCRIPTION
    Installs PSGallery if it doesn't exist and sets it to trusted repository
#>
function Use-PSGallery {    
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
    
    #Looks like it requires IE proxy ?! It has Proxy argument but doesn't use it.
    # if (((repo).InstallationPolicy -ne 'Trusted')) {  # Setting trust is VERY slow
    #     Write-Host "Setting trust"
    #     Set-PSRepository -Name PSGallery -InstallationPolicy Trusted @proxy    
    # }

    $repo = (repo | select SourceLocation, Trusted | fl * | Out-String).Trim() -split "`n" 
    @("Repository info:`n") + ($repo | % { "  $_" }) | Write-Host
}