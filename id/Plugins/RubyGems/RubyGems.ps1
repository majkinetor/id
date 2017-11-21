class RubyGems {

    [string[]] $ExtraArgs = $Env:ID_RubyGem_ExtraArgs
    
    RubyGems() {}

    [string] GetLocalVersion( [HashTable] $pkg ) {
        return ( (gem.cmd list -e $pkg.Name) -split "`n" | select -Last 1 )
    }

    Install( [HashTable] $pkg ) {
        $params = @(
            'install'
            $pkg.Name
            '--no-ri'
            '--no-rdoc'
            if ( $pkg.Version ) { '--version', $pkg.Version }  
            if ( $pkg.Force   ) { '--force' }
        ) + $pkg.Options + $pkg.ExtraArgs
        & gem.cmd $params
    }

    Init() {
        if (!( gcm gem.cmd -ea 0)) { [RubyGems]::InstallRepository() }
    }

    static InstallRepository() {
        $repo = [PackageManager]::LoadPlugin( 'Chocolatey' )
        $repo.Install( @{ Name = 'ruby' })
    }
}