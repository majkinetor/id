#
# Write-Host proxy function that adds additional parameters: AnsiColors, TimeFormat, IndentLevel
# AnsiColors switch parameter uses ANSI Escape codes to draw colors (see https://en.wikipedia.org/wiki/ANSI_escape_code)
#
function Write-Host {
    [CmdletBinding(HelpUri='http://go.microsoft.com/fwlink/?LinkID=113426', RemotingCapability='None')]
    param(
        [Parameter(Position=0, ValueFromPipeline=$true, ValueFromRemainingArguments=$true)]
        [System.Object] ${Object},        
        [switch] ${NoNewline},      
        [System.Object] ${Separator},        
        [System.ConsoleColor] ${ForegroundColor},        
        [System.ConsoleColor] ${BackgroundColor},

        [switch] ${AnsiColors} = ($Env:WH_ANSICOLORS -eq 'true'),
        [string] ${TimeFormat} = $Env:WH_TIMEFORMAT,
        [int]    ${IndentLevel} = 0        
    )     
    begin
    {
        $code = @'
        using System;
        using System.Collections.Generic;
        using System.Management.Automation;
        using System.Text;

        public static class AnsiHelper
        {
            public static string GetCode(this ConsoleColor? color, bool forBackground = false)
            {
                string colorCode = color == null ? "Clear" : color.ToString();
                return forBackground ? Background[colorCode] : Foreground[colorCode];
            }
        
            public static Dictionary<string, string> Foreground = new Dictionary<string, string>
            {
                {"Clear",       "\u001B[39m"},
                {"Black",       "\u001B[30m"}, { "DarkGray", "\u001B[90m"},
                {"DarkRed",     "\u001B[31m"}, { "Red",      "\u001B[91m"},
                {"DarkGreen",   "\u001B[32m"}, { "Green",    "\u001B[92m"},
                {"DarkYellow",  "\u001B[33m"}, { "Yellow",   "\u001B[93m"},
                {"DarkBlue",    "\u001B[34m"}, { "Blue",     "\u001B[94m"},
                {"DarkMagenta", "\u001B[35m"}, { "Magenta",  "\u001B[95m"},
                {"DarkCyan",    "\u001B[36m"}, { "Cyan",     "\u001B[96m"},
                {"Gray",        "\u001B[37m"}, { "White",    "\u001B[97m"}
            };
        
            public static Dictionary<string, string> Background = new Dictionary<string, string>
            {
                {"Clear",       "\u001B[49m"},
                {"Black",       "\u001B[40m"}, {"DarkGray", "\u001B[100m"},
                {"DarkRed",     "\u001B[41m"}, {"Red",      "\u001B[101m"},
                {"DarkGreen",   "\u001B[42m"}, {"Green",    "\u001B[102m"},
                {"DarkYellow",  "\u001B[43m"}, {"Yellow",   "\u001B[103m"},
                {"DarkBlue",    "\u001B[44m"}, {"Blue",     "\u001B[104m"},
                {"DarkMagenta", "\u001B[45m"}, {"Magenta",  "\u001B[105m"},
                {"DarkCyan",    "\u001B[46m"}, {"Cyan",     "\u001B[106m"},
                {"Gray",        "\u001B[47m"}, {"White",    "\u001B[107m"},
            };
        
            public static string WriteAnsi(ConsoleColor? foreground, ConsoleColor? background, object value, bool clear = false)
            {
                var output = new StringBuilder();
        
                output.Append(background.GetCode(true));
                output.Append(foreground.GetCode());
                output.Append(LanguagePrimitives.ConvertTo(value, typeof(string)));
                if (clear)
                {
                    output.Append(AnsiHelper.Background["Clear"]);
                    output.Append(AnsiHelper.Foreground["Clear"]);
                }
                return output.ToString();
            }
        }
'@

        'AnsiColors', 'TimeFormat', 'IndentLevel' | % { $PSBoundParameters.Remove($_) | Out-Null }

        if ( $AnsiColors ) { 
            try { [AnsiHelper] | Out-Null } catch { if ($_ -like '*Unable to find type*') { Add-Type -TypeDefinition $code } else {throw $_} }	

            $start = [AnsiHelper]::WriteAnsi( $PSBoundParameters.ForegroundColor, $PSBoundParameters.BackgroundColor, $null)
            $clear = [AnsiHelper]::WriteAnsi( $null, $null, $null )           
            Microsoft.PowerShell.Utility\Write-Host $start -NoNewline

            $hadNoNewLine = $PSBoundParameters.ContainsKey('NoNewline')
            $PSBoundParameters.NoNewline = $true                
        }

        if ($TimeFormat) {         
            $params = @{}   
            $now = (Get-Date).ToString($TimeFormat) + '  '
            if ($ForegroundColor) { $params.ForegroundColor = $ForegroundColor }
            if ($BackgrpundColor) { $params.BackgroundColor = $BackgroundColor }
            Microsoft.PowerShell.Utility\Write-Host $now -NoNewline @params
        }

        if ($IndentLevel) {
            $indent = ' '*$IndentLevel*2
            if ($Object) { $PSBoundParameters['Object'] =  $Object | % { $indent + $_ } }
        }

        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Utility\Write-Host', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }
        $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
        $steppablePipeline.Begin($PSCmdlet)
     }
     
    process {
        $steppablePipeline.Process( $indent + $_ )
    }
     
    end {
        $steppablePipeline.End()
        
        if ( $AnsiColors ) {     
            $params = @{ NoNewLine = $hadNoNewLine }
            Microsoft.PowerShell.Utility\Write-Host $clear @params
        }
    }
}

#Write-Host -BackgroundColor red test test test 1 -NoNewline -AnsiColors
#Write-Host  test test test 2 -Time s -ForegroundColor red
#Write-Host test test test 3

#Write-Host -Fg blue -Ansi 'Processes' -TimeFormat 's'
#ps | % Name | Write-LogMessage -Indent 2
#Write-Host ('-'*50) -Time o -AnsiColors -Fg blue