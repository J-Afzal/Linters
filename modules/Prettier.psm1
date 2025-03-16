$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

<#
    .SYNOPSIS
    Runs prettier against all JSON, markdown and YAML files (with exception of the package-lock.json file).

    .DESCRIPTION
    None.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module Prettier.psd1
    Test-CodeUsingPrettier -Verbose
#>

function Test-CodeUsingPrettier {

    [CmdletBinding()]
    param()

    Write-Verbose "##[debug]Test-CodeUsingPrettier:  Running Test-CodeUsingPrettier..."

    Write-Information "##[command]Test-CodeUsingPrettier:  Retrieving all files to test against prettier..."
    $filesToTest = Get-FilteredFilePathsToTest -FileNameFilterType "Exclude" -FileNameFilterList @("package-lock") -FileExtensionFilterType "Include" -FileExtensionFilterList @("clang-format", "clang-tidy", "json", "md", "yml") -Verbose

    if ($null -eq $filesToTest) {
        Write-Information "##[warning]Test-CodeUsingPrettier:  No files found to lint for prettier! Please check if this is expected!"
        return
    }

    Write-Verbose "##[debug]Test-CodeUsingPrettier:  Using the following prettier version..."
    Invoke-ExternalCommand -ExternalCommand "npx" -ExternalCommandArguments @("prettier", "--version") -ThrowError -Verbose

    Write-Information "##[command]Test-CodeUsingPrettier:  Running prettier..."

    $ExternalCommandArguments = @("prettier") + $filesToTest + @("--list-different")

    if (Invoke-ExternalCommand -ExternalCommand "npx" -ExternalCommandArguments $ExternalCommandArguments -Verbose) {
        Write-Error "##[error]Test-CodeUsingPrettier:  The above files have prettier formatting errors!"
    }

    else {
        Write-Information "##[section]Test-CodeUsingPrettier:  All files conform to prettier standards!"
    }
}
