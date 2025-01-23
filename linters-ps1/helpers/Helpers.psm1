$ErrorActionPreference = "Stop"

<#
    .SYNOPSIS
    Asserts whether an error when an external function has thrown an error via LASTEXITCODE.

    .DESCRIPTION
    This function must be called immediately after the external function call.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module ./modules/TerminalGames.psd1
    npm install
    Assert-ExternalCommandError -ThrowError -Verbose
#>

function Assert-ExternalCommandError {

    [CmdletBinding()]
    [OutputType([system.boolean])]
    param(
        [Parameter(Position=0, Mandatory=$false)]
        [switch]
        $ThrowError
    )

    Write-Verbose "##[debug]Running Assert-ExternalCommandError..."
    Write-Verbose "##[debug]Parameters:"
    Write-Verbose "##[debug]    ThrowError: $ThrowError"

    if ($LASTEXITCODE -eq 1) {
        if ($ThrowError) {
            Write-Error "Please resolve the above errors!"
        }

        else {
            return $true
        }
    }

    elseif (-Not $ThrowError) {
        return $false
    }
}

<#
    .SYNOPSIS
    Gets all git tracked files.

    .DESCRIPTION
    None.

    .INPUTS
    None.

    .OUTPUTS
    system.object[] A list of file paths (relative to the root of the repository).


    .EXAMPLE
    Import-Module ./modules/TerminalGames.psd1
    Get-AllFilePathsToTest -Verbose
#>

function Get-AllFilePathsToTest {

    [CmdletBinding()]
    [OutputType([system.object[]])]
    param()

    $allFilesToTest = Get-FilteredFilePathsToTest -FileExtensionFilter "Exclude" -FileExtensions @("") -FileNameFilter "Exclude" -FileNames @("") -Verbose

    Write-Verbose "##[debug]Returning:"
    $allFilesToTest | ForEach-Object { "##[debug]    $_" } | Write-Verbose

    return $allFilesToTest
}

<#
    .SYNOPSIS
    Gets all git tracked files using various filters.

    .DESCRIPTION
    None.

    .INPUTS
    string FileExtensionFilter. Whether to include or exclude the FileExtensions in the search.

    system.object[] FileExtensions. The file extensions to either include or exclude depending upon the value of
    FileExtensionFilter.

    string FileNameFilter. Whether to include or exclude the FileNames in the search.

    system.object[] FileNames. The file names (without file extension) to either include or exclude depending upon the value of
    FileNameFilter.

    .OUTPUTS
    system.object[] A list of file paths (relative to the root of the repository).

    .EXAMPLE
    Import-Module ./modules/TerminalGames.psd1
    Get-FilteredFilePathsToTest -FileExtensionFilter "Include" -FileExtensions @("json", "md", "yml") -FileNameFilter "Exclude" -FileNames @("package-lock") -Verbose
#>

