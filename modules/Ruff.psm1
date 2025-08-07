$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

<#
    .SYNOPSIS
    Runs ruff against all python files.

    .DESCRIPTION
    None.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module Ruff.psd1
    Test-CodeUsingRuff -Verbose
#>

function Test-CodeUsingRuff {

    [CmdletBinding()]
    param()

    Write-Verbose "##[debug]Test-CodeUsingRuff:  Running Test-CodeUsingRuff..."

    Write-Information "##[command]Test-CodeUsingRuff:  Retrieving all files to test against ruff..."
    $filesToTest = Get-FilteredFilePathsToTest -FileExtensionFilterType "Include" -FileExtensionFilterList @("py") -Verbose

    if ($null -eq $filesToTest) {
        Write-Information "##[warning]Test-CodeUsingRuff:  No files found to lint for ruff! Please check if this is expected!"
        return
    }

    Write-Verbose "##[debug]Test-CodeUsingRuff:  Using the following ruff version..."
    Invoke-ExternalCommand -ExternalCommand "uv" -ExternalCommandArguments @("run", "ruff", "--version") -ThrowError -Verbose

    Write-Information "##[command]Test-CodeUsingRuff:  Running ruff..."

    $ExternalCommandArguments = @("run", "ruff", "check") + $filesToTest

    if (Invoke-ExternalCommand -ExternalCommand "uv" -ExternalCommandArguments $ExternalCommandArguments -Verbose) {
        Write-Error "##[error]Test-CodeUsingRuff:  The above files have ruff formatting errors!"
    }

    else {
        Write-Information "##[section]Test-CodeUsingRuff:  All files conform to ruff standards!"
    }
}
