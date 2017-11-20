class Script {
    
    Script() {}

    [string] GetLocalVersion( [HashTable] $pkg ) {
        if ( $pkg.Test ) { return ($pkg.Test | iex) }
        return ''   
    }

    [Object] Install( [HashTable] $pkg ) {
        if ( $pkg.Script -isnot [ScriptBlock] ) { $pkg.Script = [ScriptBlock]::Create($pkg.Script) }
        $options = $pkg.Options
        return (& $pkg.Script @options)
    }
}