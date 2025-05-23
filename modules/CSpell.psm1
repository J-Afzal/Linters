$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

<#
    .SYNOPSIS
    Runs cspell against all non-binary files (with exception of the package-lock.json file and any auto-generated docs).

    .DESCRIPTION
    None.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module CSpell.psd1
    Test-CodeUsingCSpell -Verbose
#>

function Test-CodeUsingCSpell {

    [CmdletBinding()]
    param()

    Write-Verbose "##[debug]Test-CodeUsingCSpell:  Running Test-CodeUsingCSpell..."

    Write-Information "##[command]Test-CodeUsingCSpell:  Retrieving all files to test against cspell..."
    $filesToTest = Get-FilteredFilePathsToTest -DirectoryFilterType "Exclude" -DirectoryNameFilterList @("docs/html") -FileNameFilterType "Exclude" -FileNameFilterList @("package-lock") -ExcludeBinaryFiles -Verbose

    if ($null -eq $filesToTest) {
        Write-Information "##[warning]Test-CodeUsingCSpell:  No files found to lint for cspell! Please check if this is expected!"
        return
    }

    Write-Verbose "##[debug]Test-CodeUsingCSpell:  Using the following cspell version..."
    Invoke-ExternalCommand -ExternalCommand "npx" -ExternalCommandArguments @("cspell", "--version") -ThrowError -Verbose

    Write-Information "##[command]Test-CodeUsingCSpell:  Running cspell..."

    $ExternalCommandArguments = @("cspell") + $filesToTest + @("--config", "./cspell.yml", "--unique", "--show-context", "--no-progress", "--no-summary")

    if (Invoke-ExternalCommand -ExternalCommand "npx" -ExternalCommandArguments $ExternalCommandArguments -Verbose) {
        Write-Error "##[error]Test-CodeUsingCSpell:  The above files have cspell formatting errors!"
    }

    else {
        Write-Information "##[section]Test-CodeUsingCSpell:  All files conform to cspell standards!"
    }
}

<#
    .SYNOPSIS
    Lints the cspell.yml file.

    .DESCRIPTION
    Raises an error fore any of the following:
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

    This function will also throw errors for cspell.yml files that don't have any dictionaries, ignorePaths, words and
    ignoreWords entries.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module CSpell.psd1
    Test-CSpellConfiguration -Verbose
#>

