$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

<#
    .SYNOPSIS
    Runs yamllint against all YAML files.

    .DESCRIPTION
    None.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module Yamllint.psd1
    Test-CodeUsingYamllint -Verbose
#>

function Test-CodeUsingYamllint {

    [CmdletBinding()]
    param()

    Write-Verbose "##[debug]Test-CodeUsingYamllint:  Running Test-CodeUsingYamllint..."

    Write-Information "##[command]Test-CodeUsingYamllint:  Retrieving all files to test against yamllint..."
    $filesToTest = Get-FilteredFilePathsToTest -FileExtensionFilterType "Include" -FileExtensionFilterList @("clang-format", "clang-tidy", "yml") -Verbose

    if ($null -eq $filesToTest) {
        Write-Information "##[warning]Test-CodeUsingYamllint:  No files found to lint for yamllint! Please check if this is expected!"
        return
    }

    Write-Verbose "##[debug]Test-CodeUsingYamllint:  Using the following yamllint version..."
    Invoke-ExternalCommand -ExternalCommand "yamllint" -ExternalCommandArguments @("--version") -ThrowError -Verbose

    Write-Information "##[command]Test-CodeUsingYamllint:  Running yamllint..."

    $ExternalCommandArguments = $filesToTest + @("-c", "./.yamllint.yml")

    if (Invoke-ExternalCommand -ExternalCommand "yamllint" -ExternalCommandArguments $ExternalCommandArguments -Verbose) {
        Write-Error "##[error]Test-CodeUsingYamllint:  The above files have yamllint formatting errors!"
    }

    else {
        Write-Information "##[section]Test-CodeUsingYamllint:  All files conform to yamllint standards!"
    }
}
