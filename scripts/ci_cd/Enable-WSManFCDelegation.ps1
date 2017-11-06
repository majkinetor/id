<#
.SYNOPSIS
    Allow delegating fresh credentials to the given target

.DESCRIPTION
    This function sets policies AllowFreshCredentials and AllowFreshCredentialsWhenNTLMOnly.
    The native Enable-WSManCredSSP function does set AllowFresh policy only which may not be enough.
#>
function Enable-WSManFCDelegation( $ComputerName ) {

    if ( !$ComputerName ) {
        Write-Host "Computer name not specified, current computer domain will be used"
        $domain = Get-WmiObject Win32_ComputerSystem | % Domain
        if (!$domain -or ($domain -eq 'WORKGROUP')) { throw 'Invalid domain: $domain'}
        $ComputerName = "wsman/*.$domain"
    } else { $ComputerName = "wsman/$ComputerName" }

    $current = Get-WSManCredSSP
    if ($current -like "*$ComputerName*") { return $current }

    $key      = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation'
    $policies = 'AllowFreshCredentials', 'AllowFreshCredentialsWhenNTLMOnly'


    & { 
        if (!(Test-Path $key)) { mkdir $key }

        $policies | % { 
            $name = $_
            New-ItemProperty -Path $key -Name $name                     -Value 1 -Force
            New-ItemProperty -Path $key -Name ConcatenateDefaults_$name -Value 1 -Force
            $policy_key = Join-Path $key $name
            
            if (!(Test-Path $policy_key)) { mkdir $policy_key }
            $item = gi $policy_key | % Property | Measure -Maximum | % Maximum
            if (!$item) { $item = 1 }
            $current_items = gi $policy_key | % Property | % { gp $policy_key $_ | % $_ }
            if ($current_items -notcontains $ComputerName) {
                New-ItemProperty -Path $policy_key -Name $item -Value $ComputerName -Force
            }
        }
    } | Out-Null

    # This function doesn't set AllowFreshCredentialsWhenNTLMOnly 
    Enable-WSManCredSSP -Role client -DelegateComputer ($ComputerName -replace '^wsman/') -Force 

    Get-WSManCredSSP
}