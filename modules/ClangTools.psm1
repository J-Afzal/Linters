$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

<#
    .SYNOPSIS
    Wrapper around clang-format.

    .DESCRIPTION
    Runs clang-format against all git-tracked C++ files (*.cpp and *.hpp).

    .PARAMETER Platform
    Specifies the platform being run on.

    .PARAMETER FixClangFormatErrors
    Specifies whether to use clang-format to automatically fix any fixable errors.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module ClangTools.psd1 -Force
    Test-CodeUsingClangFormat -Platform macos-latest -FixClangFormatErrors -Verbose
#>

function Test-CodeUsingClangFormat {

    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateSet("macos-latest", "ubuntu-latest", "windows-latest")]
        [String]
        $Platform,

        [Parameter(Position = 1, Mandatory = $false)]
        [Switch]
        $FixClangFormatErrors = $false
    )

    Write-Verbose "##[debug]Test-CodeUsingClangFormat:  Running Test-CodeUsingClangFormat..."
    Write-Verbose "##[debug]Test-CodeUsingClangFormat:  Parameters:"
    Write-Verbose "##[debug]Test-CodeUsingClangFormat:      Platform            : $Platform"
    Write-Verbose "##[debug]Test-CodeUsingClangFormat:      FixClangFormatErrors: $FixClangFormatErrors"

    Write-Information "##[command]Test-CodeUsingClangFormat:  Determining the clang-format path..."

    switch ($Platform) {
        macos-latest {
            $clangToolPath = "/opt/homebrew/opt/llvm/bin/clang-format"
        }
        ubuntu-latest {
            $clangToolPath = "/home/linuxbrew/.linuxbrew/bin/clang-format"
        }
        windows-latest {
            $clangToolPath = "clang-format"
        }
    }

    Test-CodeUsingGenericClangTool -ClangTool "clang-format" -ClangToolPath $clangToolPath -FixClangToolErrors:$FixClangFormatErrors
}

<#
    .SYNOPSIS
    Wrapper around clang-tidy.

    .DESCRIPTION
    Runs clang-tidy against all git-tracked C++ files (*.cpp and *.hpp).
    CMake must be pre-configured in the build directory to allow the use of the 'compile_commands.json' file.

    .PARAMETER Platform
    Specifies the platform being run on.

    .PARAMETER FixClangTidyErrors
    Specifies whether to use clang-tidy to automatically fix any fixable errors.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module ClangTools.psd1 -Force
    Test-CodeUsingClangTidy -Platform macos-latest -FixClangTidyErrors -Verbose
#>

function Test-CodeUsingClangTidy {

    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateSet("macos-latest", "ubuntu-latest", "windows-latest")]
        [String]
        $Platform,

        [Parameter(Position = 1, Mandatory = $false)]
        [Switch]
        $FixClangTidyErrors = $false
    )

    Write-Verbose "##[debug]Test-CodeUsingClangTidy:  Running Test-CodeUsingClangTidy..."
    Write-Verbose "##[debug]Test-CodeUsingClangTidy:  Parameters:"
    Write-Verbose "##[debug]Test-CodeUsingClangTidy:      Platform          : $Platform"
    Write-Verbose "##[debug]Test-CodeUsingClangTidy:      FixClangTidyErrors: $FixClangTidyErrors"

    Write-Information "##[command]Test-CodeUsingClangFormat:  Determining the clang-tidy path..."

    switch ($Platform) {
        macos-latest {
            $clangToolPath = "/opt/homebrew/opt/llvm/bin/clang-tidy"
        }
        ubuntu-latest {
            $clangToolPath = "/home/linuxbrew/.linuxbrew/bin/clang-tidy"
        }
        windows-latest {
            $clangToolPath = "clang-tidy"
        }
    }

    Test-CodeUsingGenericClangTool -ClangTool "clang-tidy" -ClangToolPath $clangToolPath -FixClangToolErrors:$FixClangTidyErrors
}

