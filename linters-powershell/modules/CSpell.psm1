$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

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
        [String]
        $PathToLintersSubmodulesRoot,

        [Parameter(Position = 1, Mandatory = $true)]
        [String]
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

        Write-Information "##[command]Running cspell..."

        (npx -c "cspell $($filesToTest | ForEach-Object { "$PathBackToRepositoryRoot/$_" }) --config $PathBackToRepositoryRoot/cspell.yml --unique --show-context --no-progress --no-summary") | ForEach-Object { "##[error]$_" } | Write-Information

        if (Assert-ExternalCommandError) {
            Write-Error "##[error]Please resolve the above errors!"
        }
    }

    catch {
        throw
    }

    finally {
        Write-Information "##[command]Changing directory to repository root..."
        Set-Location -LiteralPath $PathBackToRepositoryRoot
    }

    Write-Output "##[section]All files conform to cspell standards!"
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
