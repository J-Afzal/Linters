@{
    # Script module or binary module file associated with this manifest.
    RootModule        = 'CSpell.psm1'

    # Version number of this module.
    ModuleVersion     = '1.0'

    # ID used to uniquely identify this module
    GUID              = '65328667-5c86-462b-bab4-732b1ba2fe4f'

    # Author of this module
    Author            = 'J-Afzal'

    # Company or vendor of this module
    CompanyName       = 'Unknown'

    # Copyright statement for this module
    Copyright         = '(c) J-Afzal. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'Provides linting functions for CSpell.'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules   = @(
        './Helpers.psm1'
    )

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        'Test-CodeUsingCSpell',
        'Test-CSpellConfiguration'
    )

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport   = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport   = @()
}
