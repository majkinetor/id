[ordered]@{
    # '7zip'    = @{ Repo = 'Chocolatey'; Tags = 'build';  }
    # 'less'    = @{ Repo = 'Chocolatey'; Tags = 'develop', 'build' }
    # 'pester'  = @{ Repo = 'PSGallery' ; Tags = 'test' }
    
    'test script' = @{
        Repo = 'Script'
        #Test = {}
        Script = { param($Dir) Write-Host 'Running script'; ls $Dir}
        Options = @{ dir = 'C:\1'}
    }
}