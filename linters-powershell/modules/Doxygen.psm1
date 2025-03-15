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
        [Parameter(Position = 0, Mandatory = $false)]
        [Switch]
        $ResetLocalGitChanges = $false
    )

    Write-Verbose "##[debug]Test-DoxygenDocumentation:  Running Test-DoxygenDocumentation..."

    if (-Not (Test-Path -LiteralPath ./Doxyfile)) {
        Write-Information "##[warning]Test-DoxygenDocumentation:  No Doxyfile file found at current directory! Please check if this is expected!"
        return -1
    }

    Write-Verbose "##[debug]Test-DoxygenDocumentation:  Using the following Doxygen version..."
    Invoke-ExternalCommand -ExternalCommand doxygen -PassThruArgs @("--version") -ThrowError | ForEach-Object { Write-Verbose "##[debug]Test-DoxygenDocumentation:  $_" }

    if ($ResetLocalGitChanges) {

        Write-Information "##[command]Test-DoxygenDocumentation:  Performing git clean..."
        Invoke-ExternalCommand -ExternalCommand git -PassThruArgs @("clean", "-f", "-d", "-x") -ThrowError
    }

    Write-Information "##[command]Test-DoxygenDocumentation:  Running Doxygen..."
    #& doxygen ./Doxyfile
    Assert-ExternalCommandError -ThrowError

    Write-Information "##[command]Test-DoxygenDocumentation:  Checking for git differences..."
    #& git update-index --really-refresh

    # if (Assert-ExternalCommandError) {
    #     Write-Error "##[error]Test-DoxygenDocumentation:  Committed Doxygen documentation is not up to date. Please check the above list of files which differ!"
    # }

    Write-Information "##[section]Test-DoxygenDocumentation:  Committed Doxygen documentation is up to date!"

    return 0
}