function Get-FilteredFilePathsToTest {

    [CmdletBinding()]
    [OutputType([system.object[]])]
    param(
        [Parameter(Position=0, Mandatory=$false, ParameterSetName="FileExtensionSearch")]
        [Parameter(Position=0, Mandatory=$false, ParameterSetName="FileExtensionAndFileNameSearch")]
        [ValidateSet("Include", "Exclude")]
        [string]
        $FileExtensionFilter,

        [Parameter(Position=1, Mandatory=$true, ParameterSetName="FileExtensionSearch")]
        [Parameter(Position=1, Mandatory=$true, ParameterSetName="FileExtensionAndFileNameSearch")]
        [system.object[]]
        $FileExtensions,

        [Parameter(Position=2, Mandatory=$false, ParameterSetName="FileNameSearch")]
        [Parameter(Position=2, Mandatory=$false, ParameterSetName="FileExtensionAndFileNameSearch")]
        [ValidateSet("Include", "Exclude")]
        [string]
        $FileNameFilter,

        [Parameter(Position=3, Mandatory=$true, ParameterSetName="FileNameSearch")]
        [Parameter(Position=3, Mandatory=$true, ParameterSetName="FileExtensionAndFileNameSearch")]
        [system.object[]]
        $FileNames
    )

    Write-Verbose "##[debug]Running Get-FilteredFilePathsToTest..."
    Write-Verbose "##[debug]Parameters:"
    Write-Verbose "##[debug]    FileExtensionFilter: $FileExtensionFilter"
    Write-Verbose "##[debug]    FileExtensions:"
    $FileExtensions | ForEach-Object { "##[debug]        $_" } | Write-Verbose
    Write-Verbose "##[debug]    FileNameFilter: $FileNameFilter"
    Write-Verbose "##[debug]    FileNames:"
    $FileNames | ForEach-Object { "##[debug]        $_" } | Write-Verbose

    if ($FileExtensionFilter -eq "Include") {

        if ($FileNameFilter -eq "Include") {
            $filteredFilesToTest = git ls-files -c | ForEach-Object { if (($_.Split(".")[-1] -In $FileExtensions) -And ($_.Split(".")[-2] -In $FileNames)) { $_ } }
        }

        else {
            $filteredFilesToTest = git ls-files -c | ForEach-Object { if (($_.Split(".")[-1] -In $FileExtensions) -And ($_.Split(".")[-2] -NotIn $FileNames)) { $_ } }
        }
    }

    else {

        if ($FileNameFilter -eq "Include") {
            $filteredFilesToTest = git ls-files -c | ForEach-Object { if (($_.Split(".")[-1] -NotIn $FileExtensions) -And ($_.Split(".")[-2] -In $FileNames)) { $_ } }
        }

        else {
            $filteredFilesToTest = git ls-files -c | ForEach-Object { if (($_.Split(".")[-1] -NotIn $FileExtensions) -And ($_.Split(".")[-2] -NotIn $FileNames)) { $_ } }
        }
    }

    Assert-ExternalCommandError -ThrowError

    Write-Verbose "##[debug]Returning:"
    $filteredFilesToTest | ForEach-Object { "##[debug]    $_" } | Write-Verbose

    return $filteredFilesToTest
}

<#
    .SYNOPSIS
    Compares two objects.

    .DESCRIPTION
    Compare-Object was not sufficient as it disregards the order of the DifferenceObject.

    .INPUTS
    system.object[] ReferenceObject. Specifies an array of objects used as a reference for comparison.

    system.object[] DifferenceObject. Specifies the objects that are compared to the reference objects.

    .OUTPUTS
    system.object[] A list of error messages.

    .EXAMPLE
    Import-Module ./modules/TerminalGames.psd1

    $arrayOne = @(1,2,3)
    $arrayTwo = @(1,3,2)

    Compare-ObjectExact -ReferenceObject $arrayOne -DifferenceObject $arrayTwo -Verbose
#>

function Compare-ObjectExact {

    [CmdletBinding()]
    [OutputType([system.object[]])]
    param(
        [Parameter(Position=0, Mandatory=$true)]
        [system.object[]]
        $ReferenceObject,

        [Parameter(Position=1, Mandatory=$true)]
        [system.object[]]
        $DifferenceObject
    )

    Write-Verbose "##[debug]Running Compare-ObjectExact..."
    Write-Verbose "##[debug]Parameters:"
    Write-Verbose "##[debug]    ReferenceObject:"
    $ReferenceObject | ForEach-Object { "##[debug]        $_" } | Write-Verbose
    Write-Verbose "##[debug]    DifferenceObject:"
    $DifferenceObject | ForEach-Object { "##[debug]        $_" } | Write-Verbose

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
    $errors | ForEach-Object { "##[debug]    $_" } | Write-Verbose

    return $errors
}

<#
    .SYNOPSIS
    Runs all linting checks found in the continuos integration workflow.

    .DESCRIPTION
    Intended to be used during development to manually check for linting issues before pushing a commit.
    Raises an error at the first occurrence of a linting error.

    .INPUTS

    [switch] FixClangTidyErrors. Whether to use clang-tidy to automatically fix any fixable errors.

    [switch] FixClangFormatErrors. Whether to use clang-format to automatically fix any fixable errors.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module ./modules/TerminalGames.psd1
    Test-CodeUsingAllLinting -FixClangTidyErrors -FixClangFormatErrors -Verbose
