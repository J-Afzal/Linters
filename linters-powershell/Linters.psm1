$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

<#
    .SYNOPSIS
    Asserts whether an error when an external function has thrown an error via LASTEXITCODE.

    .DESCRIPTION
    This function must be called immediately after the external function call.

    .PARAMETER ThrowError
    Specifies whether to throw an error if an error is detected. If no specified a boolean will be returned instead.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module ./submodules/Linters/linters-powershell/Linters.psd1
    npm install
    Assert-ExternalCommandError -ThrowError -Verbose
#>

function Assert-ExternalCommandError {

    [CmdletBinding()]
    [OutputType([system.boolean])]
    param(
        [Parameter(Position = 0, Mandatory = $false)]
        [switch]
        $ThrowError = $false
    )

    Write-Verbose "##[debug]Running Assert-ExternalCommandError..."
    Write-Verbose "##[debug]Parameters:"
    Write-Verbose "##[debug]    ThrowError: $ThrowError"

    if ($LASTEXITCODE -ne 0) {
        if ($ThrowError) {
            Write-Error "##[error]Please resolve the above errors!"
        }

        else {
            Write-Verbose "##[debug]Returning: true"
            return $true
        }
    }

    elseif (-Not $ThrowError) {
        Write-Verbose "##[debug]Returning: false"
        return $false
    }
}

<#
    .SYNOPSIS
    Gets all git tracked binary files.

    .DESCRIPTION
    Uses .gitattributes 'binary' entries to determine which file types are to be considered binary.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module ./submodules/Linters/linters-powershell/Linters.psd1
    Get-AllBinaryFiles -Verbose
#>

function Get-AllBinaryFiles {

    [CmdletBinding()]
    [OutputType([system.object[]])]
    param()

    Write-Verbose "##[debug]Running Get-AllBinaryFiles..."

    if (-Not (Test-Path -LiteralPath ./.gitattributes)) {
        Write-Information "##[warning]No .gitattributes file found at current directory! Please check if this is expected!"
        return
    }

    $gitattributesFileContents = @(Get-Content -LiteralPath ./.gitattributes)
    $binaryFileExtensions = @()
    $binaryFileNames = @()

    foreach ($currentLine in $gitattributesFileContents) {

        # File extensions with or without * wildcard
        if ($currentLine -Match "^\*?\.[a-z0-9-]+ +binary$") {

            $found = $currentLine -Match "\.[a-z0-9-]+"

            if ($found) {
                $binaryFileExtensions += $matches[0]
            }

            else {
                Write-Information "##[warning]'$currentLine' matched as a file extension but failed to extract."
            }
        }

        # Files without an extension
        if ($currentLine -Match "^[a-zA-Z0-9-]+ +binary$") {

            $found = $currentLine -Match "^[a-zA-Z0-9-]+"

            if ($found) {
                $binaryFileNames += $matches[0]
            }

            else {
                Write-Information "##[warning]'$currentLine' matched as a file without an extension but failed to extract."
            }
        }
    }

    $allFiles = git ls-files -c
    Assert-ExternalCommandError -ThrowError

    $allBinaryFiles = @()

    foreach ($file in $allFiles) {

        # Check file extensions
        $fileExtensionMatched = $false

        foreach ($binaryFileExtension in $binaryFileExtensions) {
            if ($file.EndsWith($binaryFileExtension)) {
                $fileExtensionMatched = $true
                break
            }
        }

        if ($fileExtensionMatched) {
            $allBinaryFiles += $file
            continue
        }

        # Otherwise check file names
        $fileNameMatched = $false

        foreach ($binaryFileName in $binaryFileNames) {
            if ($file.EndsWith($binaryFileName)) {
                $fileNameMatched = $true
                break
            }
        }

        if ($fileNameMatched) {
            $allBinaryFiles += $file
            continue
        }
    }

    Write-Verbose "##[debug]Returning:"
    $allBinaryFiles | ForEach-Object { Write-Verbose "##[debug]    $_" }

    return $allBinaryFiles
}

<#
    .SYNOPSIS
    Gets all git tracked files.

    .DESCRIPTION
    None.

    .PARAMETER ExcludeBinaryFiles
    Specifies whether to exclude binary files as defined in .gitattributes.

    .INPUTS
    None.

    .OUTPUTS
    system.object[] A list of file paths (relative to the root of the repository).

    .EXAMPLE
    Import-Module ./submodules/Linters/linters-powershell/Linters.psd1
    Get-AllFilePathsToTest -ExcludeBinaryFiles -Verbose
#>

function Get-AllFilePathsToTest {

    [CmdletBinding()]
    [OutputType([system.object[]])]
    param(
        [Parameter(Position = 0, Mandatory = $false)]
        [switch]
        $ExcludeBinaryFiles = $false
    )

    Write-Verbose "##[debug]Running Get-AllFilePathsToTest..."
    Write-Verbose "##[debug]Parameters:"
    Write-Verbose "##[debug]    ExcludeBinaryFiles: $ExcludeBinaryFiles"

    $allFilesToTest = Get-FilteredFilePathsToTest -DirectoryFilterType "Exclude" -DirectoryNameFilterList @("nothing") -FileNameFilterType "Exclude" -FileNameFilterList @("nothing") -FileExtensionFilterType "Exclude" -FileExtensionFilterList @("nothing") -ExcludeBinaryFiles:$ExcludeBinaryFiles

    Write-Verbose "##[debug]Returning:"
    $allFilesToTest | ForEach-Object { Write-Verbose "##[debug]    $_" }

    return $allFilesToTest
}

<#
    .SYNOPSIS
    Gets all git tracked files using various filters.

    .DESCRIPTION
    None.

    .PARAMETER DirectoryFilterType
    Specifies whether to include or exclude the DirectoryNameFilterList in the search.

    .PARAMETER DirectoryNameFilterList
    Specifies the directory paths from the root of the repo to either include or exclude depending upon the value of
    DirectoryFilterType.

    .PARAMETER FileNameFilterType
    Specifies whether to include or exclude the FileNameFilterList in the search.

    .PARAMETER FileNameFilterList
    Specifies the file names (without file extension) to either include or exclude depending upon the value of
    FileNameFilterType.

    .PARAMETER FileExtensionFilterType
    Specifies whether to include or exclude the FileExtensionFilterList in the search.

    .PARAMETER FileExtensionFilterList
    Specifies the file extensions to either include or exclude depending upon the value of FileExtensionFilterType.

    .PARAMETER ExcludeBinaryFiles
    Specifies whether to exclude binary files as defined in .gitattributes.

    .INPUTS
    None.

    .OUTPUTS
    system.object[] A list of file paths (relative to the root of the repository).

    .EXAMPLE
    Import-Module ./submodules/Linters/linters-powershell/Linters.psd1

    Get-FilteredFilePathsToTest -DirectoryFilterType "Exclude" -DirectoryNameFilterList @("docs/html") \
                                -FileNameFilterType "Exclude" -FileNameFilterList @("cspell", "package-lock") \
                                -FileExtensionFilterType "Exclude" -FileExtensionFilterList @("ico", "png") -Verbose
