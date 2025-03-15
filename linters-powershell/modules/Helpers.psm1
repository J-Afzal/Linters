$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

<#
    .SYNOPSIS
    Asserts whether an error when an external function has thrown an error via LASTEXITCODE.

    .DESCRIPTION
    This function must be called immediately after the external function call.

    .PARAMETER ThrowError
    Specifies whether to throw an error if an error is detected. If not specified a boolean will be returned instead.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    Import-Module Linters.psd1 -Force
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
    Object[] A list of error messages.

    .EXAMPLE
    Import-Module ./submodules/Linters/linters-powershell/Linters.psd1

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

    Write-Verbose "##[debug]Compare-ObjectExact returning:"
    $errors | ForEach-Object { Write-Verbose "##[debug]    $_" }

    return $errors
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
    [OutputType([Object[]])]
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

    Write-Verbose "##[debug]Get-AllBinaryFiles returning:"
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
    Object[] A list of file paths (relative to the root of the repository).

    .EXAMPLE
    Import-Module ./submodules/Linters/linters-powershell/Linters.psd1
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

    Write-Verbose "##[debug]Running Get-AllFilePathsToTest..."
    Write-Verbose "##[debug]Parameters:"
    Write-Verbose "##[debug]    ExcludeBinaryFiles: $ExcludeBinaryFiles"

    $allFilesToTest = Get-FilteredFilePathsToTest -DirectoryFilterType "Exclude" -DirectoryNameFilterList @("nothing") -FileNameFilterType "Exclude" -FileNameFilterList @("nothing") -FileExtensionFilterType "Exclude" -FileExtensionFilterList @("nothing") -ExcludeBinaryFiles:$ExcludeBinaryFiles

    Write-Verbose "##[debug]Get-AllFilePathsToTest returning:"
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
    Object[] A list of file paths (relative to the root of the repository).

    .EXAMPLE
    Import-Module ./submodules/Linters/linters-powershell/Linters.psd1

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

    Write-Verbose "##[debug]Get-FilteredFilePathsToTest returning:"
    $filteredFilesToTest | ForEach-Object { Write-Verbose "##[debug]    $_" }

    return $filteredFilesToTest
}

<#
    .SYNOPSIS
    TODO

    .DESCRIPTION
    TODO

    .PARAMETER ThrowError
    TODO

    .INPUTS
    TODO.

    .OUTPUTS
    TODO.

    .EXAMPLE
    TODO
#>

function Invoke-ExternalCommand {

    [OutputType([Boolean])]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [String]
        $ExternalCommand,

        [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
        [Object[]]
        $PassThruArgs,

        [Parameter(Position = 2, Mandatory = $false)]
        [Switch]
        $ThrowError = $false
    )

    & $ExternalCommand @PassThruArgs

    return Assert-ExternalCommandError -ThrowError:$ThrowError
}