function Test-CSpellConfiguration {

    [CmdletBinding()]
    param()

    Write-Verbose "##[debug]Test-CSpellConfiguration:  Running Test-CSpellConfiguration..."

    if (-Not (Test-Path -LiteralPath ./cspell.yml)) {
        Write-Information "##[warning]Test-CSpellConfiguration:  No cspell.yml file found at current directory! Please check if this is expected!"
        return
    }

    Write-Information "##[command]Test-CSpellConfiguration:  Retrieving contents of cspell.yml..."
    $cspellFileContents = @(Get-Content -LiteralPath ./cspell.yml)

    Write-Information "##[command]Test-CSpellConfiguration:  Performing initial check of the cspell.yml file..."
    $lintingErrors = @()

    # The below if statements will cause an exception if the file is empty or only a single line. This is fine as the config
    # file is in a useless state if it is empty or only contains a single line, and thus isn't an allowed state.
    if ($cspellFileContents[0] -ne "version: 0.2") {
        $lintingErrors += @{lineNumber = 1; line = "'$($cspellFileContents[0])'"; errorMessage = "Invalid version number. Expected 'version: 0.2'." }
    }

    if ($cspellFileContents[1] -ne "language: en-gb") {
        $lintingErrors += @{lineNumber = 2; line = "'$($cspellFileContents[1])'"; errorMessage = "Invalid language. Expected 'language: en-gb'." }
    }

    Write-Information "##[command]Test-CSpellConfiguration:  Retrieving 'dictionaries', 'ignorePaths', 'words' and 'ignoreWords'..."

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
            Write-Verbose "##[debug]Test-CSpellConfiguration:  Current line is blank: '$currentLine'"
            $lintingErrors += @{lineNumber = $currentLineNumber; line = "'$currentLine'"; errorMessage = "Invalid empty line." }
            continue
        }

        $key = $currentLine | Select-String -Pattern "^[a-zA-Z]+"

        if ($null -eq $key) {

            switch ($currentKey) {
                dictionaries {
                    Write-Verbose "##[debug]Test-CSpellConfiguration:  Current line is a 'dictionaries' entry: '$currentLine'"

                    # Assumes an indentation of four characters
                    $entry = $currentLine.TrimStart("    - ")

                    if ($cspellDictionaries.Contains($entry)) {
                        $lintingErrors += @{lineNumber = $currentLineNumber; line = "'$currentLine'"; errorMessage = "Duplicate entry within 'dictionaries'." }
                    }

                    $cspellDictionaries += $entry
                }

                ignorePaths {
                    Write-Verbose "##[debug]Test-CSpellConfiguration:  Current line is an 'ignorePaths' entry: '$currentLine'"

                    # Assumes an indentation of four characters
                    $entry = $currentLine.TrimStart("    - ").Replace('"', "")

                    if ($cspellIgnorePaths.Contains($entry)) {
                        $lintingErrors += @{lineNumber = $currentLineNumber; line = "'$currentLine'"; errorMessage = "Duplicate entry within 'ignorePaths'." }
                    }

                    $cspellIgnorePaths += $entry
                }

                words {
                    Write-Verbose "##[debug]Test-CSpellConfiguration:  Current line is a 'words' entry: '$currentLine'"

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
                    Write-Verbose "##[debug]Test-CSpellConfiguration:  Current line is an 'ignoreWords' entry: '$currentLine'"

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
                    Write-Verbose "##[debug]Test-CSpellConfiguration:  Current line is an entry for an unexpected key: '$currentLine'"

                    $lintingErrors += @{lineNumber = $currentLineNumber; line = "'$currentLine'"; errorMessage = "Entry for an invalid key." }
                }
            }
        }

        else {
            Write-Verbose "##[debug]Test-CSpellConfiguration:  Current line is a key: '$currentLine'"

            $currentKey = $key.Matches[0].Value

            if (-Not $expectedOrderOfKeys.Contains($currentKey)) {
                $lintingErrors += @{lineNumber = $currentLineNumber; line = "'$currentLine'"; errorMessage = "Invalid key." }
            }

            $orderOfKeys += $currentKey
        }
    }

    if (Compare-ObjectExact -ReferenceObject $expectedOrderOfKeys -DifferenceObject $orderOfKeys -Verbose) {
        $lintingErrors += @{lineNumber = "-"; line = "-"; errorMessage = "Keys are missing, incorrectly ordered, incorrectly cased, or contain an unexpected key. Expected the following order of keys: 'version', 'language', 'dictionaries', 'ignorePaths', 'words', 'ignoreWords'." }
    }

    Write-Information "##[command]Test-CSpellConfiguration:  Checking that 'dictionaries', 'ignorePaths', 'words' and 'ignoreWords' are alphabetically ordered..."

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

    Write-Information "##[command]Test-CSpellConfiguration:  Checking that 'ignorePaths' matches the .gitignore file..."

    if (-Not (Test-Path -LiteralPath ./.gitignore)) {
        Write-Information "##[warning]Test-CSpellConfiguration:  No .gitignore file found at current directory! Please check if this is expected!"
        $gitignoreFileContents = @()
    }

    else {
        $gitignoreFileContents = @(Get-Content -LiteralPath ./.gitignore)
    }

    # Add package-lock.json and re-sort gitattributes
    [Collections.Generic.List[String]] $cspellIgnorePathsList = $cspellIgnorePaths
    $cspellIgnorePathsList.Remove("package-lock.json") | Out-Null
    $cspellIgnorePathsList.Remove("docs/html/") | Out-Null

    if (Compare-ObjectExact -ReferenceObject ($gitignoreFileContents | Sort-Object) -DifferenceObject $cspellIgnorePathsList -Verbose) {
        $lintingErrors += @{lineNumber = "-"; line = "-"; errorMessage = "'ignorePaths' does not match the entries in .gitignore." }
    }

    Write-Information "##[command]Test-CSpellConfiguration:  Checking if 'words' are found in 'ignoreWords'..."

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

    Write-Information "##[command]Test-CSpellConfiguration:  Checking for redundant 'words' and 'ignoreWords'..."

    # Same file list as found in Test-CodeUsingCSpell but also exclude cspell.yml (assumes cspell.yml is the only file with a file name of cspell)
    $allFilesToCheck = Get-FilteredFilePathsToTest -DirectoryFilterType "Exclude" -DirectoryNameFilterList @("docs/html") -FileNameFilterType "Exclude" -FileNameFilterList @("cspell", "package-lock") -ExcludeBinaryFiles -Verbose

    [Collections.Generic.List[String]] $redundantCSpellWords = $cspellWords
    [Collections.Generic.List[String]] $redundantCSpellIgnoreWords = $cspellIgnoreWords

    foreach ($file in $allFilesToCheck) {

        Write-Verbose "##[debug]Test-CSpellConfiguration:  Reading contents of '$file'..."

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
        Write-Error "##[error]Test-CSpellConfiguration:  Please resolve the above errors!"
    }

    else {
        Write-Information "##[section]Test-CSpellConfiguration:  All cspell.yml tests passed!"
    }
}
