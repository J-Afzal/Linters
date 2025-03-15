$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

<#
    .SYNOPSIS
    Asserts whether an external command has thrown an error via LASTEXITCODE.

    .DESCRIPTION
    This function must be called immediately after the external command call.

    .PARAMETER ThrowError
    Whether to throw an error if an error is detected. If not specified, a boolean will be returned instead.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module Helpers.psd1 -Force
    npm install
    Assert-ExternalCommandError -ThrowError -Verbose
#>

function Assert-ExternalCommandError {

    [CmdletBinding()]
    [OutputType([Boolean])]
    param(
        [Parameter(Position = 0, Mandatory = $false)]
        [Switch]
        $ThrowError = $false
    )

    if ($LASTEXITCODE -ne 0) {
        if ($ThrowError) {
            Write-Error "##[error]Please resolve the above errors!"
        }

        else {
            return $true
        }
    }

    else {
        if ($ThrowError) {
            return
        }

        else {
            return $false
        }
    }
}

<#
    .SYNOPSIS
    Compares two objects and returns all differences between them.

    .DESCRIPTION
    Compare-Object was not sufficient as it disregards the order of the DifferenceObject.

    .PARAMETER ReferenceObject
    Specifies an array of objects used as a reference for comparison.

    .PARAMETER DifferenceObject
    Specifies the objects that are compared to the reference objects.

    .INPUTS
    None.

    .OUTPUTS
    Object[] A list of error messages.

    .EXAMPLE
    Import-Module Helpers.psd1

    $arrayOne = @(1,2,3)
    $arrayTwo = @(1,3,2)

    Compare-ObjectExact -ReferenceObject $arrayOne -DifferenceObject $arrayTwo -Verbose
#>

function Compare-ObjectExact {

    [CmdletBinding()]
    [OutputType([Object[]])]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [Object[]]
        $ReferenceObject,

        [Parameter(Position = 1, Mandatory = $true)]
        [Object[]]
        $DifferenceObject
    )

    Write-Verbose "##[debug]Compare-ObjectExact:  Running Compare-ObjectExact..."
    Write-Verbose "##[debug]Compare-ObjectExact:  Parameters:"
    Write-Verbose "##[debug]Compare-ObjectExact      ReferenceObject:"
    $ReferenceObject | ForEach-Object { Write-Verbose "##[debug]Compare-ObjectExact:          $_" }
    Write-Verbose "##[debug]    DifferenceObject:"
    $DifferenceObject | ForEach-Object { Write-Verbose "##[debug]Compare-ObjectExact:          $_" }

    [Collections.Generic.List[String]] $differences = @()

    for ($index = 0; $index -lt $ReferenceObject.Length; $index++) {

        try {

            if ($ReferenceObject[$index] -ne $DifferenceObject[$index]) {
                $differences.Add("'$($DifferenceObject[$index])' found instead of '$($ReferenceObject[$index])'.")
            }
        }

        catch {

            # Assuming that this is caused by an index out of bounds error with DifferenceObject
            $differences.Add("'$($ReferenceObject[$index])' was not found.")

        }
    }

    if ($DifferenceObject.Length -gt $ReferenceObject.Length) {

        for ($index = $ReferenceObject.Length; $index -lt $DifferenceObject.Length; $index++) {

            $differences.Add("An extra value of '$($DifferenceObject[$index])' found.")
        }
    }

    Write-Verbose "##[debug]Compare-ObjectExact:  Returning:"
    $differences | ForEach-Object { Write-Verbose "##[debug]Compare-ObjectExact:      $_" }

    return $differences
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
    Import-Module Helpers.psd1
    Get-AllBinaryFiles -Verbose
#>

function Get-AllBinaryFiles {

    [CmdletBinding()]
    [OutputType([Object[]])]
    param()

    Write-Verbose "##[debug]Get-AllBinaryFiles:  Running Get-AllBinaryFiles..."

    if (-Not (Test-Path -LiteralPath ./.gitattributes)) {
        Write-Information "##[warning]Get-AllBinaryFiles:  No .gitattributes file found at current directory! Please check if this is expected!"
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
                Write-Information "##[warning]Get-AllBinaryFiles:  '$currentLine' matched as a file extension but failed to extract."
            }
        }

        # Files without an extension
        if ($currentLine -Match "^[a-zA-Z0-9-]+ +binary$") {

            $found = $currentLine -Match "^[a-zA-Z0-9-]+"

            if ($found) {
                $binaryFileNames += $matches[0]
            }

            else {
                Write-Information "##[warning]Get-AllBinaryFiles:  '$currentLine' matched as a file without an extension but failed to extract."
            }
        }
    }

    $allFiles = Invoke-ExternalCommand -ExternalCommand "git" -ExternalCommandArguments @("ls-files", "-c") -ReturnCommandOutput -ThrowError

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

    Write-Verbose "##[debug]Get-AllBinaryFiles:  Returning:"
    $allBinaryFiles | ForEach-Object { Write-Verbose "##[debug]Get-AllBinaryFiles:      $_" }

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
    Object[] A list of file paths (relative to the root of the repository).

    .EXAMPLE
    Import-Module Helpers.psd1
    Get-AllFilePathsToTest -ExcludeBinaryFiles -Verbose
