$root = Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path
Import-Module "$root\dbatools.psd1" -Force

#this should be moved somewhere to a file that will be used as config for the acceptance tests
$script:ServerConfig = 
    New-Object -TypeName PsObject -Property @{
       Name = '.\sqlexpress'
    }

Describe 'Test-SqlPath' {
    It 'Returns True for existing directory' { 
        # -- Arrange
        $path = $env:ProgramFiles
        $path | Should Exist 

        # -- Act
        $actual = Test-SqlPath -SqlServer $script:ServerConfig.Name -Path $path

        # -- Assert
        $actual | Should Be $True
    }

    It 'Returns True for existing file' { 
        # -- Arrange
        $path = "$env:windir\notepad.exe"
        $path | Should Exist 

        # -- Act
        $actual = Test-SqlPath -SqlServer $script:ServerConfig.Name -Path $path

        # -- Assert
        $actual | Should Be $True
    }

     It 'Returns False for non-existing file' { 
        # -- Arrange
        $path = 'C:\dummyfile.txt'
        $path | Should Not Exist 

        # -- Act
        $actual = Test-SqlPath -SqlServer $script:ServerConfig.Name -Path $path

        # -- Assert
        $actual | Should Be $False
    }
}