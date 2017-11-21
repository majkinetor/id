[ordered]@{
    '7zip'    = @{ Repo = 'Chocolatey'; Tags = 'build'; Force = $true }
    'less'    = @{ Repo = 'Chocolatey'; Tags = 'develop', 'build' }
    'pester'  = @{ Repo = 'PSGallery' ; Tags = 'test' }
    
    'test script' = @{
        Repo = 'Script'
        Test = { 1 }
        Script = { param($Dir) Write-Host 'Running script'; ipconfig }
        Options = @{ dir = 'C:\1'}
    }

    'bundler' = @{ Repo = 'RubyGems' }
}
