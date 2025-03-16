$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

<#
    .SYNOPSIS
    Runs PSScriptAnalyzer against all PowerShell files.

    .DESCRIPTION
    None.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module PSScriptAnalyzer.psd1
    Test-CodeUsingPSScriptAnalyzer -Verbose
#>

function Test-CodeUsingPSScriptAnalyzer {

    [CmdletBinding()]
    param()

    Write-Verbose "##[debug]Test-CodeUsingPSScriptAnalyzer:  Running Test-CodeUsingPSScriptAnalyzer..."

    Write-Information "##[command]Test-CodeUsingPSScriptAnalyzer:  Retrieving all files to test against PSScriptAnalyzer..."
    $filesToTest = Get-FilteredFilePathsToTest -FileExtensionFilterType "Include" -FileExtensionFilterList @("ps1", "psd1", "psm1") -Verbose

    if ($null -eq $filesToTest) {
        Write-Information "##[warning]Test-CodeUsingPSScriptAnalyzer:  No files found to lint for PSScriptAnalyzer! Please check if this is expected!"
        return
    }

    $filesWithErrors = @()

    foreach ($file in $filesToTest) {

        Write-Information "##[command]Test-CodeUsingPSScriptAnalyzer:  Running PSScriptAnalyzer against '$file'..."

        $output = Invoke-ScriptAnalyzer -Path $file -Settings ./PSScriptAnalyzerSettings.psd1

        if ($output.Length -gt 0) {
            $filesWithErrors += $file
        }
    }

    if ($filesWithErrors.Length -gt 0) {
        Write-Information "##[error]Test-CodeUsingPSScriptAnalyzer:  The following files have PSScriptAnalyzer errors:"
        $filesWithErrors | ForEach-Object { Write-Information "##[error]Test-CodeUsingPSScriptAnalyzer:  $_" }
        Write-Error "##[error]Test-CodeUsingPSScriptAnalyzer:  Please resolve the above errors!"
    }

    else {
        Write-Information "##[section]Test-CodeUsingPSScriptAnalyzer:  All files conform to PSScriptAnalyzer standards!"
    }
}
