function chocolatey( [HashTable] $pkg ) {
    if (!(gcm choco.exe -ea 0)) { Use-Chocolatey }

    if (!$script:chocolatey_list) { 
        Write-Verbose 'Get local chocolatey packages'
        $script:chocolatey_list = choco list --local-only --limit-output
    }
    
    $name = $pkg.Name
    if ($l = $script:chocolatey_list -match "^$name\|") { "Already installed: $l"; return }

    Write-Host "Installing dependency: $name" -ForegroundColor yellow

    $params = @(
        'install'
        '--yes'
        $name
        if ( $pkg.Params  ) { '--params',  $pkg.Params  }
        if ( $pkg.Version ) { '--version', $pkg.Version }  
        if ( $pkg.Source  ) { '--source',  $pkg.Source  }          
    ) + $pkg.Options

    
    Write-Host "choco.exe $params"
    & choco.exe $params
    if ($LASTEXITCODE) { throw "Failed to install dependency '$name' - exit code $LastExitCode"}
}
