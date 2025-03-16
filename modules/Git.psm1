$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

<#
    .SYNOPSIS
    Lints the .gitattributes file.

    .DESCRIPTION
    Raises an error fore any of the following:
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
    Import-Module Git.psd1
    Test-GitattributesFile -Verbose
#>

function Test-GitAttributesFile {

    [CmdletBinding()]
    param()

    Write-Verbose "##[debug]Test-GitattributesFile:  Running Test-GitattributesFile..."

    if (-Not (Test-Path -LiteralPath ./.gitattributes)) {
        Write-Information "##[warning]Test-GitattributesFile:  No .gitattributes file found at current directory! Please check if this is expected!"
        return
    }

    Write-Information "##[command]Test-GitattributesFile:  Retrieving contents of .gitattributes..."
    $gitattributesFileContents = @(Get-Content -LiteralPath ./.gitattributes)

    Write-Information "##[command]Test-GitattributesFile:  Retrieving all unique file extensions and unique files without a file extension..."
    $gitTrackedFiles = Invoke-ExternalCommand -ExternalCommand "git" -ExternalCommandArguments @("ls-files", "-c") -ReturnCommandOutput -ThrowError | ForEach-Object { if (-Not $_.StartsWith("submodules")) { $_ } } | Split-Path -Leaf

    $uniqueGitTrackedFileExtensions = $gitTrackedFiles | ForEach-Object { if ($_.Split(".").Length -gt 1) { "\.$($_.Split(".")[-1])" } } | Sort-Object | Select-Object -Unique
    $uniqueGitTrackedFileNamesWithoutExtensions = $gitTrackedFiles | ForEach-Object { if ($_.Split(".").Length -eq 1) { $_ } } | Sort-Object | Select-Object -Unique

    # Null coalesce to empty arrays
    if ($null -eq $uniqueGitTrackedFileExtensions) {
        $uniqueGitTrackedFileExtensions = @()
    }

    if ($null -eq $uniqueGitTrackedFileNamesWithoutExtensions) {
        $uniqueGitTrackedFileNamesWithoutExtensions = @()
    }

    Write-Verbose "##[debug]Test-GitattributesFile:  Retrieved unique file extensions:"
    $uniqueGitTrackedFileExtensions | ForEach-Object { Write-Verbose "##[debug]Test-GitattributesFile:  $($_.TrimStart("\"))" }

    Write-Verbose "##[debug]Test-GitattributesFile:  Retrieved unique files without a file extension:"
    $uniqueGitTrackedFileNamesWithoutExtensions | ForEach-Object { Write-Verbose "##[debug]Test-GitattributesFile:  $_" }

    $uniqueGitTrackedFileExtensionsAndFileNamesWithoutExtensions = $uniqueGitTrackedFileExtensions + $uniqueGitTrackedFileNamesWithoutExtensions

    Write-Information "##[command]Test-GitattributesFile:  Checking formatting of .gitattributes file..."
    $lintingErrors = @()
    $foundEntries = @()
    $previousLineWasBlank = $false
    $gitattributesFileContentsWithoutComments = @()

    for ($index = 0; $index -lt $gitattributesFileContents.Length; $index++) {

        $currentLine = $gitattributesFileContents[$index]
        $currentLineNumber = $index + 1

        if ($currentLine -eq "") {
            Write-Verbose "##[debug]Test-GitattributesFile:  Current line is blank: '$currentLine'"

            if ($previousLineWasBlank) {
                $lintingErrors += @{lineNumber = $currentLineNumber; line = "'$currentLine'"; errorMessage = "Duplicate blank line." }
            }

            $previousLineWasBlank = $true
            continue
        }

        # Match every before and including '#'
        $lineBeforeAndIncludingComment = $currentLine | Select-String -Pattern ".*#"

        if ($null -eq $lineBeforeAndIncludingComment) {
            Write-Verbose "##[debug]Test-GitattributesFile:  Current line is code: '$currentLine'"

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
            Write-Verbose "##[debug]Test-GitattributesFile:  Current line is comment: '$currentLine'"
        }

        else {
            Write-Verbose "##[debug]Test-GitattributesFile:  Current line is a mixture of comment and code: '$currentLine'"
            $lintingErrors += @{lineNumber = $currentLineNumber; line = "'$currentLine'"; errorMessage = "Lines must be blank, entirely comment or entirely non-comment." }
        }

        $previousLineWasBlank = $false
    }

    Write-Information "##[command]Test-GitattributesFile:  Checking all unique file extensions and files without extensions have a .gitattributes entry:"

    foreach ($fileExtensionOrFileNameWithoutExtension in $uniqueGitTrackedFileExtensionsAndFileNamesWithoutExtensions) {

        $foundMatch = $false

        foreach ($line in $gitattributesFileContentsWithoutComments) {

            if ($line -Match $fileExtensionOrFileNameWithoutExtension ) {
                Write-Verbose "##[debug]Test-GitattributesFile:  $fileExtension entry found in: '$line'"
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
        Write-Error "##[error]Test-GitattributesFile:  Please resolve the above errors!"
    }

    else {
        Write-Information "##[section]Test-GitattributesFile:  All .gitattributes tests passed!"
    }
}

<#
    .SYNOPSIS
    Lints the .gitignore file.

    .DESCRIPTION
    Raises an error fore any of the following:
        - Duplicate empty lines
        - Duplicate entries
        - Not alphabetically ordered

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module Git.psd1
    Test-GitIgnoreFile -Verbose
#>

function Test-GitIgnoreFile {

    [CmdletBinding()]
    param()

    Write-Verbose "##[debug]Test-GitIgnoreFile:  Running Test-GitIgnoreFile..."

    if (-Not (Test-Path -LiteralPath ./.gitignore)) {
        Write-Information "##[warning]Test-GitIgnoreFile:  No .gitignore file found at current directory! Please check if this is expected!"
        return
    }

    Write-Information "##[command]Test-GitIgnoreFile:  Retrieving contents of .gitignore..."
    $gitignoreFileContents = @(Get-Content -LiteralPath ./.gitignore)

    Write-Information "##[command]Test-GitIgnoreFile:  Checking formatting of .gitignore file..."
    $lintingErrors = @()
    $foundEntries = @()

    for ($index = 0; $index -lt $gitignoreFileContents.Length; $index++) {

        $currentLine = $gitignoreFileContents[$index]
        $currentLineNumber = $index + 1

        if ($currentLine -eq "") {
            Write-Verbose "##[debug]Test-GitIgnoreFile:  Current line is blank: '$currentLine'"

            if ($previousLineWasBlank) {
                $lintingErrors += @{lineNumber = $currentLineNumber; line = "'$currentLine'"; errorMessage = "Duplicate blank line." }
            }

            $previousLineWasBlank = $true
        }

        else {
            # Match every before and including '#'
            $lineBeforeAndIncludingComment = $currentLine | Select-String -Pattern ".*#"

            if ($null -eq $lineBeforeAndIncludingComment) {
                Write-Verbose "##[debug]Test-GitIgnoreFile:  Current line is code: '$currentLine'"

                if ($foundEntries.Contains($currentLine)) {
                    $lintingErrors += @{lineNumber = $currentLineNumber; line = "'$currentLine'"; errorMessage = "Duplicate entry." }
                }

                $foundEntries += $currentLine
            }

            elseif ($lineBeforeAndIncludingComment.Matches.Value.Length -eq 1) {
                Write-Verbose "##[debug]Test-GitIgnoreFile:  Current line is comment: '$currentLine'"
            }

            else {
                Write-Verbose "##[debug]Test-GitIgnoreFile:  Current line is a mixture of comment and code: '$line'"
                $lintingErrors += @{lineNumber = $currentLineNumber; line = "'$currentLine'"; errorMessage = "Line must be blank, entirely comment or entirely non-comment." }
            }

            $previousLineWasBlank = $false
        }
    }

    Write-Information "##[command]Test-GitIgnoreFile:  Checking all entries are alphabetically ordered..."

    if ($foundEntries.Length -gt 1) {

        $foundEntriesSorted = $foundEntries | Sort-Object

        if (Compare-ObjectExact -ReferenceObject $foundEntriesSorted -DifferenceObject $foundEntries -Verbose) {
            $lintingErrors += @{lineNumber = "-"; line = "-"; errorMessage = "Entries are not alphabetically ordered." }
        }
    }

    if ($lintingErrors.Length -gt 0) {
        $lintingErrors | Sort-Object { $_.lineNumber }, { $_.errorMessage } | ForEach-Object { [PSCustomObject]$_ } | Format-Table -AutoSize -Wrap -Property lineNumber, line, errorMessage
        Write-Error "##[error]Test-GitIgnoreFile:  Please resolve the above errors!"
    }

    else {
        Write-Information "##[section]Test-GitIgnoreFile:  All .gitignore tests passed!"
    }
}
