# Chocolatey

Install package from [Chocolatey Gallery](https://chocolatey.org/packages) using `choco.exe` CLI application.

## Options

- `[string[]] $ExtraArgs` - argument list for the choco.exe command line (for example `'-d'`)

## Package options

- `[string] Params`  - `--params` value 
- `[string] Version` - `--version` value 
- `[string] Source`  - `--source` value
- `[string[]] Options` - Array of other options to pass to choco.exe

## Notes

- Set proxy via `$Env:HTTP_PROXY`