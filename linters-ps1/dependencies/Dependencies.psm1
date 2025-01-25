$ErrorActionPreference = "Stop"

<#
    .SYNOPSIS
    Installs all linting dependencies needed to run the lint job within GitHub workflows.

    .DESCRIPTION
    This function only installs the linting dependencies not found on the GitHub workflow platforms.
    Clang tools are not installed here and instead are installed in the function that uses them.

    .INPUTS
    [string] Platform. The current GitHub workflow platform.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module ./linters-ps1/Linters.psd1
    Install-LintingDependencies -PathToLintersSubmodulesRoot "." -Verbose
#>

function Install-LintingDependencies {

    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory=$true)]
        [string]
        $PathToLintersSubmodulesRoot
    )

    Write-Output "##[section]Running Install-LintingDependencies..."
    Write-Verbose "##[debug]Parameters:"
    Write-Verbose "##[debug]    PathToLintersSubmodulesRoot: $PathToLintersSubmodulesRoot"

    Write-Output "##[section]Installing npm dependencies..."

    npm install

    Assert-ExternalCommandError -ThrowError

    Write-Verbose "##[debug]Finished installing npm dependencies."

    Write-Output "##[section]All linting dependencies installed!"
}
