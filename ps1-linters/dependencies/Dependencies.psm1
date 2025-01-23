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

    Assert-ExternalCommandError -Verbose

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

    Assert-ExternalCommandError -Verbose

    Write-Verbose "##[debug]Finished installing npm dependencies."

    if (-Not (Test-Path -Path "./build/compile_commands.json")) {

        Write-Output "##[section]Configuring CMake to generate the 'compile_commands.json' file..."

        # This will fail if ninja is not installed so Install-BuildDependencies is called.
        Install-BuildDependencies -Platform $Platform

        cmake -S . -B ./build -G "Ninja"

        Assert-ExternalCommandError -Verbose

        Write-Verbose "##[debug]Finished configuring CMake to generate the 'compile_commands.json' file."
    }

    Write-Output "##[section]All linting dependencies installed!"
}
