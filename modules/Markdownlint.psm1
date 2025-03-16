$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

<#
    .SYNOPSIS
    Runs markdownlint against all markdown files (with exception of any auto-generated docs).

    .DESCRIPTION
    None.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module Markdownlint.psd1
    Test-CodeUsingMarkdownlint -Verbose
#>

function Test-CodeUsingMarkdownlint {

    [CmdletBinding()]
    param()

    Write-Verbose "##[debug]Test-CodeUsingMarkdownlint:  Running Test-CodeUsingMarkdownlint..."

    Write-Information "##[command]Test-CodeUsingMarkdownlint:  Retrieving all files to test against markdownlint..."
    $filesToTest = Get-FilteredFilePathsToTest -DirectoryFilterType "Exclude" -DirectoryNameFilterList @("docs/html") -FileExtensionFilterType "Include" -FileExtensionFilterList @("md") -Verbose

    if ($null -eq $filesToTest) {
        Write-Information "##[warning]Test-CodeUsingMarkdownlint:  No files found to lint for markdownlint! Please check if this is expected!"
        return
    }

    Write-Verbose "##[debug]Test-CodeUsingMarkdownlint:  Using the following markdownlint version..."
    Invoke-ExternalCommand -ExternalCommand "npx" -ExternalCommandArguments @("markdownlint-cli", "--version") -ThrowError -Verbose

    Write-Information "##[command]Test-CodeUsingMarkdownlint:  Running markdownlint..."

    $ExternalCommandArguments = @("markdownlint-cli") + $filesToTest + @("--config", "./.markdownlint.yml")

    if (Invoke-ExternalCommand -ExternalCommand "npx" -ExternalCommandArguments $ExternalCommandArguments -Verbose) {
        Write-Error "##[error]Test-CodeUsingMarkdownlint:  The above files have markdownlint formatting errors!"
    }

    else {
        Write-Information "##[section]Test-CodeUsingMarkdownlint:  All files conform to markdownlint standards!"
    }
}