<#
    .SYNOPSIS
    Generic function for running a clang tool such as clang-tidy or clang-format.

    .DESCRIPTION
    Runs the specific clang tool against all git-tracked C++ files (*.cpp and *.hpp).
    For clang-tidy CMake must be pre-configured in the build directory to allow the use of the 'compile_commands.json' file.

    .PARAMETER FixClangToolErrors
    Specifies whether to automatically fix any fixable errors.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module ClangTools.psd1 -Force
    Test-CodeUsingGenericClangTool -FixClangToolErrors -Verbose
#>

function Test-CodeUsingGenericClangTool {

    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateSet("clang-format", "clang-tidy")]
        [String]
        $ClangTool,

        [Parameter(Position = 1, Mandatory = $true)]
        [String]
        $ClangToolPath,

        [Parameter(Position = 2, Mandatory = $false)]
        [Switch]
        $FixClangToolErrors = $false
    )

    Write-Verbose "##[debug]Test-CodeUsingGenericClangTool:  Running Test-CodeUsingGenericClangTool..."
    Write-Verbose "##[debug]Test-CodeUsingGenericClangTool:  Parameters:"
    Write-Verbose "##[debug]Test-CodeUsingGenericClangTool:      ClangTool         : $ClangTool"
    Write-Verbose "##[debug]Test-CodeUsingGenericClangTool:      ClangToolPath     : $ClangToolPath"
    Write-Verbose "##[debug]Test-CodeUsingGenericClangTool:      FixClangToolErrors: $FixClangToolErrors"

    Write-Information "##[command]Test-CodeUsingGenericClangTool:  Retrieving all files to test against '$ClangTool'..."
    $filesToTest = Get-FilteredFilePathsToTest -FileExtensionFilterType "Include" -FileExtensionFilterList @("cpp", "hpp")

    if ($null -eq $filesToTest) {
        Write-Information "##[warning]Test-CodeUsingGenericClangTool:  No files found to lint for clang tools! Please check if this is expected!"
        return
    }

    Write-Verbose "##[debug]Test-CodeUsingGenericClangTool:  Using the following '$ClangTool' version..."
    Invoke-ExternalCommand -ExternalCommand $ClangToolPath -ExternalCommandArguments @("--version") -ThrowError -Verbose

    $filesWithErrors = @()

    foreach ($file in $filesToTest) {

        Write-Information "##[command]Test-CodeUsingGenericClangTool:  Running '$ClangTool' against '$file'..."

        if (Invoke-ExternalCommand -ExternalCommand $ClangToolPath -ExternalCommandArguments @("--config-file", "./.$ClangTool", $file, "-p", "./build") -Verbose) {

            if ($FixClangToolErrors) {

                Write-Verbose "##[command]Test-CodeUsingGenericClangTool:  Attempting to fix '$ClangTool' within '$file'..."

                if (Invoke-ExternalCommand -ExternalCommand $ClangToolPath -ExternalCommandArguments @("--config-file", "./.$ClangTool", $file, "-p", "./build") -Verbose) {
                    Write-Verbose "##[debug]Test-CodeUsingGenericClangTool:  '$ClangTool' errors still exist in '$file'!"
                    $filesWithErrors += $file
                }

                else {
                    Write-Verbose "##[debug]Test-CodeUsingGenericClangTool:  All '$ClangTool' errors in '$file' have been fixed!"
                }
            }

            else {
                $filesWithErrors += $file
            }
        }
    }

    if ($filesWithErrors.Length -gt 0) {
        Write-Information "##[error]Test-CodeUsingGenericClangTool:  The following files have '$ClangTool' errors:"
        $filesWithErrors | ForEach-Object { Write-Information "##[error]Test-CodeUsingGenericClangTool:  $_" }
        Write-Error "##[error]Test-CodeUsingGenericClangTool:  Please resolve the above errors!"
    }

    else {
        Write-Information "##[section]Test-CodeUsingGenericClangTool:  All files conform to '$ClangTool' standards!"
    }
}
