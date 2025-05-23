$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

<#
    .SYNOPSIS
    Runs black against all python files.

    .DESCRIPTION
    None.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module Black.psd1
    Test-CodeUsingBlack -Verbose
#>

function Test-CodeUsingBlack {

    [CmdletBinding()]
    param()

    Write-Verbose "##[debug]Test-CodeUsingBlack:  Running Test-CodeUsingBlack..."

    Write-Information "##[command]Test-CodeUsingBlack:  Retrieving all files to test against black..."
    $filesToTest = Get-FilteredFilePathsToTest -FileExtensionFilterType "Include" -FileExtensionFilterList @("py") -Verbose

    if ($null -eq $filesToTest) {
        Write-Information "##[warning]Test-CodeUsingBlack:  No files found to lint for black! Please check if this is expected!"
        return
    }

    Write-Verbose "##[debug]Test-CodeUsingBlack:  Using the following black version..."
    Invoke-ExternalCommand -ExternalCommand "black" -ExternalCommandArguments @("--version") -ThrowError -Verbose

    Write-Information "##[command]Test-CodeUsingBlack:  Running black..."

    $ExternalCommandArguments = $filesToTest + @("--check")

    if (Invoke-ExternalCommand -ExternalCommand "black" -ExternalCommandArguments $ExternalCommandArguments -Verbose) {
        Write-Error "##[error]Test-CodeUsingBlack:  The above files have black formatting errors!"
    }

    else {
        Write-Information "##[section]Test-CodeUsingBlack:  All files conform to black standards!"
    }
}