#>

function Get-FilteredFilePathsToTest {

    [CmdletBinding()]
    [OutputType([system.object[]])]
    param(
        [Parameter(Position = 0, Mandatory = $false, ParameterSetName = "DirectorySearch")]
        [Parameter(Position = 0, Mandatory = $false, ParameterSetName = "DirectoryAndFileNameSearch")]
        [Parameter(Position = 0, Mandatory = $false, ParameterSetName = "FullSearch")]
        [ValidateSet("Include", "Exclude")]
        [string]
        $DirectoryFilterType,

        [Parameter(Position = 1, Mandatory = $true, ParameterSetName = "DirectorySearch")]
        [Parameter(Position = 1, Mandatory = $true, ParameterSetName = "DirectoryAndFileNameSearch")]
        [Parameter(Position = 1, Mandatory = $true, ParameterSetName = "FullSearch")]
        [system.object[]]
        $DirectoryNameFilterList,

        [Parameter(Position = 2, Mandatory = $false, ParameterSetName = "FileNameSearch")]
        [Parameter(Position = 2, Mandatory = $false, ParameterSetName = "DirectoryAndFileNameSearch")]
        [Parameter(Position = 2, Mandatory = $false, ParameterSetName = "FileNameAndFileExtensionSearch")]
        [Parameter(Position = 2, Mandatory = $false, ParameterSetName = "FullSearch")]
        [ValidateSet("Include", "Exclude")]
        [string]
        $FileNameFilterType,

        [Parameter(Position = 3, Mandatory = $true, ParameterSetName = "FileNameSearch")]
        [Parameter(Position = 3, Mandatory = $true, ParameterSetName = "DirectoryAndFileNameSearch")]
        [Parameter(Position = 3, Mandatory = $true, ParameterSetName = "FileNameAndFileExtensionSearch")]
        [Parameter(Position = 3, Mandatory = $true, ParameterSetName = "FullSearch")]
        [system.object[]]
        $FileNameFilterList,

        [Parameter(Position = 4, Mandatory = $false, ParameterSetName = "FileExtensionSearch")]
        [Parameter(Position = 4, Mandatory = $false, ParameterSetName = "FileNameAndFileExtensionSearch")]
        [Parameter(Position = 4, Mandatory = $false, ParameterSetName = "FullSearch")]
        [ValidateSet("Include", "Exclude")]
        [string]
        $FileExtensionFilterType,

        [Parameter(Position = 5, Mandatory = $true, ParameterSetName = "FileExtensionSearch")]
        [Parameter(Position = 5, Mandatory = $true, ParameterSetName = "FileNameAndFileExtensionSearch")]
        [Parameter(Position = 5, Mandatory = $true, ParameterSetName = "FullSearch")]
        [system.object[]]
        $FileExtensionFilterList,

        [Parameter(Position = 6, Mandatory = $false, ParameterSetName = "DirectorySearch")]
        [Parameter(Position = 6, Mandatory = $false, ParameterSetName = "FileNameSearch")]
        [Parameter(Position = 6, Mandatory = $false, ParameterSetName = "FileExtensionSearch")]
        [Parameter(Position = 6, Mandatory = $false, ParameterSetName = "DirectoryAndFileNameSearch")]
        [Parameter(Position = 6, Mandatory = $false, ParameterSetName = "FileNameAndFileExtensionSearch")]
        [Parameter(Position = 6, Mandatory = $false, ParameterSetName = "FullSearch")]
        [switch]
        $ExcludeBinaryFiles = $false
    )

    Write-Verbose "##[debug]Running Get-FilteredFilePathsToTest..."
    Write-Verbose "##[debug]Parameters:"
    Write-Verbose "##[debug]    DirectoryFilterType: $DirectoryFilterType"
    Write-Verbose "##[debug]    DirectoryNameFilterList:"
    $DirectoryNameFilterList | ForEach-Object { Write-Verbose "##[debug]        $_" }
    Write-Verbose "##[debug]    FileNameFilterType: $FileNameFilterType"
    Write-Verbose "##[debug]    FileNameFilterList:"
    $FileNameFilterList | ForEach-Object { Write-Verbose "##[debug]        $_" }
    Write-Verbose "##[debug]    FileExtensionFilterType: $FileExtensionFilterType"
    Write-Verbose "##[debug]    FileExtensionFilterList:"
    $FileExtensionFilterList | ForEach-Object { Write-Verbose "##[debug]        $_" }
    Write-Verbose "##[debug]    ExcludeBinaryFiles: $ExcludeBinaryFiles"

    $allFiles = git ls-files -c
    Assert-ExternalCommandError -ThrowError

    $allBinaryFiles = Get-AllBinaryFiles
    $filteredFilesToTest = @()

    foreach ($file in $allFiles) {

        # Exclude submodules
        if ($file.StartsWith("submodules")) {
            continue
        }

        # Exclude binary files if required
        if ($ExcludeBinaryFiles -And ($null -ne $allBinaryFiles) -And $allBinaryFiles.Contains($file)) {
            continue
        }

        # Check if file directory is in allow list
        $fileDirectoryIsAllowed = if ($DirectoryFilterType -eq "Include") { $false } else { $true }

        foreach ($directoryFilter in $DirectoryNameFilterList) {
            if ($file.StartsWith($directoryFilter)) {
                $fileDirectoryIsAllowed = if ($DirectoryFilterType -eq "Include") { $true } else { $false }
                break
            }
        }

        # If directory is not allowed skip further checks and go to next file
        if (-Not $fileDirectoryIsAllowed) {
            continue
        }

        # Check if file name is in allow list
        $fileNameIsAllowed = if ($FileNameFilterType -eq "Include") { $false } else { $true }

        $fileName = $file.Split("/")[-1].Split(".")[-2]

        if ($fileName -In $FileNameFilterList) {
            $fileNameIsAllowed = if ($FileNameFilterType -eq "Include") { $true } else { $false }
        }

        # If file name is not allowed skip further checks and go to next file
        if (-Not $fileNameIsAllowed) {
            continue
        }

        # Check if file name is in allow list
        $fileExtensionIsAllowed = if ($FileExtensionFilterType -eq "Include") { $false } else { $true }

        $fileExtension = $file.Split(".")[-1]

        if ($fileExtension -In $FileExtensionFilterList) {
            $fileExtensionIsAllowed = if ($FileExtensionFilterType -eq "Include") { $true } else { $false }
        }

        # If file extension is not allowed skip further checks and go to next file
        if (-Not $fileExtensionIsAllowed) {
            continue
        }

        $filteredFilesToTest += $file
    }

    Write-Verbose "##[debug]Returning:"
    $filteredFilesToTest | ForEach-Object { Write-Verbose "##[debug]    $_" }

    return $filteredFilesToTest
}

