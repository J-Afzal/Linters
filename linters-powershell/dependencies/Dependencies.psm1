$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

<#
    .SYNOPSIS
    Installs all linting dependencies needed to run the lint job within GitHub workflows.

    .DESCRIPTION
    This function only installs the linting dependencies not found on the GitHub workflow platforms.
    Ideally Cpp linting dependencies would also be installed here but due to installation complexities they are done within the
    respective Cpp linting step.

    .PARAMETER PathToLintersSubmodulesRoot
    Specifies the path the to the root of the Linters submodule.

    .PARAMETER PathBackToRepositoryRoot
    Specifies the path need to return to the repository root from the Linters submodule.

    .PARAMETER InstallCppLintingDependencies
    Whether to install C++ linting dependencies.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module ./submodules/Linters/linters-powershell/Linters.psd1
    Install-LintingDependencies -Platform macos-latest -PathToLintersSubmodulesRoot "./submodules/Linters" -PathBackToRepositoryRoot "." -InstallCppLintingDependencies -Verbose

#>

function Install-LintingDependencies {

    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateSet("macos-latest", "ubuntu-latest", "windows-latest")]
        [string]
        $Platform,

        [Parameter(Position = 0, Mandatory = $true)]
        [string]
        $PathToLintersSubmodulesRoot,

        [Parameter(Position = 1, Mandatory = $true)]
        [string]
        $PathBackToRepositoryRoot,

        [Parameter(Position = 2, Mandatory = $false)]
        [switch]
        $InstallCppLintingDependencies = $false
    )

    Write-Verbose "##[debug]Running Install-LintingDependencies..."
    Write-Verbose "##[debug]Parameters:"
    Write-Verbose "##[debug]    Platform: $Platform"
    Write-Verbose "##[debug]    PathToLintersSubmodulesRoot: $PathToLintersSubmodulesRoot"
    Write-Verbose "##[debug]    PathBackToRepositoryRoot: $PathBackToRepositoryRoot"
    Write-Verbose "##[debug]    InstallCppLintingDependencies: $InstallCppLintingDependencies"

    Write-Information "##[command]Changing directory to Linters submodule folder..."
    Set-Location -LiteralPath $PathToLintersSubmodulesRoot

    try {
        Write-Information "##[command]Installing npm dependencies..."
        npm install
        Assert-ExternalCommandError -ThrowError

        if (-Not $InstallCppLintingDependencies) {
            return
        }

        switch ($Platform) {
            macos-latest {
                brew install ninja
                brew install llvm
                brew install doxygen
            }

            ubuntu-latest {
                sudo apt-get install ninja-build
                sudo apt-get install wslu
                & ./.github/workflows/helpers/install-brew-on-ubuntu.sh
                brew install llvm
                brew install doxygen
            }

            windows-latest {
                choco install ninja -y
                choco upgrade llvm -y
                choco install doxygen.portable -y
            }

            default {
                Write-Error "##[error]'$Platform' is an unsupported platform."
            }
        }
    }

    catch {
        throw
    }

    finally {
        Write-Information "##[command]Changing directory to repository root..."
        Set-Location -LiteralPath $PathBackToRepositoryRoot
    }

    Write-Information "##[section]All linting dependencies installed!"
}