#>

function Test-CodeUsingAllLinters {

    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=$false)]
        [switch]
        $FixClangTidyErrors,

        [Parameter(Position=1, Mandatory=$false)]
        [switch]
        $FixClangFormatErrors
    )

    Write-Output "##[section]Running Test-CodeUsingAllLinting..."
    Write-Verbose "##[debug]Parameters:"
    Write-Verbose "##[debug]    FixClangTidyErrors: $FixClangTidyErrors"
    Write-Verbose "##[debug]    FixClangFormatErrors: $FixClangFormatErrors"

    Test-GitIgnoreFile -Verbose

    Test-GitAttributesFile -Verbose

    Test-CSpellConfigurationFile -Verbose

    Test-PrettierIgnoreFile -Verbose

    Test-CodeUsingCSpell -Verbose

    Test-CodeUsingPrettier -Verbose

    Test-CodeUsingPSScriptAnalyzer -Verbose

    Test-CodeUsingClang -FixClangTidyErrors:$FixClangTidyErrors -FixClangFormatErrors:$FixClangFormatErrors -Verbose

    Write-Output "##[section]All linting tests passed!"
}

<#
    .SYNOPSIS
    Wrapper around clang-tidy and clang-format.

    .DESCRIPTION
    Runs clang-tidy and clang-format against all git-tracked C++ files (*.cpp and *.hpp).
    CMake must be configured in the ./build/ directory as the 'compile_commands.json' file is needed by clang-tidy.
    Raises an error if linting errors found.

    .INPUTS
    [switch] FixClangTidyErrors. Whether to use clang-tidy to automatically fix any fixable errors.

    [switch] FixClangFormatErrors. Whether to use clang-format to automatically fix any fixable errors.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module ./modules/TerminalGames.psd1
    Test-CodeUsingClang -FixClangTidyErrors -FixClangFormatErrors -Verbose
#>

