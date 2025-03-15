$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

<#
    .SYNOPSIS
    Runs PSScriptAnalyzer against all PowerShell files.

    .DESCRIPTION
    Raises an error if linting errors found.

    .PARAMETER PathToLintersSubmodulesRoot
    Specifies the path the to the root of the Linters submodule.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module ./submodules/Linters/linters-powershell/Linters.psd1
    Test-CodeUsingPSScriptAnalyzer -PathToLintersSubmodulesRoot "./submodules/Linters" -Verbose
#>

function Test-CodeUsingPSScriptAnalyzer {

    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [String]
        $PathToLintersSubmodulesRoot
    )

    Write-Verbose "##[debug]Running Test-CodeUsingPSScriptAnalyzer..."
    Write-Verbose "##[debug]Parameters:"
    Write-Verbose "##[debug]    PathToLintersSubmodulesRoot: $PathToLintersSubmodulesRoot"

    Write-Information "##[command]Retrieving all files to test against PSScriptAnalyzer..."
    $filesToTest = Get-FilteredFilePathsToTest -FileExtensionFilterType "Include" -FileExtensionFilterList @("ps1", "psd1", "psm1")

    if ($null -eq $filesToTest) {
        Write-Information "##[warning]No files found to lint for PSScriptAnalyzer! Please check if this is expected!"
        return
    }

    $filesWithErrors = @()

    foreach ($file in $filesToTest) {

        Write-Information "##[command]Running PSScriptAnalyzer against '$file'..."

        $output = Invoke-ScriptAnalyzer -Path $file -Settings "$PathToLintersSubmodulesRoot/PSScriptAnalyzerSettings.psd1"

        if ($output.Length -gt 0) {
            $filesWithErrors += $file
        }
    }

    if ($filesWithErrors.Length -gt 0) {
        Write-Information "##[error]The following files have PSScriptAnalyzer errors:"
        $filesWithErrors | ForEach-Object { Write-Information "##[error]$_" }
        Write-Error "##[error]Please resolve the above errors!"
    }

    else {
        Write-Output "##[section]All files conform to PSScriptAnalyzer standards!"
    }
}
