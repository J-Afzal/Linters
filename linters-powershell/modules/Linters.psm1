$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

<#
    .SYNOPSIS
    Runs all linting checks found in the continuous integration workflow.

    .DESCRIPTION
    To be ran locally from the root of the repository during development to manually check for linting issues.
    Raises an error at the first occurrence of a linting issue.

    .PARAMETER Platform
    Specifies the platform being run on.

    .PARAMETER PathToLintersSubmodulesRoot
    Specifies the path the to the root of the Linters submodule.

    .PARAMETER PathBackToRepositoryRoot
    Specifies the path need to return to the repository root from the Linters submodule.

    .PARAMETER FixClangTidyErrors
    Specifies whether to use clang-tidy to automatically fix any fixable errors.

    .PARAMETER FixClangFormatErrors
    Specifies whether to use clang-format to automatically fix any fixable errors.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module ./submodules/Linters/linters-powershell/Linters.psd1
    Test-CodeUsingAllLinters -PathToLintersSubmodulesRoot "./submodules/Linters" -PathBackToRepositoryRoot "../.." -FixClangTidyErrors -FixClangFormatErrors -Verbose
#>

function Test-CodeUsingAllLinters {

    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateSet("macos-latest", "ubuntu-latest", "windows-latest")]
        [String]
        $Platform,

        [Parameter(Position = 1, Mandatory = $true)]
        [String]
        $PathToLintersSubmodulesRoot,

        [Parameter(Position = 2, Mandatory = $true)]
        [String]
        $PathBackToRepositoryRoot,

        [Parameter(Position = 3, Mandatory = $false)]
        [Switch]
        $FixClangTidyErrors = $false,

        [Parameter(Position = 4, Mandatory = $false)]
        [Switch]
        $FixClangFormatErrors = $false
    )

    Write-Verbose "##[debug]Running Test-CodeUsingAllLinting..."
    Write-Verbose "##[debug]Parameters:"
    Write-Verbose "##[debug]    Platform: $Platform"
    Write-Verbose "##[debug]    PathToLintersSubmodulesRoot: $PathToLintersSubmodulesRoot"
    Write-Verbose "##[debug]    PathBackToRepositoryRoot: $PathBackToRepositoryRoot"
    Write-Verbose "##[debug]    FixClangTidyErrors: $FixClangTidyErrors"
    Write-Verbose "##[debug]    FixClangFormatErrors: $FixClangFormatErrors"

    Test-GitIgnoreFile

    Test-GitAttributesFile

    Test-CSpellConfiguration

    Test-CodeUsingCSpell -PathToLintersSubmodulesRoot $PathToLintersSubmodulesRoot -PathBackToRepositoryRoot $PathBackToRepositoryRoot

    Test-CodeUsingPrettier -PathToLintersSubmodulesRoot $PathToLintersSubmodulesRoot -PathBackToRepositoryRoot $PathBackToRepositoryRoot

    Test-CodeUsingPSScriptAnalyzer -PathToLintersSubmodulesRoot $PathToLintersSubmodulesRoot

    Test-CodeUsingClangTools -Platform $Platform -PathToLintersSubmodulesRoot $PathToLintersSubmodulesRoot -FixClangTidyErrors:$FixClangTidyErrors -FixClangFormatErrors:$FixClangFormatErrors

    Test-DoxygenDocumentation -Verbose

    Write-Output "##[section]All linting tests passed!"
}