function Test-CodeUsingClang {

    [CmdletBinding()]
    param
    (
        [Parameter(Position=0, Mandatory=$false)]
        [switch]
        $FixClangTidyErrors,

        [Parameter(Position=1, Mandatory=$false)]
        [switch]
        $FixClangFormatErrors
    )

    Write-Output "##[section]Running Test-CodeUsingClang..."
    Write-Verbose "##[debug]Parameters:"
    Write-Verbose "##[debug]    FixClangTidyErrors: $FixClangTidyErrors"
    Write-Verbose "##[debug]    FixClangFormatErrors: $FixClangFormatErrors"

    Write-Verbose "##[debug]Using the following clang-tidy version..."
    (clang-tidy --version) | ForEach-Object { "##[debug]$_" } | Write-Verbose

    Write-Verbose "##[debug]Using the following clang-format version..."
    (clang-format --version) | ForEach-Object { "##[debug]$_" } | Write-Verbose

    Write-Output "##[section]Retrieving all files to test against clang-tidy and clang-format..."
    $filesToTest = Get-FilteredFilePathsToTest -FileExtensionFilter "Include" -FileExtensions @("cpp", "hpp") -Verbose

    $filesWithErrors = @()

    foreach ($file in $filesToTest) {

        $ErrorActionPreference = "Continue"

        Write-Output "##[section]Running clang-tidy against '$file'..."
        (clang-tidy $file -p ./build 2>&1) | ForEach-Object { "##[debug]$_" } | Write-Verbose

        if (Assert-ExternalCommandError) {

            if ($FixClangTidyErrors) {
                Write-Verbose "##[debug]Fixing clang-tidy issues in '$file'..."
                (clang-tidy --fix $file -p ./build 2>&1) | ForEach-Object { "##[debug]$_" } | Write-Verbose

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

        Write-Output "##[section]Running clang-format against '$file'..."
        (clang-format --Werror --dry-run $file 2>&1) | ForEach-Object { "##[debug]$_" } | Write-Verbose

        if (Assert-ExternalCommandError) {

            if ($FixClangFormatErrors) {
                Write-Verbose "##[debug]Fixing clang-format issues in '$file'..."
                (clang-format --Werror --i $file 2>&1) | ForEach-Object { "##[debug]$_" } | Write-Verbose

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

        $ErrorActionPreference = "Stop"
    }

    if ($filesWithErrors.Length -gt 0) {
        Write-Verbose "##[debug]The following files do not conform to clang-tidy/clang-format standards:"
        $filesWithErrors | ForEach-Object { "##[debug]$_" } | Write-Verbose
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

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module ./modules/TerminalGames.psd1
    Test-CodeUsingCSpell -Verbose
#>

function Test-CodeUsingCSpell {

    [CmdletBinding()]
    param()

    Write-Output "##[section]Running Test-CodeUsingCSpell..."

    Write-Verbose "##[debug]Using the following cspell version..."
    (npx cspell --version) | ForEach-Object { "##[debug]$_" } | Write-Verbose

    Write-Output "##[section]Retrieving all files to test against cspell..."
    $filesToTest = Get-FilteredFilePathsToTest -FileExtensionFilter "Exclude" -FileExtensions @("ico", "png") -FileNameFilter "Exclude" @("package-lock") -Verbose

    $filesWithErrors = @()

    foreach ($file in $filesToTest) {

        Write-Output "##[section]Running cspell against '$file'..."

        (npx -c "cspell --unique --show-context --no-progress --no-summary $file") | ForEach-Object { "##[debug]$_" } | Write-Verbose

        if (Assert-ExternalCommandError) {
            $filesWithErrors += $file
        }
    }

    if ($filesWithErrors.Length -gt 0) {
        Write-Verbose "##[debug]The following files have cspell errors:"
        $filesWithErrors | ForEach-Object { "##[debug]$_" } | Write-Verbose
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

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module ./modules/TerminalGames.psd1
    Test-CodeUsingPrettier -Verbose
#>

function Test-CodeUsingPrettier {

    [CmdletBinding()]
    param()

    Write-Output "##[section]Running Test-CodeUsingPrettier..."

    Write-Verbose "##[debug]Using the following prettier version..."
    (npx prettier --version) | ForEach-Object { "##[debug]$_" } | Write-Verbose

    Write-Output "##[section]Retrieving all files to test against prettier..."
    $filesToTest = Get-FilteredFilePathsToTest -FileExtensionFilter "Include" -FileExtensions @("clang-format", "clang-tidy", "json", "md", "yml") -FileNameFilter "Exclude" @("package-lock") -Verbose

    $filesWithErrors = @()

    foreach ($file in $filesToTest) {

        Write-Output "##[section]Running prettier against '$file'..."

        (npx -c "prettier $file --debug-check") | ForEach-Object { "##[debug]$_" } | Write-Verbose

        if (Assert-ExternalCommandError) {
            $filesWithErrors += $file
        }
    }

    if ($filesWithErrors.Length -gt 0) {
        Write-Verbose "##[debug]The following files have prettier errors:"
        $filesWithErrors | ForEach-Object { "##[debug]$_" } | Write-Verbose
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

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module ./modules/TerminalGames.psd1
    Test-CodeUsingPSScriptAnalyzer -Verbose
#>

function Test-CodeUsingPSScriptAnalyzer {

    [CmdletBinding()]
    param()

    Write-Output "##[section]Running Test-CodeUsingPSScriptAnalyzer..."

    Write-Output "##[section]Retrieving all files to test against PSScriptAnalyzer..."
    $filesToTest = Get-FilteredFilePathsToTest -FileExtensionFilter "Include" -FileExtensions @("ps1", "psd1", "psm1") -Verbose

    $filesWithErrors = @()

    foreach ($file in $filesToTest) {

        Write-Output "##[section]Running PSScriptAnalyzer against '$file'..."

        Invoke-ScriptAnalyzer -Path $file -Settings ./PSScriptAnalyzerSettings.psd1
        $output = Invoke-ScriptAnalyzer -Path $file -Settings ./PSScriptAnalyzerSettings.psd1

        if ($output.Length -gt 0) {
            $filesWithErrors += $file
        }
    }

    if ($filesWithErrors.Length -gt 0) {
        Write-Verbose "##[debug]The following files have PSScriptAnalyzer errors:"
        $filesWithErrors | ForEach-Object { "##[debug]$_" } | Write-Verbose
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
    Import-Module ./modules/TerminalGames.psd1
    Test-CSpellConfigurationFile -Verbose
#>

function Test-CSpellConfigurationFile {

    [CmdletBinding()]
    param()

    Write-Output "##[section]Running Test-CSpellConfigurationFile..."

    Write-Output "##[section]Retrieving contents of cspell.yml..."
    $cspellFileContents = @(Get-Content -Path ./cspell.yml)
    Write-Verbose "##[debug]Finished retrieving the contents cspell.yml."

    Write-Output "##[section]Checking cspell.yml file..."
    $lintingErrors = @()

    # The below if statements will cause an exception if the file is empty or only a single line. This is fine as the config
    # file is in a useless state if it is empty or only contains a single line, and thus isn't an allowed state.
    if ($cspellFileContents[0] -ne "version: ""0.2""") {
        $lintingErrors += @{lineNumber = 1; line = "'$($cspellFileContents[0])'"; errorMessage = "Invalid version number. Expected 'version: ""0.2""'." }
    }

    if ($cspellFileContents[1] -ne "language: en-gb") {
        $lintingErrors += @{lineNumber = 2; line = "'$($cspellFileContents[1])'"; errorMessage = "Invalid language. Expected 'language: en-gb'." }
    }

    Write-Verbose "##[debug]Retrieving 'dictionaries', 'ignorePaths', 'words' and 'ignoreWords'..."
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

    Write-Verbose "##[debug]Retrieved entries 'dictionaries', 'ignorePaths', 'words' and 'ignoreWords'."

    if (Compare-ObjectExact -ReferenceObject $expectedOrderOfKeys -DifferenceObject $orderOfKeys -Verbose) {
        $lintingErrors += @{lineNumber = "-"; line = "-"; errorMessage = "Keys are missing, incorrectly ordered, incorrectly cased, or contain an unexpected key. Expected the following order of keys: 'version', 'language', 'dictionaries', 'ignorePaths', 'words', 'ignoreWords'." }
    }

    Write-Verbose "##[debug]Finished checking cspell.yml file."

    Write-Output "##[section]Checking 'dictionaries', 'ignorePaths', 'words' and 'ignoreWords' are alphabetically ordered..."

    if (Compare-ObjectExact -ReferenceObject ($cspellDictionaries | Sort-Object) -DifferenceObject $cspellDictionaries -Verbose) {
        $lintingErrors += @{lineNumber = "-"; line = "-"; errorMessage = "'dictionaries' is not alphabetically ordered." }
    }

    if (Compare-ObjectExact -ReferenceObject ($cspellIgnorePaths | Sort-Object) -DifferenceObject $cspellIgnorePaths -Verbose) {
        $lintingErrors += @{lineNumber = "-"; line = "-"; errorMessage = "'ignorePaths' is not alphabetically ordered." }
    }

    if (Compare-ObjectExact -ReferenceObject ($cspellWords | Sort-Object) -DifferenceObject $cspellWords -Verbose) {
        $lintingErrors += @{lineNumber = "-"; line = "-"; errorMessage = "'words' is not alphabetically ordered." }
    }

    if (Compare-ObjectExact -ReferenceObject ($cspellIgnoreWords | Sort-Object) -DifferenceObject $cspellIgnoreWords -Verbose) {
        $lintingErrors += @{lineNumber = "-"; line = "-"; errorMessage = "'ignoreWords' is not alphabetically ordered." }
    }

    Write-Verbose "##[debug]Finished checking 'ignorePaths', 'words' and 'ignoreWords' are alphabetically ordered."

    Write-Output "##[section]Checking 'ignorePaths' matches the .gitignore file..."

    if (-Not (Test-Path -Path "./.gitignore")) {
        Write-Output "##[debug]No gitignore file found at current directory!"
        $gitignoreFileContents = @()
    }

    else {
        $gitignoreFileContents = @(Get-Content -Path ./.gitignore)
    }

    # Add package-lock.json and re-sort gitattributes
    $gitignoreFileContents += "package-lock.json"

    if (Compare-ObjectExact -ReferenceObject ($gitignoreFileContents | Sort-Object) -DifferenceObject $cspellIgnorePaths -Verbose) {
        $lintingErrors += @{lineNumber = "-"; line = "-"; errorMessage = "'ignorePaths' does not match the entries in .gitignore." }
    }

    Write-Output "##[debug]Finished checking 'ignorePaths' matches the .gitignore file."

    Write-Output "##[section]Checking if 'words' are found in 'ignoreWords'..."

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

    Write-Verbose "##[debug]Finished checking if 'words' are found in 'ignoreWords'."

    Write-Output "##[section]Checking for redundant 'words' and 'ignoreWords'..."

    Write-Verbose "##[debug]Retrieving all files to check..."
    # Same file list as found in Test-CodeUsingCSpell but also exclude cspell.yml (assumes cspell.yml is the only file with a file name of cspell)
    $allFilesToCheck = @(Get-FilteredFilePathsToTest -FileExtensionFilter "Exclude" -FileExtensions @("ico", "png") -FileNameFilter "Exclude" -FileNames @("cspell", "package-lock") -Verbose)

    [Collections.Generic.List[String]] $redundantCSpellWords = $cspellWords
    [Collections.Generic.List[String]] $redundantCSpellIgnoreWords = $cspellIgnoreWords

    foreach ($file in $allFilesToCheck) {

        Write-Verbose "##[debug]Reading contents of '$file'..."

        $fileContents = @(Get-Content -Path $file)

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

    Write-Output "##[section]Finished checking for redundant 'words' and 'ignoreWords'."

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
    Import-Module ./modules/TerminalGames.psd1
    Test-GitattributesFile -Verbose
#>

function Test-GitAttributesFile {

    [CmdletBinding()]
    param()

    Write-Output "##[section]Running Test-GitattributesFile..."

    Write-Output "##[section]Retrieving contents of .gitattributes..."
    $gitattributesFileContents = @(Get-Content -Path ./.gitattributes)
    Write-Verbose "##[debug]Finished retrieving the contents .gitattributes."

    Write-Output "##[section]Retrieving all unique file extensions and unique files without a file extension..."
    $gitTrackedFiles = git ls-files -c | Split-Path -Leaf

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
    $uniqueGitTrackedFileExtensions | ForEach-Object { "##[debug]$($_.TrimStart("\"))" } | Write-Verbose

    Write-Verbose "##[debug]Retrieved unique files without a file extension:"
    $uniqueGitTrackedFileNamesWithoutExtensions | ForEach-Object { "##[debug]$_" } | Write-Verbose

    $uniqueGitTrackedFileExtensionsAndFileNamesWithoutExtensions = $uniqueGitTrackedFileExtensions + $uniqueGitTrackedFileNamesWithoutExtensions

    Write-Output "##[section]Checking .gitattributes file..."
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

    Write-Verbose "##[debug]Finished checking .gitattributes file."

    Write-Output "##[section]Checking all unique file extensions and files without extensions have a .gitattributes entry:"

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

    Write-Verbose "##[debug]Finished checking that all unique file extensions and files without extensions have a .gitattributes entry."

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
        - Redundant entries
        - Malformed entries
        - Not alphabetically ordered

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module ./modules/TerminalGames.psd1
    Test-GitIgnoreFile -Verbose
#>

function Test-GitIgnoreFile {

    [CmdletBinding()]
    param()

    Write-Output "##[section]Running Test-GitIgnoreFile..."

    if (-Not (Test-Path -Path "./.gitignore")) {
        Write-Output "##[section]No gitignore file found at current directory!"
        return
    }

    Write-Output "##[section]Retrieving contents of .gitignore..."
    $gitignoreFileContents = @(Get-Content -Path ./.gitignore)
    Write-Verbose "##[debug]Finished retrieving the contents .gitignore."

    Write-Output "##[section]Checking .gitignore file..."
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

                if (-Not (Test-Path -Path $currentLine) -And $currentLine -NotIn (".vs/", ".vscode/")) { # Exclude IDE directories
                    $lintingErrors += @{lineNumber = $currentLineNumber; line = "'$currentLine'"; errorMessage = "Redundant or malformed entry." }
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

    Write-Verbose "##[debug]Finished checking .gitignore file."

    Write-Output "##[section]Checking all entries are alphabetically ordered..."

    if ($foundEntries.Length -gt 1) {

        $foundEntriesSorted = $foundEntries | Sort-Object

        if (Compare-ObjectExact -ReferenceObject $foundEntriesSorted -DifferenceObject $foundEntries -Verbose) {
            $lintingErrors += @{lineNumber = "-"; line = "-"; errorMessage = "Entries are not alphabetically ordered." }
        }
    }

    Write-Verbose "##[debug]Finished checking all entries are alphabetically ordered."

    if ($lintingErrors.Length -gt 0) {
        $lintingErrors | Sort-Object { $_.lineNumber }, { $_.errorMessage } | ForEach-Object { [PSCustomObject]$_ } | Format-Table -AutoSize -Wrap -Property lineNumber, line, errorMessage
        Write-Error "##[error]Please resolve the above errors!"
    }

    else {
        Write-Output "##[section]All .gitignore tests passed!"
    }
}

<#
    .SYNOPSIS
    Lints the .prettierignore file.

    .DESCRIPTION
    Raises an error if .prettierignore does not match the .gitignore file (with exception of the package-lock.json file).

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module ./modules/TerminalGames.psd1
    Test-PrettierIgnoreFile -Verbose
#>

function Test-PrettierIgnoreFile {

    [CmdletBinding()]
    param()

    Write-Output "##[section]Running Test-PrettierIgnoreFile..."

    Write-Output "##[section]Retrieving contents of .prettierignore..."
    $prettierIgnoreFileContents = @(Get-Content -Path ./.prettierignore)
    Write-Verbose "##[debug]Finished retrieving the contents .prettierignore."

    Write-Output "##[section]Retrieving contents of .gitignore..."
    if (-Not (Test-Path -Path "./.gitignore")) {
        Write-Output "##[debug]No gitignore file found at current directory!"
        $gitignoreFileContents = @()
    }

    else {
        $gitignoreFileContents = @(Get-Content -Path ./.gitignore)
    }
    Write-Verbose "##[debug]Finished retrieving the contents .gitignore."

    Write-Output "##[section]Checking that .prettierignore matches .gitignore exactly..."
    $lintingErrors = @()

    # package-lock.json is the only exception.
    $gitignoreFileContents += "package-lock.json"
    $gitignoreFileContents = $gitignoreFileContents | Sort-Object

    if (Compare-ObjectExact -ReferenceObject $gitignoreFileContents -DifferenceObject $prettierIgnoreFileContents -Verbose) {
        $lintingErrors += @{lineNumber = "-"; line = "-"; errorMessage = ".prettierignore does not match .gitignore" }
    }

    Write-Verbose "##[debug]Finished checking that .prettierignore matches .gitignore exactly."

    if ($lintingErrors.Length -gt 0) {
        $lintingErrors | Sort-Object { $_.lineNumber }, { $_.errorMessage } | ForEach-Object { [PSCustomObject]$_ } | Format-Table -AutoSize -Wrap -Property lineNumber, line, errorMessage
        Write-Error "##[error]Please resolve the above errors!"
    }

    else {
        Write-Output "##[section]All .prettierignore tests passed!"
    }
}
