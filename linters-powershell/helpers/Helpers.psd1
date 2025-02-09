@{
    # Script module or binary module file associated with this manifest.
    RootModule        = 'Helpers.psm1'

    # Version number of this module.
    ModuleVersion     = '1.0'

    # ID used to uniquely identify this module
    GUID              = '57074fb8-164c-4d28-849f-08846b3a5cb7'

    # Author of this module
    Author            = 'J-Afzal'

    # Company or vendor of this module
    CompanyName       = 'Unknown'

    # Copyright statement for this module
    Copyright         = '(c) 2025 J-Afzal. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = ''

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        'Assert-ExternalCommandError',
        'Test-CodeUsingAllLinters',
        'Test-CodeUsingClangTools',
        'Test-CodeUsingCSpell',
        'Test-CodeUsingPrettier',
        'Test-CodeUsingPSScriptAnalyzer',
        'Test-CSpellConfiguration',
        'Test-GitAttributesFile',
        'Test-GitIgnoreFile',
        'Test-PrettierIgnoreFile'
    )

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport   = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport   = @()
}
