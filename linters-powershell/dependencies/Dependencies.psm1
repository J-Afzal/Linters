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
    Import-Module ./submodules/Linters/linters-powershell/Linters.psd1
    Install-LintingDependencies -PathToLintersSubmodulesRoot "." -Platform "macos-latest" -InstallCppDependencies -Verbose
#>

function Install-LintingDependencies {

    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory=$true)]
        [string]
        $PathToLintersSubmodulesRoot,

        [Parameter(Position=0, Mandatory=$true)]
        [string]
        $Platform,

        [Parameter(Position=0, Mandatory=$true)]
        [switch]
        $InstallCppDependencies
    )

    Write-Output "##[section]Running Install-LintingDependencies..."
    Write-Verbose "##[debug]Parameters:"
    Write-Verbose "##[debug]    PathToLintersSubmodulesRoot: $PathToLintersSubmodulesRoot"
    Write-Verbose "##[debug]    Platform: $Platform"
    Write-Verbose "##[debug]    InstallCppDependencies: $InstallCppDependencies"

    Set-Location -Path $PathToLintersSubmodulesRoot

    Write-Output "##[section]Installing npm dependencies..."

    npm install

    Assert-ExternalCommandError -ThrowError

    if ($InstallCppDependencies) {

        Write-Information "##[command]Installing doxygen..."

        switch ($Platform) {
            macos-latest {
                & brew install doxygen
            }

            ubuntu-latest {
                & sudo apt-get install doxygen
            }

            windows-latest {
                & choco install doxygen.install -y
            }

            default {
                Write-Error "##[error]Unsupported platform: $Platform"
            }
        }

        Assert-ExternalCommandError -ThrowError
    }

    Write-Output "##[section]All linting dependencies installed!"
}
