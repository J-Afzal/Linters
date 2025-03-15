$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

# TODO: separate clang tidy and clang format

<#
    .SYNOPSIS
    Wrapper around clang-tidy and clang-format.

    .DESCRIPTION
    Runs clang-tidy and clang-format against all git-tracked C++ files (*.cpp and *.hpp).
    CMake must be pre-configured in the build directory to allow the use of the 'compile_commands.json' file.

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
    Import-Module ClangTools.psd1 -Force
    Test-CodeUsingClangTools -Platform macos-latest -FixClangTidyErrors -FixClangFormatErrors -Verbose
#>

function Test-CodeUsingClangTools {

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

    Write-Verbose "##[debug]Running Test-CodeUsingClangTools..."
    Write-Verbose "##[debug]Parameters:"
    Write-Verbose "##[debug]    Platform: $Platform"
    Write-Verbose "##[debug]    PathToLintersSubmodulesRoot: $PathToLintersSubmodulesRoot"
    Write-Verbose "##[debug]    FixClangTidyErrors: $FixClangTidyErrors"
    Write-Verbose "##[debug]    FixClangFormatErrors: $FixClangFormatErrors"

    Write-Information "##[command]Retrieving all files to test against clang-tidy and clang-format..."
    $filesToTest = Get-FilteredFilePathsToTest -FileExtensionFilterType "Include" -FileExtensionFilterList @("cpp", "hpp")

    if ($null -eq $filesToTest) {
        Write-Information "##[warning]No files found to lint for clang tools! Please check if this is expected!"
        return
    }

    Write-Verbose "##[debug]Using the following clang-tidy version..."
    if ($Platform -eq "macos-latest") {
        (/opt/homebrew/opt/llvm/bin/clang-tidy --version) | ForEach-Object { Write-Verbose "##[debug]$_" }
    }
    elseif ($Platform -eq "ubuntu-latest") {
        (/home/linuxbrew/.linuxbrew/bin/clang-tidy --version) | ForEach-Object { Write-Verbose "##[debug]$_" }
    }
    else {
        (clang-tidy --version) | ForEach-Object { Write-Verbose "##[debug]$_" }
    }
    Assert-ExternalCommandError -ThrowError

    Write-Verbose "##[debug]Using the following clang-format version..."
    if ($Platform -eq "macos-latest") {
        (/opt/homebrew/opt/llvm/bin/clang-format --version) | ForEach-Object { Write-Verbose "##[debug]$_" }
    }
    elseif ($Platform -eq "ubuntu-latest") {
        (/home/linuxbrew/.linuxbrew/bin/clang-format --version) | ForEach-Object { Write-Verbose "##[debug]$_" }
    }
    else {
        (clang-format --version) | ForEach-Object { Write-Verbose "##[debug]$_" }
    }
    Assert-ExternalCommandError -ThrowError

    $filesWithErrors = @()

    $ErrorActionPreference = "Continue"

    foreach ($file in $filesToTest) {

        Write-Information "##[command]Running clang-tidy against '$file'..."
        if ($Platform -eq "macos-latest") {
            (/opt/homebrew/opt/llvm/bin/clang-tidy --config-file $PathToLintersSubmodulesRoot/.clang-tidy $file -p ./build 2>&1) | ForEach-Object { Write-Verbose "##[debug]$_" }
        }
        elseif ($Platform -eq "ubuntu-latest") {
            (/home/linuxbrew/.linuxbrew/bin/clang-tidy --config-file $PathToLintersSubmodulesRoot/.clang-tidy $file -p ./build 2>&1) | ForEach-Object { Write-Verbose "##[debug]$_" }
        }
        else {
            (clang-tidy --config-file $PathToLintersSubmodulesRoot/.clang-tidy $file -p ./build 2>&1) | ForEach-Object { Write-Verbose "##[debug]$_" }
        }

        if (Assert-ExternalCommandError) {

            if ($FixClangTidyErrors) {
                Write-Verbose "##[debug]Fixing clang-tidy issues in '$file'..."
                if ($Platform -eq "macos-latest") {
                    (/opt/homebrew/opt/llvm/bin/clang-tidy --config-file $PathToLintersSubmodulesRoot/.clang-tidy --fix $file -p ./build 2>&1) | ForEach-Object { Write-Verbose "##[debug]$_" }
                }
                elseif ($Platform -eq "ubuntu-latest") {
                    (/home/linuxbrew/.linuxbrew/bin/clang-tidy --config-file $PathToLintersSubmodulesRoot/.clang-tidy --fix $file -p ./build 2>&1) | ForEach-Object { Write-Verbose "##[debug]$_" }
                }
                else {
                    (clang-tidy --config-file $PathToLintersSubmodulesRoot/.clang-tidy --fix $file -p ./build 2>&1) | ForEach-Object { Write-Verbose "##[debug]$_" }
                }

                if (Assert-ExternalCommandError) {
                    Write-Verbose "##[debug]clang-tidy issues still exist in '$file'..."
                    $filesWithErrors += $file
                }

                else {
                    Write-Verbose "##[debug]All clang-tidy issues in '$file' have been fixed!"
                }
            }

            else {
                $filesWithErrors += $file
            }
        }

        Write-Information "##[command]Running clang-format against '$file'..."
        if ($Platform -eq "macos-latest") {
            (/opt/homebrew/opt/llvm/bin/clang-format --style=file:$PathToLintersSubmodulesRoot/.clang-format --Werror --dry-run $file 2>&1) | ForEach-Object { Write-Verbose "##[debug]$_" }
        }
        elseif ($Platform -eq "ubuntu-latest") {
            (/home/linuxbrew/.linuxbrew/bin/clang-format --style=file:$PathToLintersSubmodulesRoot/.clang-format --Werror --dry-run $file 2>&1) | ForEach-Object { Write-Verbose "##[debug]$_" }
        }
        else {
            (clang-format --style=file:$PathToLintersSubmodulesRoot/.clang-format --Werror --dry-run $file 2>&1) | ForEach-Object { Write-Verbose "##[debug]$_" }
        }

        if (Assert-ExternalCommandError) {

            if ($FixClangFormatErrors) {
                Write-Verbose "##[debug]Fixing clang-format issues in '$file'..."
                if ($Platform -eq "macos-latest") {
                    (/opt/homebrew/opt/llvm/bin/clang-format --style=file:$PathToLintersSubmodulesRoot/.clang-format --Werror --i $file 2>&1) | ForEach-Object { Write-Verbose "##[debug]$_" }
                }
                elseif ($Platform -eq "ubuntu-latest") {
                    (/home/linuxbrew/.linuxbrew/bin/clang-format --style=file:$PathToLintersSubmodulesRoot/.clang-format --Werror --i $file 2>&1) | ForEach-Object { Write-Verbose "##[debug]$_" }
                }
                else {
                    (clang-format --style=file:$PathToLintersSubmodulesRoot/.clang-format --Werror --i $file 2>&1) | ForEach-Object { Write-Verbose "##[debug]$_" }
                }

                if (Assert-ExternalCommandError) {
                    Write-Verbose "##[debug]clang-format issues still exist in '$file'..."
                    $filesWithErrors += $file
                }

                else {
                    Write-Verbose "##[debug]All clang-format issues in '$file' have been fixed!"
                }
            }

            else {
                $filesWithErrors += $file
            }
        }
    }

    $ErrorActionPreference = "Stop"

    if ($filesWithErrors.Length -gt 0) {
        Write-Information "##[error]The following files have clang-tidy/clang-format errors:"
        $filesWithErrors | ForEach-Object { Write-Information "##[error]$_" }
        Write-Error "##[error]Please resolve the above errors!"
    }

    else {
        Write-Output "##[section]All files conform to clang-tidy/clang-format standards!"
    }
}
