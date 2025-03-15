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

    .PARAMETER FixClangTidyErrors
    Specifies whether to use clang-tidy to automatically fix any fixable errors.

    .PARAMETER FixClangFormatErrors
    Specifies whether to use clang-format to automatically fix any fixable errors.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module AllLinters.psd1
    Test-CodeUsingAllLinters -FixClangTidyErrors -FixClangFormatErrors -Verbose
#>

function Test-CodeUsingAllLinters {

    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateSet("macos-latest", "ubuntu-latest", "windows-latest")]
        [String]
        $Platform,

        [Parameter(Position = 1, Mandatory = $false)]
        [Switch]
        $FixClangTidyErrors = $false,

        [Parameter(Position = 2, Mandatory = $false)]
        [Switch]
        $FixClangFormatErrors = $false
    )

    Write-Verbose "##[debug]Test-CodeUsingAllLinting:  Running Test-CodeUsingAllLinting..."
    Write-Verbose "##[debug]Test-CodeUsingAllLinting:  Parameters:"
    Write-Verbose "##[debug]Test-CodeUsingAllLinting:      Platform                   : $Platform"
    Write-Verbose "##[debug]Test-CodeUsingAllLinting:      FixClangTidyErrors         : $FixClangTidyErrors"
    Write-Verbose "##[debug]Test-CodeUsingAllLinting:      FixClangFormatErrors       : $FixClangFormatErrors"

    Test-GitIgnoreFile -Verbose

    Test-GitAttributesFile -Verbose

    Test-CSpellConfiguration -Verbose

    Test-CodeUsingCSpell -Verbose

    Test-CodeUsingPrettier -Verbose

    Test-CodeUsingPSScriptAnalyzer -Verbose

    Test-CodeUsingClangFormat -Platform $Platform -FixClangFormatErrors:$FixClangFormatErrors -Verbose

    Test-CodeUsingClangTidy -Platform $Platform -FixClangTidyErrors:$FixClangTidyErrors -Verbose

    Test-DoxygenDocumentation -Platform $Platform -Verbose

    Write-Information "##[section]Test-CodeUsingAllLinting:  All linting tests passed!"
}