<#
    .SYNOPSIS
    Compares two objects.

    .DESCRIPTION
    Compare-Object was not sufficient as it disregards the order of the DifferenceObject.

    .PARAMETER ReferenceObject
    Specifies an array of objects used as a reference for comparison.

    .PARAMETER DifferenceObject
    Specifies the objects that are compared to the reference objects.

    .INPUTS
    None.

    .OUTPUTS
    system.object[] A list of error messages.

    .EXAMPLE
    Import-Module ./submodules/Linters/linters-powershell/Linters.psd1

    $arrayOne = @(1,2,3)
    $arrayTwo = @(1,3,2)

    Compare-ObjectExact -ReferenceObject $arrayOne -DifferenceObject $arrayTwo -Verbose
#>

function Compare-ObjectExact {

    [CmdletBinding()]
    [OutputType([system.object[]])]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [system.object[]]
        $ReferenceObject,

        [Parameter(Position = 1, Mandatory = $true)]
        [system.object[]]
        $DifferenceObject
    )

    Write-Verbose "##[debug]Running Compare-ObjectExact..."
    Write-Verbose "##[debug]Parameters:"
    Write-Verbose "##[debug]    ReferenceObject:"
    $ReferenceObject | ForEach-Object { Write-Verbose "##[debug]        $_" }
    Write-Verbose "##[debug]    DifferenceObject:"
    $DifferenceObject | ForEach-Object { Write-Verbose "##[debug]        $_" }

    [Collections.Generic.List[String]] $errors = @()

    for ($index = 0; $index -lt $ReferenceObject.Length; $index++) {

        try {

            if ($ReferenceObject[$index] -ne $DifferenceObject[$index]) {
                $errors.Add("'$($DifferenceObject[$index])' found instead of '$($ReferenceObject[$index])'.")
            }
        }

        catch {

            # Assuming that this is caused by an index out of bounds error with DifferenceObject
            $errors.Add("'$($ReferenceObject[$index])' was not found.")

        }
    }

    if ($DifferenceObject.Length -gt $ReferenceObject.Length) {

        for ($index = $ReferenceObject.Length; $index -lt $DifferenceObject.Length; $index++) {

            $errors.Add("An extra value of '$($DifferenceObject[$index])' found.")
        }
    }

    Write-Verbose "##[debug]Returning:"
    $errors | ForEach-Object { Write-Verbose "##[debug]    $_" }

    return $errors
}

<#
    .SYNOPSIS
    Runs all linting checks found in the continuos integration workflow.

    .DESCRIPTION
    Intended to be used locally during development to manually check for linting issues before pushing a commit.
    Raises an error at the first occurrence of a linting error.

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
        [string]
        $Platform,

        [Parameter(Position = 1, Mandatory = $true)]
        [string]
        $PathToLintersSubmodulesRoot,

        [Parameter(Position = 2, Mandatory = $true)]
        [string]
        $PathBackToRepositoryRoot,

        [Parameter(Position = 3, Mandatory = $false)]
        [switch]
        $FixClangTidyErrors = $false,

        [Parameter(Position = 4, Mandatory = $false)]
        [switch]
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

<#
    .SYNOPSIS
    Wrapper around clang-tidy and clang-format.

    .DESCRIPTION
    Runs clang-tidy and clang-format against all git-tracked C++ files (*.cpp and *.hpp).
    CMake must be configured in the ./build/ directory as the 'compile_commands.json' file is needed by clang-tidy.
    Raises an error if linting errors found.

    .PARAMETER Platform
    Specifies the platform being run on.

    .PARAMETER PathToLintersSubmodulesRoot
    Specifies the path the to the root of the Linters submodule.

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
    Test-CodeUsingClangTools -Platform macos-latest -PathToLintersSubmodulesRoot "./submodules/Linters" -FixClangTidyErrors -FixClangFormatErrors -Verbose
#>

