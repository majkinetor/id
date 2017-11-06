function Show-ServerInfo( [switch]$Raw ) {  
    
    $info = [ordered]@{}
    
    $info.Server = Get-ComputerInfo | select CSName, CSDomain, @{ N='OsTotalVisibleMemorySize (GB)'; E={ [Math]::Ceiling(($_.OsTotalVisibleMemorySize/1MB)) } }, TimeZone, CsNumberOfLogicalProcessors, CsNumberOfProcessors | ConvertTo-HashTable
    $info.Server.Disks = . { get-psdrive -PSProvider FileSystem | select Name, @{ N='Used'; E={[Math]::Ceiling($_.Used/1GB)}}, @{ N='Free'; E={[Math]::Ceiling($_.Free/1GB)}} | % {$a=[ordered]@{}} { $a[$_.Name] = "Used: {0,4} GB  |  Free: {1,4} GB" -f $_.Used, $_.Free }; $a }

    $info.User = [ordered]@{
        Username   = whoami
        IsAdmin    = Test-Admin
        CurrentDir = $pwd    
    }    

    $info.OperatingSystem = Get-CimInstance win32_operatingsystem | select Caption, Version, OSArchitecture, LocalDateTime, LastBootUpTime, OSLanguage | ConvertTo-HashTable

    $c = Get-Culture
    $l = Get-WinSystemLocale
    $info.OperatingSystem.Regional = [ordered]@{ 
        TimeZone = [System.TimeZone]::CurrentTimeZone.StandardName
        Locale  = '{0,-30} {1,10} {2}' -f $l.DisplayName, $l.Name, $l.LCID
        Culture = '{0,-30} {1,10} {2}' -f $c.DisplayName, $c.Name, $c.LCID
        DecimalSeparator = $c.NumberFormat.NumberDecimalSeparator
        GroupSeparator   = $c.NumberFormat.NumberGroupSeparator
        DateTimeFormat   = $c.DateTimeFormat.FullDateTimePattern
    }
    
    $info.Powershell = $PSVersionTable
    
    $util = [ordered]@{}
    if (gcm git -ea 0)     { $util.Git = (git --version) -replace 'git version ' }
    if (gcm choco -ea 0)   { $util.Chocolatey = choco --version }
    if ($util.Count -gt 0) { $info.Utilities = $util }

    if ($Raw) { return $info }
    Write-HashTable $info
}