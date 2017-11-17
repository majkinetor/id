class Script {
    
    Script() {}

    [string] GetLocalVersion( [HashTable] $pkg ) {
        if ( $pkg.Test ) { return ($pkg.Test | iex) }
        return ''   
    }

    Install( [HashTable] $pkg ) {
        if ( $pkg.Script -isnot [ScriptBlock] ) { $pkg.Script = [ScriptBlock]::Create($pkg.Script) }
        $options = $pkg.Options
        & $pkg.Script @options *>&1 | Write-Host
    }
}