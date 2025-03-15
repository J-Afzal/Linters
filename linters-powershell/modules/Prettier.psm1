$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

<#
    .SYNOPSIS
    Runs prettier against all JSON, markdown and YAML files (with exception of the package-lock.json file).

    .DESCRIPTION
    Raises an error if linting errors found.

    .PARAMETER PathToLintersSubmodulesRoot
    Specifies the path the to the root of the Linters submodule.

    .PARAMETER PathBackToRepositoryRoot
    Specifies the path need to return to the repository root from the Linters submodule.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module ./submodules/Linters/linters-powershell/Linters.psd1
    Test-CodeUsingPrettier -PathToLintersSubmodulesRoot "./submodules/Linters" -PathBackToRepositoryRoot "../.." -Verbose
#>

function Test-CodeUsingPrettier {

    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [String]
        $PathToLintersSubmodulesRoot,

        [Parameter(Position = 1, Mandatory = $true)]
        [String]
        $PathBackToRepositoryRoot
    )

    Write-Verbose "##[debug]Running Test-CodeUsingPrettier..."
    Write-Verbose "##[debug]Parameters:"
    Write-Verbose "##[debug]    PathToLintersSubmodulesRoot: $PathToLintersSubmodulesRoot"
    Write-Verbose "##[debug]    PathBackToRepositoryRoot: $PathBackToRepositoryRoot"

    Write-Information "##[command]Retrieving all files to test against prettier..."
    $filesToTest = Get-FilteredFilePathsToTest -FileNameFilterType "Exclude" -FileNameFilterList @("package-lock") -FileExtensionFilterType "Include" -FileExtensionFilterList @("clang-format", "clang-tidy", "json", "md", "yml")

    if ($null -eq $filesToTest) {
        Write-Information "##[warning]No files found to lint for prettier! Please check if this is expected!"
        return
    }

    Write-Information "##[command]Changing directory to Linters submodule folder..."
    Set-Location -LiteralPath $PathToLintersSubmodulesRoot

    try {
        Write-Verbose "##[debug]Using the following prettier version..."
        (npx prettier --version) | ForEach-Object { Write-Verbose "##[debug]$_" }

        Write-Information "##[command]Running prettier..."

        $errors = @(npx -c "prettier $($filesToTest | ForEach-Object { "$PathBackToRepositoryRoot/$_" }) --list-different")

        if ($errors.Length -gt 0) {
            Write-Information "##[error]The following files differ from Prettier formatting:"
            $errors | ForEach-Object { Write-Information "##[error]    $($_.Substring($PathBackToRepositoryRoot.Length + 1))" }
            Write-Error "##[error]Please resolve the above errors!"
        }
    }

    catch {
        throw
    }

    finally {
        Write-Information "##[command]Changing directory to repository root..."
        Set-Location -LiteralPath $PathBackToRepositoryRoot
    }

    Write-Output "##[section]All files conform to prettier standards!"
}