#>

function Get-AllFilePathsToTest {

    [CmdletBinding()]
    [OutputType([Object[]])]
    param(
        [Parameter(Position = 0, Mandatory = $false)]
        [Switch]
        $ExcludeBinaryFiles = $false
    )

    Write-Verbose "##[debug]Get-AllFilePathsToTest:  Running Get-AllFilePathsToTest..."
    Write-Verbose "##[debug]Get-AllFilePathsToTest:  Parameters:"
    Write-Verbose "##[debug]Get-AllFilePathsToTest:      ExcludeBinaryFiles: $ExcludeBinaryFiles"

    $allFilesToTest = Get-FilteredFilePathsToTest -DirectoryFilterType "Exclude" -DirectoryNameFilterList @("nothing") -FileNameFilterType "Exclude" -FileNameFilterList @("nothing") -FileExtensionFilterType "Exclude" -FileExtensionFilterList @("nothing") -ExcludeBinaryFiles:$ExcludeBinaryFiles

    Write-Verbose "##[debug]Get-AllFilePathsToTest:  Returning:"
    $allFilesToTest | ForEach-Object { Write-Verbose "##[debug]Get-AllFilePathsToTest:      $_" }

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
    Object[] A list of file paths (relative to the root of the repository).

    .EXAMPLE
    Import-Module Helpers.psd1

    Get-FilteredFilePathsToTest -DirectoryFilterType "Exclude" -DirectoryNameFilterList @("docs/html") \
                                -FileNameFilterType "Exclude" -FileNameFilterList @("cspell", "package-lock") \
                                -FileExtensionFilterType "Exclude" -FileExtensionFilterList @("ico", "png") -Verbose
#>

function Get-FilteredFilePathsToTest {

    [CmdletBinding()]
    [OutputType([Object[]])]
    param(
        [Parameter(Position = 0, Mandatory = $false, ParameterSetName = "DirectorySearch")]
        [Parameter(Position = 0, Mandatory = $false, ParameterSetName = "DirectoryAndFileNameSearch")]
        [Parameter(Position = 0, Mandatory = $false, ParameterSetName = "FullSearch")]
        [ValidateSet("Include", "Exclude")]
        [String]
        $DirectoryFilterType,

        [Parameter(Position = 1, Mandatory = $true, ParameterSetName = "DirectorySearch")]
        [Parameter(Position = 1, Mandatory = $true, ParameterSetName = "DirectoryAndFileNameSearch")]
        [Parameter(Position = 1, Mandatory = $true, ParameterSetName = "FullSearch")]
        [Object[]]
        $DirectoryNameFilterList,

        [Parameter(Position = 2, Mandatory = $false, ParameterSetName = "FileNameSearch")]
        [Parameter(Position = 2, Mandatory = $false, ParameterSetName = "DirectoryAndFileNameSearch")]
        [Parameter(Position = 2, Mandatory = $false, ParameterSetName = "FileNameAndFileExtensionSearch")]
        [Parameter(Position = 2, Mandatory = $false, ParameterSetName = "FullSearch")]
        [ValidateSet("Include", "Exclude")]
        [String]
        $FileNameFilterType,

        [Parameter(Position = 3, Mandatory = $true, ParameterSetName = "FileNameSearch")]
        [Parameter(Position = 3, Mandatory = $true, ParameterSetName = "DirectoryAndFileNameSearch")]
        [Parameter(Position = 3, Mandatory = $true, ParameterSetName = "FileNameAndFileExtensionSearch")]
        [Parameter(Position = 3, Mandatory = $true, ParameterSetName = "FullSearch")]
        [Object[]]
        $FileNameFilterList,

        [Parameter(Position = 4, Mandatory = $false, ParameterSetName = "FileExtensionSearch")]
        [Parameter(Position = 4, Mandatory = $false, ParameterSetName = "FileNameAndFileExtensionSearch")]
        [Parameter(Position = 4, Mandatory = $false, ParameterSetName = "FullSearch")]
        [ValidateSet("Include", "Exclude")]
        [String]
        $FileExtensionFilterType,

        [Parameter(Position = 5, Mandatory = $true, ParameterSetName = "FileExtensionSearch")]
        [Parameter(Position = 5, Mandatory = $true, ParameterSetName = "FileNameAndFileExtensionSearch")]
        [Parameter(Position = 5, Mandatory = $true, ParameterSetName = "FullSearch")]
        [Object[]]
        $FileExtensionFilterList,

        [Parameter(Position = 6, Mandatory = $false, ParameterSetName = "DirectorySearch")]
        [Parameter(Position = 6, Mandatory = $false, ParameterSetName = "FileNameSearch")]
        [Parameter(Position = 6, Mandatory = $false, ParameterSetName = "FileExtensionSearch")]
        [Parameter(Position = 6, Mandatory = $false, ParameterSetName = "DirectoryAndFileNameSearch")]
        [Parameter(Position = 6, Mandatory = $false, ParameterSetName = "FileNameAndFileExtensionSearch")]
        [Parameter(Position = 6, Mandatory = $false, ParameterSetName = "FullSearch")]
        [Switch]
        $ExcludeBinaryFiles = $false
    )

    Write-Verbose "##[debug]Get-FilteredFilePathsToTest:  Running Get-FilteredFilePathsToTest..."
    Write-Verbose "##[debug]Get-FilteredFilePathsToTest:  Parameters:"
    Write-Verbose "##[debug]Get-FilteredFilePathsToTest:      DirectoryFilterType: $DirectoryFilterType"
    Write-Verbose "##[debug]Get-FilteredFilePathsToTest:      DirectoryNameFilterList:"
    $DirectoryNameFilterList | ForEach-Object { Write-Verbose "##[debug]Get-FilteredFilePathsToTest:          $_" }
    Write-Verbose "##[debug]Get-FilteredFilePathsToTest:      FileNameFilterType: $FileNameFilterType"
    Write-Verbose "##[debug]Get-FilteredFilePathsToTest:      FileNameFilterList:"
    $FileNameFilterList | ForEach-Object { Write-Verbose "##[debug]Get-FilteredFilePathsToTest:          $_" }
    Write-Verbose "##[debug]Get-FilteredFilePathsToTest:      FileExtensionFilterType: $FileExtensionFilterType"
    Write-Verbose "##[debug]Get-FilteredFilePathsToTest:      FileExtensionFilterList:"
    $FileExtensionFilterList | ForEach-Object { Write-Verbose "##[debug]Get-FilteredFilePathsToTest:          $_" }
    Write-Verbose "##[debug]Get-FilteredFilePathsToTest:      ExcludeBinaryFiles: $ExcludeBinaryFiles"

    $allFiles = Invoke-ExternalCommand -ExternalCommand "git" -ExternalCommandArguments @("ls-files", "-c") -ReturnCommandOutput -ThrowError

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

    Write-Verbose "##[debug]Get-FilteredFilePathsToTest:  Returning:"
    $filteredFilesToTest | ForEach-Object { Write-Verbose "##[debug]Get-FilteredFilePathsToTest:      $_" }

    return $filteredFilesToTest
}

<#
    .SYNOPSIS
    TODO

    .DESCRIPTION
    TODO

    .PARAMETER ExternalCommand
    The external command to invoke.

    .PARAMETER ExternalCommandArguments
    The arguments to pass to the external command.

    .PARAMETER ReturnCommandOutput
    Whether to return the output of the command.

    .PARAMETER ThrowError
    Whether to throw an error if an error is detected. If not specified, a boolean will be returned instead if
    ReturnCommandOutput is not specified.

    .INPUTS
    None.

    .OUTPUTS
    Boolean. If neither ThrowError nor ReturnCommandOutput are specified this value represents whether the external command
    has thrown an error.
    Object[]. If ReturnCommandOutput is specified this value represents the output of the external command.

    .EXAMPLE
    Import-Module Helpers.psd1
    Invoke-ExternalCommand -ExternalCommand "npx" -ExternalCommandArguments @("cspell", "--version") -ReturnCommandOutput -ThrowError -Verbose
#>

function Invoke-ExternalCommand {

    [OutputType([Boolean])]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [String]
        $ExternalCommand,

        [Parameter(Position = 1, Mandatory = $true)]
        [Object[]]
        $ExternalCommandArguments,

        [Parameter(Position = 2, Mandatory = $false)]
        [Switch]
        $ReturnCommandOutput = $false,

        [Parameter(Position = 3, Mandatory = $false)]
        [Switch]
        $ThrowError = $false
    )

    Write-Verbose "##[debug]Invoke-ExternalCommand:  Running Invoke-ExternalCommand..."
    Write-Verbose "##[debug]Invoke-ExternalCommand:  Parameters:"
    Write-Verbose "##[debug]Invoke-ExternalCommand:      ExternalCommand     : $ExternalCommand"
    Write-Verbose "##[debug]Invoke-ExternalCommand:      ExternalCommandArguments:"
    $ExternalCommandArguments | ForEach-Object { Write-Verbose "##[debug]Invoke-ExternalCommand:          $_" }
    Write-Verbose "##[debug]Invoke-ExternalCommand:      ReturnCommandOutput : $ReturnCommandOutput"
    Write-Verbose "##[debug]Invoke-ExternalCommand:      ThrowError          : $ThrowError"

    if ($ReturnCommandOutput) {
        $output = (& $ExternalCommand @ExternalCommandArguments 2>&1)
        Assert-ExternalCommandError -ThrowError:$ThrowError
        return $output
    }

    else {
        (& $ExternalCommand @ExternalCommandArguments 2>&1) | ForEach-Object { Write-Verbose "##[debug]Invoke-ExternalCommand:  $_" }
        return Assert-ExternalCommandError -ThrowError:$ThrowError
    }
}
