# Copyright © 2017 Chocolatey Software, Inc.
# Copyright © 2015 - 2017 RealDimensions Software, LLC
# Copyright © 2011 - 2015 RealDimensions Software, LLC & original authors/contributors from https://github.com/chocolatey/chocolatey
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

<#
.SYNOPSIS
Updates the environment variables of the current powershell session with
any environment variable changes that may have occured during a
Chocolatey package install.

.DESCRIPTION
When Chocolatey installs a package, the package author may add or change
certain environment variables that will affect how the application runs
or how it is accessed. Often, these changes are not visible to the
current PowerShell session. This means the user needs to open a new
PowerShell session before these settings take effect which can render
the installed application nonfunctional until that time.

Use the Update-SessionEnvironment command to refresh the current
PowerShell session with all environment settings possibly performed by
Chocolatey package installs.

.NOTES
This method is also added to the user's PowerShell profile as
`refreshenv`. When called as `refreshenv`, the method will provide
additional output.

Preserves `PSModulePath` as set by the process starting in 0.9.10.
#>
function Update-SessionEnvironment {

  function Get-EnvironmentVariableNames([System.EnvironmentVariableTarget] $Scope) {
      # HKCU:\Environment may not exist in all Windows OSes (such as Server Core).
      switch ($Scope) {
        'User'    { Get-Item 'HKCU:\Environment' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Property }
        'Machine' { Get-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' | Select-Object -ExpandProperty Property }
        'Process' { Get-ChildItem Env:\ | Select-Object -ExpandProperty Key }
        default { throw "Unsupported environment scope: $Scope" }
      }
  }

  function Get-EnvironmentVariable {
    [CmdletBinding()]
    [OutputType([string])]
    param(
      [Parameter(Mandatory=$true)][string] $Name,
      [Parameter(Mandatory=$true)][System.EnvironmentVariableTarget] $Scope,
      [Parameter(Mandatory=$false)][switch] $PreserveVariables = $false,
      [parameter(ValueFromRemainingArguments = $true)][Object[]] $ignoredArguments
    )
    
      [string] $MACHINE_ENVIRONMENT_REGISTRY_KEY_NAME = "SYSTEM\CurrentControlSet\Control\Session Manager\Environment\";
      [Microsoft.Win32.RegistryKey] $win32RegistryKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($MACHINE_ENVIRONMENT_REGISTRY_KEY_NAME)
      if ($Scope -eq [System.EnvironmentVariableTarget]::User) {
        [string] $USER_ENVIRONMENT_REGISTRY_KEY_NAME = "Environment";
        [Microsoft.Win32.RegistryKey] $win32RegistryKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($USER_ENVIRONMENT_REGISTRY_KEY_NAME)
      } elseif ($Scope -eq [System.EnvironmentVariableTarget]::Process) {
        return [Environment]::GetEnvironmentVariable($Name, $Scope)
      }
    
      [Microsoft.Win32.RegistryValueOptions] $registryValueOptions = [Microsoft.Win32.RegistryValueOptions]::None
    
      if ($PreserveVariables) {
        Write-Verbose "Choosing not to expand environment names"
        $registryValueOptions = [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
      }
    
      [string] $environmentVariableValue = [string]::Empty
    
      try {
        #Write-Verbose "Getting environment variable $Name"
        if ($win32RegistryKey -ne $null) {
          # Some versions of Windows do not have HKCU:\Environment
          $environmentVariableValue = $win32RegistryKey.GetValue($Name, [string]::Empty, $registryValueOptions)
        }
      } catch {
        Write-Debug "Unable to retrieve the $Name environment variable. Details: $_"
      } finally {
        if ($win32RegistryKey -ne $null) { $win32RegistryKey.Close() }
      }
    
      if ($environmentVariableValue -eq $null -or $environmentVariableValue -eq '') {
        $environmentVariableValue = [Environment]::GetEnvironmentVariable($Name, $Scope)
      }
    
      return $environmentVariableValue
  }  

  Write-Host "Refreshing environment variables from the registry"

  $userName     = $env:USERNAME
  $architecture = $env:PROCESSOR_ARCHITECTURE
  $psModulePath = $env:PSModulePath

  #ordering is important here, $user comes after so we can override $machine
  'Process', 'Machine', 'User' | % {
      $scope = $_
      Get-EnvironmentVariableNames -Scope $scope | % {
          Set-Item "Env:$($_)" -Value (Get-EnvironmentVariable -Scope $scope -Name $_)
      }
    }

  #Path gets special treatment b/c it munges the two together
  $paths = 'Machine', 'User' | % {
      (Get-EnvironmentVariable -Name 'PATH' -Scope $_) -split ';'
    } | select -Unique
  $Env:PATH = $paths -join ';'

  # PSModulePath is almost always updated by process, so we want to preserve it.
  $env:PSModulePath = $psModulePath

  # reset user and architecture
  if ($userName)     { $env:USERNAME = $userName }
  if ($architecture) { $env:PROCESSOR_ARCHITECTURE = $architecture }
}