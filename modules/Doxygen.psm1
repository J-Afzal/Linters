$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

<#
    .SYNOPSIS
    Checks that the committed Doxygen documentation is up to date.

    .DESCRIPTION
    Assumes Doxygen is already installed.

    .PARAMETER ResetLocalGitChanges
    Specifies whether to reset local git changes before comparing for Doxygen documentation git differences.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module Doxygen.psd1 -Force
    Test-DoxygenDocumentation -ResetLocalGitChanges -Verbose
#>

function Test-DoxygenDocumentation {

    [CmdletBinding()]
    [OutputType([Int32])]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateSet("macos-latest", "ubuntu-latest", "windows-latest")]
        [String]
        $Platform,

        [Parameter(Position = 1, Mandatory = $false)]
        [Switch]
        $ResetLocalGitChanges = $false
    )

    Write-Verbose "##[debug]Test-DoxygenDocumentation:  Running Test-DoxygenDocumentation..."
    Write-Verbose "##[debug]Test-DoxygenDocumentation:  Parameters:"
    Write-Verbose "##[debug]Test-DoxygenDocumentation:      Platform            : $Platform"
    Write-Verbose "##[debug]Test-DoxygenDocumentation:      ResetLocalGitChanges: $ResetLocalGitChanges"

    # No idea why but other platforms always result in a diff.
    if ($Platform -ne "macos-latest") {
        Write-Information "##[section]The platform '$Platform' is not supported!"
        return
    }

    if (-Not (Test-Path -LiteralPath ./Doxyfile)) {
        Write-Information "##[warning]Test-DoxygenDocumentation:  No Doxyfile file found at current directory! Please check if this is expected!"
        return
    }

    Write-Verbose "##[debug]Test-DoxygenDocumentation:  Using the following Doxygen version..."
    Invoke-ExternalCommand -ExternalCommand "doxygen" -ExternalCommandArguments @("--version") -ThrowError -Verbose | ForEach-Object { Write-Verbose "##[debug]Test-DoxygenDocumentation:  $_" }

    if ($ResetLocalGitChanges) {

        Write-Information "##[command]Test-DoxygenDocumentation:  Performing git clean..."
        Invoke-ExternalCommand -ExternalCommand "git" -ExternalCommandArguments @("clean", "-f", "-d", "-x") -ThrowError -Verbose
    }

    Write-Information "##[command]Test-DoxygenDocumentation:  Running Doxygen..."
    Invoke-ExternalCommand -ExternalCommand doxygen -ExternalCommandArguments @("./Doxyfile") -ThrowError -Verbose

    Write-Information "##[command]Test-DoxygenDocumentation:  Checking for git differences..."

    if (Invoke-ExternalCommand -ExternalCommand "git" -ExternalCommandArguments @("update-index", "--really-refresh") -Verbose) {
        Write-Error "##[error]Test-DoxygenDocumentation:  Committed Doxygen documentation is not up to date. Please check the above list of files which differ!"
    }

    Write-Information "##[section]Test-DoxygenDocumentation:  Committed Doxygen documentation is up to date!"
}
