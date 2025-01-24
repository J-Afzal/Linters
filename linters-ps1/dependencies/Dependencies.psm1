$ErrorActionPreference = "Stop"

<#
    .SYNOPSIS
    Installs all dependencies that are needed to build within GitHub workflows.

    .DESCRIPTION
    This function only installs the build dependencies not found on the GitHub workflow platforms.

    .INPUTS
    [string] Platform. The current GitHub workflow platform.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module ./modules/TerminalGames.psd1
    Install-BuildDependencies -Platform "macos-latest" -Verbose
#>

function Install-BuildDependencies {

    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=$false)]
        [ValidateSet("macos-latest", "ubuntu-latest", "windows-latest")]
        [string]
        $Platform
    )

    Write-Output "##[section]Running Install-BuildDependencies..."
    Write-Verbose "##[debug]Parameters:"
    Write-Verbose "##[debug]    Platform: $Platform"

    switch ($Platform) {
        macos-latest {
            brew install ninja
        }

        ubuntu-latest {
            sudo apt-get install ninja-build
        }

        windows-latest {
            choco install ninja -y
        }
    }

    Assert-ExternalCommandError -ThrowError -Verbose

    Write-Output "##[section]All build dependencies installed!"
}

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
    Import-Module ./modules/TerminalGames.psd1
    Install-LintingDependencies -Platform "macos-latest" -Verbose
#>

function Install-LintingDependencies {

    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=$false)]
        [ValidateSet("macos-latest", "ubuntu-latest", "windows-latest")]
        [string]
        $Platform
    )

    Write-Output "##[section]Running Install-LintingDependencies..."
    Write-Verbose "##[debug]Parameters:"
    Write-Verbose "##[debug]    Platform: $Platform"

    Write-Output "##[section]Installing npm dependencies..."

    npm install

    Assert-ExternalCommandError -ThrowError -Verbose

    Write-Verbose "##[debug]Finished installing npm dependencies."

    Write-Output "##[section]All linting dependencies installed!"
}