function Test-CodeUsingClangTools {

    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateSet("macos-latest", "ubuntu-latest", "windows-latest")]
        [string]
        $Platform,

        [Parameter(Position = 0, Mandatory = $true)]
        [string]
        $PathToLintersSubmodulesRoot,

        [Parameter(Position = 1, Mandatory = $false)]
        [switch]
        $FixClangTidyErrors = $false,

        [Parameter(Position = 2, Mandatory = $false)]
        [switch]
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
    } elseif ($Platform -eq "ubuntu-latest") {
        (/home/linuxbrew/.linuxbrew/bin/clang-tidy --version) | ForEach-Object { Write-Verbose "##[debug]$_" }
    } else {
        (clang-tidy --version) | ForEach-Object { Write-Verbose "##[debug]$_" }
    }
    Assert-ExternalCommandError -ThrowError

    Write-Verbose "##[debug]Using the following clang-format version..."
    if ($Platform -eq "macos-latest") {
        (/opt/homebrew/opt/llvm/bin/clang-format --version) | ForEach-Object { Write-Verbose "##[debug]$_" }
    } elseif ($Platform -eq "ubuntu-latest") {
        (/home/linuxbrew/.linuxbrew/bin/clang-format --version) | ForEach-Object { Write-Verbose "##[debug]$_" }
    } else {
        (clang-format --version) | ForEach-Object { Write-Verbose "##[debug]$_" }
    }
    Assert-ExternalCommandError -ThrowError

    $filesWithErrors = @()

    $ErrorActionPreference = "Continue"

    foreach ($file in $filesToTest) {

        Write-Information "##[command]Running clang-tidy against '$file'..."
        if ($Platform -eq "macos-latest") {
            (/opt/homebrew/opt/llvm/bin/clang-tidy --config-file $PathToLintersSubmodulesRoot/.clang-tidy $file -p ./build 2>&1) | ForEach-Object { Write-Verbose "##[debug]$_" }
        } elseif ($Platform -eq "ubuntu-latest") {
            (/home/linuxbrew/.linuxbrew/bin/clang-tidy --config-file $PathToLintersSubmodulesRoot/.clang-tidy $file -p ./build 2>&1) | ForEach-Object { Write-Verbose "##[debug]$_" }
        } else {
            (clang-tidy --config-file $PathToLintersSubmodulesRoot/.clang-tidy $file -p ./build 2>&1) | ForEach-Object { Write-Verbose "##[debug]$_" }
        }

        if (Assert-ExternalCommandError) {

            if ($FixClangTidyErrors) {
                Write-Verbose "##[debug]Fixing clang-tidy issues in '$file'..."
                if ($Platform -eq "macos-latest") {
                    (/opt/homebrew/opt/llvm/bin/clang-tidy --config-file $PathToLintersSubmodulesRoot/.clang-tidy --fix $file -p ./build 2>&1) | ForEach-Object { Write-Verbose "##[debug]$_" }
                } elseif ($Platform -eq "ubuntu-latest") {
                    (/home/linuxbrew/.linuxbrew/bin/clang-tidy --config-file $PathToLintersSubmodulesRoot/.clang-tidy --fix $file -p ./build 2>&1) | ForEach-Object { Write-Verbose "##[debug]$_" }
                } else {
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
        } elseif ($Platform -eq "ubuntu-latest") {
            (/home/linuxbrew/.linuxbrew/bin/clang-format --style=file:$PathToLintersSubmodulesRoot/.clang-format --Werror --dry-run $file 2>&1) | ForEach-Object { Write-Verbose "##[debug]$_" }
        } else {
            (clang-format --style=file:$PathToLintersSubmodulesRoot/.clang-format --Werror --dry-run $file 2>&1) | ForEach-Object { Write-Verbose "##[debug]$_" }
        }

        if (Assert-ExternalCommandError) {

            if ($FixClangFormatErrors) {
                Write-Verbose "##[debug]Fixing clang-format issues in '$file'..."
                if ($Platform -eq "macos-latest") {
                    (/opt/homebrew/opt/llvm/bin/clang-format --style=file:$PathToLintersSubmodulesRoot/.clang-format --Werror --i $file 2>&1) | ForEach-Object { Write-Verbose "##[debug]$_" }
                } elseif ($Platform -eq "ubuntu-latest") {
                    (/home/linuxbrew/.linuxbrew/bin/clang-format --style=file:$PathToLintersSubmodulesRoot/.clang-format --Werror --i $file 2>&1) | ForEach-Object { Write-Verbose "##[debug]$_" }
                } else {
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

<#
    .SYNOPSIS
    Runs cspell against all non-binary files (with exception of the package-lock.json file).

    .DESCRIPTION
    Raises an error if linting errors found.

    .PARAMETER PathToLintersSubmodulesRoot
    Specifies the path the to the root of the Linters submodule.

    .PARAMETER PathBackToRepositoryRoot
    Specifies the path need to return to the repository root from the Linters submodule.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module ./submodules/Linters/linters-powershell/Linters.psd1
    Test-CodeUsingCSpell -PathToLintersSubmodulesRoot "./submodules/Linters" -PathBackToRepositoryRoot "." -Verbose
#>

function Test-CodeUsingCSpell {

    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]
        $PathToLintersSubmodulesRoot,

        [Parameter(Position = 1, Mandatory = $true)]
        [string]
        $PathBackToRepositoryRoot
    )

    Write-Verbose "##[debug]Running Test-CodeUsingCSpell..."
    Write-Verbose "##[debug]Parameters:"
    Write-Verbose "##[debug]    PathToLintersSubmodulesRoot: $PathToLintersSubmodulesRoot"
    Write-Verbose "##[debug]    PathBackToRepositoryRoot: $PathBackToRepositoryRoot"

    Write-Information "##[command]Retrieving all files to test against cspell..."
    $filesToTest = Get-FilteredFilePathsToTest -DirectoryFilterType "Exclude" -DirectoryNameFilterList @("docs/html") -FileNameFilterType "Exclude" -FileNameFilterList @("package-lock") -ExcludeBinaryFiles

    if ($null -eq $filesToTest) {
        Write-Information "##[warning]No files found to lint for cspell! Please check if this is expected!"
        return
    }

    Write-Information "##[command]Changing directory to Linters submodule folder..."
    Set-Location -LiteralPath $PathToLintersSubmodulesRoot

    try {
        Write-Verbose "##[debug]Using the following cspell version..."
        (npx cspell --version) | ForEach-Object { "##[debug]$_" } | Write-Verbose

        $filesWithErrors = @()

        foreach ($file in $filesToTest) {

            Write-Information "##[command]Running cspell against '$file'..."

            (npx -c "cspell $PathBackToRepositoryRoot/$file --config $PathBackToRepositoryRoot/cspell.yml --unique --show-context --no-progress --no-summary") | ForEach-Object { "##[debug]$_" } | Write-Verbose

            if (Assert-ExternalCommandError) {
                $filesWithErrors += $file
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

    if ($filesWithErrors.Length -gt 0) {
        Write-Information "##[error]The following files have cspell errors:"
        $filesWithErrors | ForEach-Object { Write-Information "##[error]$_" }
        Write-Error "##[error]Please resolve the above errors!"
    }

    else {
        Write-Output "##[section]All files conform to cspell standards!"
    }
}

<#
    .SYNOPSIS
    Runs prettier against all JSON, markdown and YAML files (with exception of the package-lock.json file).

    .DESCRIPTION
    Raises an error if linting errors found.

    .PARAMETER PathToLintersSubmodulesRoot
    Specifies the path the to the root of the Linters submodule.

    .PARAMETER PathBackToRepositoryRoot
    Specifies the path need to return to the repository root from the Linters submodule.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module ./submodules/Linters/linters-powershell/Linters.psd1
    Test-CodeUsingPrettier -PathToLintersSubmodulesRoot "./submodules/Linters" -PathBackToRepositoryRoot "../.." -Verbose
#>

function Test-CodeUsingPrettier {

    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]
        $PathToLintersSubmodulesRoot,

        [Parameter(Position = 1, Mandatory = $true)]
        [string]
        $PathBackToRepositoryRoot
    )

    Write-Verbose "##[debug]Running Test-CodeUsingPrettier..."
    Write-Verbose "##[debug]Parameters:"
    Write-Verbose "##[debug]    PathToLintersSubmodulesRoot: $PathToLintersSubmodulesRoot"
    Write-Verbose "##[debug]    PathBackToRepositoryRoot: $PathBackToRepositoryRoot"

    Write-Information "##[command]Retrieving all files to test against prettier..."
    $filesToTest = Get-FilteredFilePathsToTest -FileNameFilterType "Exclude" -FileNameFilterList @("package-lock") -FileExtensionFilterType "Include" -FileExtensionFilterList @("clang-format", "clang-tidy", "json", "md", "yml")

    if ($null -eq $filesToTest) {
        Write-Information "##[warning]No files found to lint for prettier! Please check if this is expected!"
        return
    }

    Write-Information "##[command]Changing directory to Linters submodule folder..."
    Set-Location -LiteralPath $PathToLintersSubmodulesRoot

    try {
        Write-Verbose "##[debug]Using the following prettier version..."
        (npx prettier --version) | ForEach-Object { Write-Verbose "##[debug]$_" }

        $filesWithErrors = @()

        foreach ($file in $filesToTest) {

            Write-Information "##[command]Running prettier against '$file'..."

            (npx -c "prettier $PathBackToRepositoryRoot/$file --debug-check") | ForEach-Object { Write-Verbose "##[debug]$_" }

            if (Assert-ExternalCommandError) {
                $filesWithErrors += $file
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

    if ($filesWithErrors.Length -gt 0) {
        Write-Information "##[error]The following files have prettier errors:"
        $filesWithErrors | ForEach-Object { Write-Information "##[error]$_" }
        Write-Error "##[error]Please resolve the above errors!"
    }

    else {
        Write-Output "##[section]All files conform to prettier standards!"
    }
}

<#
    .SYNOPSIS
    Runs PSScriptAnalyzer against all PowerShell files.

    .DESCRIPTION
    Raises an error if linting errors found.

    .PARAMETER PathToLintersSubmodulesRoot
    Specifies the path the to the root of the Linters submodule.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module ./submodules/Linters/linters-powershell/Linters.psd1
    Test-CodeUsingPSScriptAnalyzer -PathToLintersSubmodulesRoot "./submodules/Linters" -Verbose
#>

function Test-CodeUsingPSScriptAnalyzer {

    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]
        $PathToLintersSubmodulesRoot
    )

    Write-Verbose "##[debug]Running Test-CodeUsingPSScriptAnalyzer..."
    Write-Verbose "##[debug]Parameters:"
    Write-Verbose "##[debug]    PathToLintersSubmodulesRoot: $PathToLintersSubmodulesRoot"

    Write-Information "##[command]Retrieving all files to test against PSScriptAnalyzer..."
    $filesToTest = Get-FilteredFilePathsToTest -FileExtensionFilterType "Include" -FileExtensionFilterList @("ps1", "psd1", "psm1")

    if ($null -eq $filesToTest) {
        Write-Information "##[warning]No files found to lint for PSScriptAnalyzer! Please check if this is expected!"
        return
    }

    $filesWithErrors = @()

    foreach ($file in $filesToTest) {

        Write-Information "##[command]Running PSScriptAnalyzer against '$file'..."

        Invoke-ScriptAnalyzer -Path $file -Settings "$PathToLintersSubmodulesRoot/PSScriptAnalyzerSettings.psd1"
        $output = Invoke-ScriptAnalyzer -Path $file -Settings "$PathToLintersSubmodulesRoot/PSScriptAnalyzerSettings.psd1"

        if ($output.Length -gt 0) {
            $filesWithErrors += $file
        }
    }

    if ($filesWithErrors.Length -gt 0) {
        Write-Information "##[error]The following files have PSScriptAnalyzer errors:"
        $filesWithErrors | ForEach-Object { Write-Information "##[error]$_" }
        Write-Error "##[error]Please resolve the above errors!"
    }

    else {
        Write-Output "##[section]All files conform to PSScriptAnalyzer standards!"
    }
}

<#
    .SYNOPSIS
    Lints the cspell.yml file.

    .DESCRIPTION
    Raises an error if linting issues are found for the following issues:
        - Invalid version number
        - Invalid language
        - Invalid ordering of keys
        - Empty lines
        - Non-alphabetical ordering of entries within keys
        - Duplicate entries in dictionaries, ignorePaths, words and ignoreWords
        - Non-lowercase entries in words and ignoreWords
        - Entries that are in both words and ignoreWords
        - Entries in ignorePaths that are not present in gitignore (with exception of the package-lock.json file)
        - Entries in words and ignoreWords that are not present in the codebase

    This function will also throw errors for cspell.yml files that don't have any dictionaries, ignorePaths, words and ignoreWords entries.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module ./submodules/Linters/linters-powershell/Linters.psd1
    Test-CSpellConfiguration -Verbose
#>

function Test-CSpellConfiguration {

    [CmdletBinding()]
    param()

    Write-Verbose "##[debug]Running Test-CSpellConfiguration..."

    if (-Not (Test-Path -LiteralPath ./cspell.yml)) {
        Write-Information "##[warning]No cspell.yml file found at current directory! Please check if this is expected!"
        return
    }

    Write-Information "##[command]Retrieving contents of cspell.yml..."
    $cspellFileContents = @(Get-Content -LiteralPath ./cspell.yml)

    Write-Information "##[command]Checking cspell.yml file..."
    $lintingErrors = @()

    # The below if statements will cause an exception if the file is empty or only a single line. This is fine as the config
    # file is in a useless state if it is empty or only contains a single line, and thus isn't an allowed state.
    if ($cspellFileContents[0] -ne "version: ""0.2""") {
        $lintingErrors += @{lineNumber = 1; line = "'$($cspellFileContents[0])'"; errorMessage = "Invalid version number. Expected 'version: ""0.2""'." }
    }

    if ($cspellFileContents[1] -ne "language: en-gb") {
        $lintingErrors += @{lineNumber = 2; line = "'$($cspellFileContents[1])'"; errorMessage = "Invalid language. Expected 'language: en-gb'." }
    }

    Write-Information "##[command]Retrieving 'dictionaries', 'ignorePaths', 'words' and 'ignoreWords'..."
    $expectedOrderOfKeys = @("version", "language", "dictionaries", "ignorePaths", "words", "ignoreWords")
    $orderOfKeys = @()

    $cspellDictionaries = @()
    $cspellIgnorePaths = @()
    $cspellWords = @()
    $cspellIgnoreWords = @()

    for ($index = 0; $index -lt $cspellFileContents.Length; $index++) {

        $currentLine = $cspellFileContents[$index]
        $currentLineNumber = $index + 1

        if ($currentLine -eq "") {
            Write-Verbose "##[debug]Current line is blank: '$currentLine'"
            $lintingErrors += @{lineNumber = $currentLineNumber; line = "'$currentLine'"; errorMessage = "Invalid empty line." }
            continue
        }

        $key = $currentLine | Select-String -Pattern "^[a-zA-Z]+"

        if ($null -eq $key) {

            switch ($currentKey) {
                dictionaries {
                    Write-Verbose "##[debug]Current line is a 'dictionaries' entry: '$currentLine'"

                    # Assumes an indentation of four characters
                    $entry = $currentLine.TrimStart("    - ")

                    if ($cspellDictionaries.Contains($entry)) {
                        $lintingErrors += @{lineNumber = $currentLineNumber; line = "'$currentLine'"; errorMessage = "Duplicate entry within 'dictionaries'." }
                    }

                    $cspellDictionaries += $entry
                }

                ignorePaths {
                    Write-Verbose "##[debug]Current line is an 'ignorePaths' entry: '$currentLine'"

                    # Assumes an indentation of four characters
                    $entry = $currentLine.TrimStart("    - ")

                    if ($cspellIgnorePaths.Contains($entry)) {
                        $lintingErrors += @{lineNumber = $currentLineNumber; line = "'$currentLine'"; errorMessage = "Duplicate entry within 'ignorePaths'." }
                    }

                    $cspellIgnorePaths += $entry
                }

                words {
                    Write-Verbose "##[debug]Current line is a 'words' entry: '$currentLine'"

                    # Assumes an indentation of four characters
                    $entry = $currentLine.TrimStart("    - ")
                    $entryLowerCase = $entry.ToLower()

                    if ($entry -CMatch "[A-Z]") {
                        $lintingErrors += @{lineNumber = $currentLineNumber; line = "'$currentLine'"; errorMessage = "Entry is not lowercase." }
                    }

                    if ($cspellWords.Contains($entryLowerCase)) {
                        $lintingErrors += @{lineNumber = $currentLineNumber; line = "'$currentLine'"; errorMessage = "Duplicate entry within 'words'." }
                    }

                    $cspellWords += $entryLowerCase
                }

                ignoreWords {
                    Write-Verbose "##[debug]Current line is an 'ignoreWords' entry: '$currentLine'"

                    # Assumes an indentation of four characters
                    $entry = $currentLine.TrimStart("    - ")
                    $entryLowerCase = $entry.ToLower()

                    if ($entry -CMatch "[A-Z]") {
                        $lintingErrors += @{lineNumber = $currentLineNumber; line = "'$currentLine'"; errorMessage = "Entry is not lowercase." }
                    }

                    if ($cspellIgnoreWords.Contains($entryLowerCase)) {
                        $lintingErrors += @{lineNumber = $currentLineNumber; line = "'$currentLine'"; errorMessage = "Duplicate entry within 'ignoreWords'." }
                    }

                    $cspellIgnoreWords += $entryLowerCase
                }

                default {
                    Write-Verbose "##[debug]Current line is an entry for an unexpected key: '$currentLine'"

                    $lintingErrors += @{lineNumber = $currentLineNumber; line = "'$currentLine'"; errorMessage = "Entry for an invalid key." }
                }
            }
        }

        else {
            Write-Verbose "##[debug]Current line is a key: '$currentLine'"

            $currentKey = $key.Matches[0].Value

            if (-Not $expectedOrderOfKeys.Contains($currentKey)) {
                $lintingErrors += @{lineNumber = $currentLineNumber; line = "'$currentLine'"; errorMessage = "Invalid key." }
            }

            $orderOfKeys += $currentKey
        }
    }

    if (Compare-ObjectExact -ReferenceObject $expectedOrderOfKeys -DifferenceObject $orderOfKeys) {
        $lintingErrors += @{lineNumber = "-"; line = "-"; errorMessage = "Keys are missing, incorrectly ordered, incorrectly cased, or contain an unexpected key. Expected the following order of keys: 'version', 'language', 'dictionaries', 'ignorePaths', 'words', 'ignoreWords'." }
    }

    Write-Information "##[command]Checking 'dictionaries', 'ignorePaths', 'words' and 'ignoreWords' are alphabetically ordered..."

    if (Compare-ObjectExact -ReferenceObject ($cspellDictionaries | Sort-Object) -DifferenceObject $cspellDictionaries) {
        $lintingErrors += @{lineNumber = "-"; line = "-"; errorMessage = "'dictionaries' is not alphabetically ordered." }
    }

    if (Compare-ObjectExact -ReferenceObject ($cspellIgnorePaths | Sort-Object) -DifferenceObject $cspellIgnorePaths) {
        $lintingErrors += @{lineNumber = "-"; line = "-"; errorMessage = "'ignorePaths' is not alphabetically ordered." }
    }

    if (Compare-ObjectExact -ReferenceObject ($cspellWords | Sort-Object) -DifferenceObject $cspellWords) {
        $lintingErrors += @{lineNumber = "-"; line = "-"; errorMessage = "'words' is not alphabetically ordered." }
    }

    if (Compare-ObjectExact -ReferenceObject ($cspellIgnoreWords | Sort-Object) -DifferenceObject $cspellIgnoreWords) {
        $lintingErrors += @{lineNumber = "-"; line = "-"; errorMessage = "'ignoreWords' is not alphabetically ordered." }
    }

    Write-Information "##[command]Checking 'ignorePaths' matches the .gitignore file..."

    if (-Not (Test-Path -LiteralPath ./.gitignore)) {
        Write-Information "##[warning]No .gitignore file found at current directory! Please check if this is expected!"
        $gitignoreFileContents = @()
    }

    else {
        $gitignoreFileContents = @(Get-Content -LiteralPath ./.gitignore)
    }

    # Add package-lock.json and re-sort gitattributes
    [Collections.Generic.List[String]] $cspellIgnorePathsList = $cspellIgnorePaths
    $cspellIgnorePathsList.Remove("package-lock.json") | Out-Null
    $cspellIgnorePathsList.Remove("docs/html/") | Out-Null

    if (Compare-ObjectExact -ReferenceObject ($gitignoreFileContents | Sort-Object) -DifferenceObject $cspellIgnorePathsList) {
        $lintingErrors += @{lineNumber = "-"; line = "-"; errorMessage = "'ignorePaths' does not match the entries in .gitignore." }
    }

    Write-Information "##[command]Checking if 'words' are found in 'ignoreWords'..."

    # Re-iterate over cspell file to give line number context
    for ($index = 0; $index -lt $cspellFileContents.Length; $index++) {

        $currentLine = $cspellFileContents[$index]
        $currentLineNumber = $index + 1

        $key = $currentLine | Select-String -Pattern "^[a-zA-Z]+"

        if ($null -eq $key) {

            if ($currentKey -eq "words") {

                # Assumes an indentation of four characters
                $entry = $currentLine.TrimStart("    - ").ToLower()

                if ($cspellIgnoreWords.Contains($entry)) {
                    $lintingErrors += @{lineNumber = $currentLineNumber; line = "'$currentLine'"; errorMessage = "'words' entry also found in 'ignoreWords'." }
                }
            }
        }

        else {
            $currentKey = $key.Matches[0].Value
        }
    }

    Write-Information "##[command]Checking for redundant 'words' and 'ignoreWords'..."

    Write-Verbose "##[debug]Retrieving all files to check..."
    # Same file list as found in Test-CodeUsingCSpell but also exclude cspell.yml (assumes cspell.yml is the only file with a file name of cspell)
    $allFilesToCheck = Get-FilteredFilePathsToTest -DirectoryFilterType "Exclude" -DirectoryNameFilterList @("docs/html") -FileNameFilterType "Exclude" -FileNameFilterList @("cspell", "package-lock") -ExcludeBinaryFiles

    [Collections.Generic.List[String]] $redundantCSpellWords = $cspellWords
    [Collections.Generic.List[String]] $redundantCSpellIgnoreWords = $cspellIgnoreWords

    foreach ($file in $allFilesToCheck) {

        Write-Verbose "##[debug]Reading contents of '$file'..."

        $fileContents = @(Get-Content -LiteralPath $file)

        foreach ($line in $fileContents) {

            for ($index = 0; $index -lt $redundantCSpellWords.Count; $index++) {

                $result = Select-String -InputObject $line -SimpleMatch $redundantCSpellWords[$index]

                if ($null -ne $result) {
                    if ($redundantCSpellWords.Contains($redundantCSpellWords[$index])) {
                        $redundantCSpellWords.RemoveAt($index)
                        $index--
                    }
                }
            }

            for ($index = 0; $index -lt $redundantCSpellIgnoreWords.Count; $index++) {

                $result = Select-String -InputObject $line -SimpleMatch $redundantCSpellIgnoreWords[$index]

                if ($null -ne $result) {
                    if ($redundantCSpellIgnoreWords.Contains($redundantCSpellIgnoreWords[$index])) {
                        $redundantCSpellIgnoreWords.RemoveAt($index)
                        $index--
                    }
                }
            }
        }
    }

    if ($redundantCSpellWords.Count -gt 0) {
        $lintingErrors += @{lineNumber = "-"; line = "-"; errorMessage = "The following 'words' are redundant: $($redundantCSpellWords | ForEach-Object { "'$_'" })" }
    }

    if ($redundantCSpellIgnoreWords.Count -gt 0) {
        $lintingErrors += @{lineNumber = "-"; line = "-"; errorMessage = "The following 'ignoreWords' are redundant: $($redundantCSpellIgnoreWords | ForEach-Object { "'$_'" })" }
    }

    if ($lintingErrors.Length -gt 0) {
        $lintingErrors | Sort-Object { $_.lineNumber }, { $_.errorMessage } | ForEach-Object { [PSCustomObject]$_ } | Format-Table -AutoSize -Wrap -Property lineNumber, line, errorMessage
        Write-Error "##[error]Please resolve the above errors!"
    }

    else {
        Write-Output "##[section]All cspell.yml tests passed!"
    }
}

<#
    .SYNOPSIS
    Check that the comitted doxygen documentation is up to date.

    .DESCRIPTION
    Assumes doxygen is already installed.

    .PARAMETER ResetLocalGitChanges
    Specifies whether to reset local git changes before comparing for doxygen documentation git differences.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module ./submodules/Linters/linters-powershell/Linters.psd1
    Test-DoxygenDocumentation -ResetLocalGitChanges -Verbose
#>

function Test-DoxygenDocumentation {

    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $false)]
        [switch]
        $ResetLocalGitChanges = $false
    )

    Write-Verbose "##[debug]Running Test-DoxygenDocumentation..."

    if (-Not (Test-Path -LiteralPath ./Doxyfile)) {
        Write-Information "##[warning]No Doxyfile file found at current directory! Please check if this is expected!"
        return
    }

    Write-Verbose "##[debug]Using the following doxygen version..."
    (doxygen --version) | ForEach-Object { "##[debug]$_" } | Write-Verbose

    if ($ResetLocalGitChanges) {

        Write-Information "##[command]Performing git clean..."
        & git clean --force -d -x
        Assert-ExternalCommandError -ThrowError

        Write-Information "##[command]Performing git reset..."
        git reset --hard
        Assert-ExternalCommandError -ThrowError
    }

    Write-Information "##[command]Running doxygen..."
    & doxygen ./Doxyfile
    Assert-ExternalCommandError -ThrowError

    Write-Information "##[command]Checking for git differences..."
    & git update-index --really-refresh
    if (Assert-ExternalCommandError) {
        Write-Error "##[error]Comitted doxygen documentation is not up to date. Please check the above list of files which differ!"
    }

    Write-Output "##[section]Comitted doxygen documentation is up to date!"
}

<#
    .SYNOPSIS
    Lints the .gitattributes file.

    .DESCRIPTION
    Raises an error if linting issues are found for the following issues:
        - Duplicate empty lines
        - Duplicate entries
        - Redundant entries
        - Malformed entries
        - Missing entries

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module ./submodules/Linters/linters-powershell/Linters.psd1
    Test-GitattributesFile -Verbose
#>

function Test-GitAttributesFile {

    [CmdletBinding()]
    param()

    Write-Verbose "##[debug]Running Test-GitattributesFile..."

    if (-Not (Test-Path -LiteralPath ./.gitattributes)) {
        Write-Information "##[warning]No .gitattributes file found at current directory! Please check if this is expected!"
        return
    }

    Write-Information "##[command]Retrieving contents of .gitattributes..."
    $gitattributesFileContents = @(Get-Content -LiteralPath ./.gitattributes)

    Write-Information "##[command]Retrieving all unique file extensions and unique files without a file extension..."
    $gitTrackedFiles = git ls-files -c | ForEach-Object { if (-Not $_.StartsWith("submodules")) { $_ } } | Split-Path -Leaf # Exclude submodules

    $uniqueGitTrackedFileExtensions = $gitTrackedFiles | ForEach-Object { if ($_.Split(".").Length -gt 1) { "\.$($_.Split(".")[-1])" } } | Sort-Object | Select-Object -Unique
    $uniqueGitTrackedFileNamesWithoutExtensions = $gitTrackedFiles | ForEach-Object { if ($_.Split(".").Length -eq 1) { $_ } } | Sort-Object | Select-Object -Unique

    # Null coalesce to empty arrays
    if ($null -eq $uniqueGitTrackedFileExtensions) {
        $uniqueGitTrackedFileExtensions = @()
    }

    if ($null -eq $uniqueGitTrackedFileNamesWithoutExtensions) {
        $uniqueGitTrackedFileNamesWithoutExtensions = @()
    }

    Write-Verbose "##[debug]Retrieved unique file extensions:"
    $uniqueGitTrackedFileExtensions | ForEach-Object { Write-Verbose "##[debug]$($_.TrimStart("\"))" }

    Write-Verbose "##[debug]Retrieved unique files without a file extension:"
    $uniqueGitTrackedFileNamesWithoutExtensions | ForEach-Object { Write-Verbose "##[debug]$_" }

    $uniqueGitTrackedFileExtensionsAndFileNamesWithoutExtensions = $uniqueGitTrackedFileExtensions + $uniqueGitTrackedFileNamesWithoutExtensions

    Write-Information "##[command]Checking formatting of .gitattributes file..."
    $lintingErrors = @()
    $foundEntries = @()
    $previousLineWasBlank = $false
    $gitattributesFileContentsWithoutComments = @()

    for ($index = 0; $index -lt $gitattributesFileContents.Length; $index++) {

        $currentLine = $gitattributesFileContents[$index]
        $currentLineNumber = $index + 1

        if ($currentLine -eq "") {
            Write-Verbose "##[debug]Current line is blank: '$currentLine'"

            if ($previousLineWasBlank) {
                $lintingErrors += @{lineNumber = $currentLineNumber; line = "'$currentLine'"; errorMessage = "Duplicate blank line." }
            }

            $previousLineWasBlank = $true
            continue
        }

        # Match every before and including '#'
        $lineBeforeAndIncludingComment = $currentLine | Select-String -Pattern ".*#"

        if ($null -eq $lineBeforeAndIncludingComment) {
            Write-Verbose "##[debug]Current line is code: '$currentLine'"

            if (-Not (
                    $currentLine -Match "^\* +text=auto +eol=lf$" -or
                    # File extensions with or without * wildcard
                    $currentLine -Match "^\*?\.[a-z0-9-]+ +binary$" -or
                    $currentLine -Match "^\*?\.[a-z0-9-]+ +text$" -or
                    $currentLine -Match "^\*?\.[a-z0-9-]+ +text +eol=[a-z]+$" -or
                    $currentLine -Match "^\*?\.[a-z0-9-]+ +text +diff=[a-z]+$" -or
                    $currentLine -Match "^\*?\.[a-z0-9-]+ +text +eol=[a-z]+ +diff=[a-z]+$" -or
                    # Files without an extension
                    $currentLine -Match "^[a-zA-Z0-9-]+ +binary$" -or
                    $currentLine -Match "^[a-zA-Z0-9-]+ +text$" -or
                    $currentLine -Match "^[a-zA-Z0-9-]+ +text +eol=[a-z]+$" -or
                    $currentLine -Match "^[a-zA-Z0-9-]+ +text +diff=[a-z]+$" -or
                    $currentLine -Match "^[a-zA-Z0-9-]+ +text +eol=[a-z]+ +diff=[a-z]+$"
                )) {
                $lintingErrors += @{lineNumber = $currentLineNumber; line = "'$currentLine'"; errorMessage = "Non-comment lines must match one of the following: '* text=auto', '[FILE]/[FILE EXTENSION] binary', '[FILE]/[FILE EXTENSION] text', '[FILE]/[FILE EXTENSION] text eol=[TEXT]', '[FILE]/[FILE EXTENSION] text diff=[TEXT]' or '[FILE]/[FILE EXTENSION] text eol=[TEXT] diff=[TEXT]'." }
            }

            else {
                # Used to check for missing entries later
                $gitattributesFileContentsWithoutComments += $currentLine

                # Check for duplicate and redundant entries
                $fileExtensionOrFileWithoutExtension = $currentLine | Select-String -Pattern "(^\*?\.[a-z0-9-]+)|^[a-zA-Z0-9-]+"

                if ($null -ne $fileExtensionOrFileWithoutExtension) {
                    $entry = $fileExtensionOrFileWithoutExtension.Matches.Value

                    if ($uniqueGitTrackedFileExtensions.Contains("\$($entry.TrimStart("*"))") -or
                        $uniqueGitTrackedFileNamesWithoutExtensions.Contains($entry)) {

                        if ($foundEntries.Contains($entry) -or
                            $foundEntries.Contains($entry)) {
                            $lintingErrors += @{lineNumber = $currentLineNumber; line = "'$currentLine'"; errorMessage = "Duplicate entry." }
                        }

                        else {
                            $foundEntries += $entry
                        }
                    }

                    else {
                        $lintingErrors += @{lineNumber = $currentLineNumber; line = "'$currentLine'"; errorMessage = "Redundant entry." }
                    }
                }
            }
        }

        elseif ($lineBeforeAndIncludingComment.Matches.Value.Length -eq 1) {
            Write-Verbose "##[debug]Current line is comment: '$currentLine'"
        }

        else {
            Write-Verbose "##[debug]Current line is a mixture of comment and code: '$currentLine'"
            $lintingErrors += @{lineNumber = $currentLineNumber; line = "'$currentLine'"; errorMessage = "Lines must be blank, entirely comment or entirely non-comment." }
        }

        $previousLineWasBlank = $false
    }

    Write-Information "##[command]Checking all unique file extensions and files without extensions have a .gitattributes entry:"

    foreach ($fileExtensionOrFileNameWithoutExtension in $uniqueGitTrackedFileExtensionsAndFileNamesWithoutExtensions) {

        $foundMatch = $false

        foreach ($line in $gitattributesFileContentsWithoutComments) {

            if ($line -Match $fileExtensionOrFileNameWithoutExtension ) {
                Write-Verbose "##[debug]$fileExtension entry found in: '$line'"
                $foundMatch = $true
                break
            }
        }

        if (-Not $foundMatch) {
            $lintingErrors += @{lineNumber = "-"; line = "-"; errorMessage = "'$($fileExtensionOrFileNameWithoutExtension.TrimStart("\"))' does not have a .gitattributes entry." }
        }
    }

    if ($lintingErrors.Length -gt 0) {
        $lintingErrors | Sort-Object { $_.lineNumber }, { $_.errorMessage } | ForEach-Object { [PSCustomObject]$_ } | Format-Table -AutoSize -Wrap -Property lineNumber, line, errorMessage
        Write-Error "##[error]Please resolve the above errors!"
    }

    else {
        Write-Output "##[section]All .gitattributes tests passed!"
    }
}

<#
    .SYNOPSIS
    Lints the .gitignore file.

    .DESCRIPTION
    Raises an error if linting issues are found for the following issues:
        - Duplicate empty lines
        - Duplicate entries
        - Not alphabetically ordered

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module ./submodules/Linters/linters-powershell/Linters.psd1
    Test-GitIgnoreFile -Verbose
#>

function Test-GitIgnoreFile {

    [CmdletBinding()]
    param()

    Write-Verbose "##[debug]Running Test-GitIgnoreFile..."

    if (-Not (Test-Path -LiteralPath ./.gitignore)) {
        Write-Information "##[warning]No .gitignore file found at current directory! Please check if this is expected!"
        return
    }

    Write-Information "##[command]Retrieving contents of .gitignore..."
    $gitignoreFileContents = @(Get-Content -LiteralPath ./.gitignore)

    Write-Information "##[command]Checking formatting of .gitignore file..."
    $lintingErrors = @()
    $foundEntries = @()

    for ($index = 0; $index -lt $gitignoreFileContents.Length; $index++) {

        $currentLine = $gitignoreFileContents[$index]
        $currentLineNumber = $index + 1

        if ($currentLine -eq "") {
            Write-Verbose "##[debug]Current line is blank: '$currentLine'"

            if ($previousLineWasBlank) {
                $lintingErrors += @{lineNumber = $currentLineNumber; line = "'$currentLine'"; errorMessage = "Duplicate blank line." }
            }

            $previousLineWasBlank = $true
        }

        else {
            # Match every before and including '#'
            $lineBeforeAndIncludingComment = $currentLine | Select-String -Pattern ".*#"

            if ($null -eq $lineBeforeAndIncludingComment) {
                Write-Verbose "##[debug]Current line is code: '$currentLine'"

                if ($foundEntries.Contains($currentLine)) {
                    $lintingErrors += @{lineNumber = $currentLineNumber; line = "'$currentLine'"; errorMessage = "Duplicate entry." }
                }

                $foundEntries += $currentLine
            }

            elseif ($lineBeforeAndIncludingComment.Matches.Value.Length -eq 1) {
                Write-Verbose "##[debug]Current line is comment: '$currentLine'"
            }

            else {
                Write-Verbose "##[debug]Current line is a mixture of comment and code: '$line'"
                $lintingErrors += @{lineNumber = $currentLineNumber; line = "'$currentLine'"; errorMessage = "Line must be blank, entirely comment or entirely non-comment." }
            }

            $previousLineWasBlank = $false
        }
    }

    Write-Information "##[command]Checking all entries are alphabetically ordered..."

    if ($foundEntries.Length -gt 1) {

        $foundEntriesSorted = $foundEntries | Sort-Object

        if (Compare-ObjectExact -ReferenceObject $foundEntriesSorted -DifferenceObject $foundEntries) {
            $lintingErrors += @{lineNumber = "-"; line = "-"; errorMessage = "Entries are not alphabetically ordered." }
        }
    }

    if ($lintingErrors.Length -gt 0) {
        $lintingErrors | Sort-Object { $_.lineNumber }, { $_.errorMessage } | ForEach-Object { [PSCustomObject]$_ } | Format-Table -AutoSize -Wrap -Property lineNumber, line, errorMessage
        Write-Error "##[error]Please resolve the above errors!"
    }

    else {
        Write-Output "##[section]All .gitignore tests passed!"
    }
}
