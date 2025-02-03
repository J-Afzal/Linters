$ErrorActionPreference = "Stop"

<#
    .SYNOPSIS
    Installs all linting dependencies needed to run the lint job within GitHub workflows.

    .DESCRIPTION
    This function only installs the linting dependencies not found on the GitHub workflow platforms.
    Ideally Cpp linting dependencies would also be installed here but due to installation complexities they are done within the
    respective Cpp linting step.

    .PARAMETER PathToLintersSubmodulesRoot
    Specifies the path the to the root of the Linters submodule.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module ./submodules/Linters/linters-powershell/Linters.psd1
    Install-LintingDependencies -PathToLintersSubmodulesRoot "." -Verbose
#>

function Install-LintingDependencies {

    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=$true)]
        [string]
        $PathToLintersSubmodulesRoot
    )

    Write-Output "##[section]Running Install-LintingDependencies..."
    Write-Verbose "##[debug]Parameters:"
    Write-Verbose "##[debug]    PathToLintersSubmodulesRoot: $PathToLintersSubmodulesRoot"

    Set-Location -Path $PathToLintersSubmodulesRoot

    Write-Output "##[section]Installing npm dependencies..."

    npm install

    Assert-ExternalCommandError -ThrowError

    Write-Output "##[section]All linting dependencies installed!"
}
