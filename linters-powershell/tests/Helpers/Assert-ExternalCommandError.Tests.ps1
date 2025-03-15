BeforeAll {
    Import-Module ./linters-powershell/modules/Helpers.psm1 -Force
}

Describe 'Assert-ExternalCommandError' {
    It 'Given no parameters and $Global:LASTEXITCODE -eq 0, it should return false' {
        $Global:LASTEXITCODE = 0
        Assert-ExternalCommandError | Should -BeFalse
    }

    It 'Given no parameters and $Global:LASTEXITCODE -eq 1, it should return true' {
        $Global:LASTEXITCODE = 1
        Assert-ExternalCommandError | Should -BeTrue
    }

    It 'Given no parameters and $Global:LASTEXITCODE -eq -1, it should return true' {
        $Global:LASTEXITCODE = 1
        Assert-ExternalCommandError | Should -BeTrue
    }

    It 'Given no parameters and $Global:LASTEXITCODE -eq 128, it should return true' {
        $Global:LASTEXITCODE = 1
        Assert-ExternalCommandError | Should -BeTrue
    }

    It 'Given no parameters and $Global:LASTEXITCODE -eq -128, it should return true' {
        $Global:LASTEXITCODE = 1
        Assert-ExternalCommandError | Should -BeTrue
    }

    # Repeat the above tests but with -ThrowError
    It 'Given -ThrowError and $Global:LASTEXITCODE -eq 0, it should return null' {
        $Global:LASTEXITCODE = 0
        Assert-ExternalCommandError -ThrowError | Should -BeNullOrEmpty
    }

    It 'Given -ThrowError and $Global:LASTEXITCODE -eq 1, it should throw an error' {
        $Global:LASTEXITCODE = 1
        { Assert-ExternalCommandError -ThrowError } | Should -Throw '##`[error`]Please resolve the above errors!'
    }

    It 'Given -ThrowError and $Global:LASTEXITCODE -eq -1, it should throw an error' {
        $Global:LASTEXITCODE = 1
        { Assert-ExternalCommandError -ThrowError } | Should -Throw '##`[error`]Please resolve the above errors!'
    }

    It 'Given -ThrowError and $Global:LASTEXITCODE -eq 128, it should throw an error' {
        $Global:LASTEXITCODE = 1
        { Assert-ExternalCommandError -ThrowError } | Should -Throw '##`[error`]Please resolve the above errors!'
    }

    It 'Given -ThrowError and $Global:LASTEXITCODE -eq -128, it should throw an error' {
        $Global:LASTEXITCODE = 1
        { Assert-ExternalCommandError -ThrowError } | Should -Throw '##`[error`]Please resolve the above errors!'
    }
}
