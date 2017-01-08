$root = Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path
Import-Module "$root\dbatools.psd1" -Force

function Get-FileExistsMockData ([switch] $FileExists, [switch] $DirectoryExists) {
$data = @"
<?xml version="1.0" standalone="yes"?>
<NewDataSet>
  <xs:schema id="NewDataSet" xmlns="" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:msdata="urn:schemas-microsoft-com:xml-msdata">
    <xs:element name="NewDataSet" msdata:IsDataSet="true" msdata:Locale="">
      <xs:complexType>
        <xs:choice minOccurs="0" maxOccurs="unbounded">
          <xs:element name="Table">
            <xs:complexType>
              <xs:sequence>
                <xs:element name="File_x0020_Exists" type="xs:unsignedByte" minOccurs="0" />
                <xs:element name="File_x0020_is_x0020_a_x0020_Directory" type="xs:unsignedByte" minOccurs="0" />
                <xs:element name="Parent_x0020_Directory_x0020_Exists" type="xs:unsignedByte" minOccurs="0" />
              </xs:sequence>
            </xs:complexType>
          </xs:element>
        </xs:choice>
      </xs:complexType>
    </xs:element>
  </xs:schema>
  <Table>
    <File_x0020_Exists>0</File_x0020_Exists>
    <File_x0020_is_x0020_a_x0020_Directory>$([int][bool]$FileExists)</File_x0020_is_x0020_a_x0020_Directory>
    <Parent_x0020_Directory_x0020_Exists>$([int][bool]$DirectoryExists)</Parent_x0020_Directory_x0020_Exists>
  </Table>
</NewDataSet>
"@

    Load-DataSetXml -Data $data
}

function Save-DataSetXml ([System.Data.DataTable]$Table) { 
    #todo write textwriter (streamWriter) with WriteSchema xmlMode
}

function To-DataSet ([System.Data.DataTable]$Table) { 
   $set = New-Object -TypeName System.Data.DataSet 
   $set.Add($Table)
   $set
}

function Get-MockCredential ($UserName = 'username', $Password = 'password') { 
    New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName, (ConvertTo-SecureString $Password -AsPlainText -Force)
}

function Load-DataSetXml ([String]$Data) { 
    try {
        $set = New-Object -TypeName System.Data.DataSet

        $schemaReader = New-Object -TypeName System.IO.StringReader -ArgumentList $Data
        $dataReader = New-Object -TypeName System.IO.StringReader -ArgumentList $Data
        
        $null = $set.ReadXmlSchema($schemaReader)
        $null = $set.ReadXml($dataReader)

        $set
    }
    finally {
        $schemaReader.Dispose()
        $dataReader.Dispose()
    }
}

InModuleScope -ModuleName dbatools {
    Describe 'Test-SqlPath' {
        #guard mock to avoid calling the server
        Mock Execute-WithResult {}  

        Context 'Test query result' {
            It 'Returns true when only file exists' {
                # -- Arrange
                Mock Execute-WithResult { Get-FileExistsMockData -FileExists:$true -DirectoryExists:$false } 

                # -- Act
                $actual = Test-SqlPath -SqlServer 'dummy' -Path 'dummyPath' 
        
                # -- Assert
                $actual | Should Be $True
            }

            It 'Returns true when only directory exists' {
                # -- Arrange
                Mock Execute-WithResult { Get-FileExistsMockData -FileExists:$false -DirectoryExists:$true } 

                # -- Act
                $actual = Test-SqlPath -SqlServer 'dummy' -Path 'dummyPath' 
        
                # -- Assert
                $actual | Should Be $False
            }

            It 'Returns true when both directory and file exist' {
                # -- Arrange
                Mock Execute-WithResult { Get-FileExistsMockData -FileExists:$true -DirectoryExists:$true } 

                # -- Act
                $actual = Test-SqlPath -SqlServer 'dummy' -Path 'dummyPath' 
        
                # -- Assert
                $actual | Should Be $True
            }

            It 'Returns false when file does not exist and directory does not exist' {
                # -- Arrange
                Mock Execute-WithResult { Get-FileExistsMockData -FileExists:$false -DirectoryExists:$false } 

                # -- Act
                $actual = Test-SqlPath -SqlServer 'dummy' -Path 'dummyPath' 
        
                # -- Assert
                $actual | Should Be $False
            }
        }

        Context 'Test command call' { 
            It 'Calls Execute-WithResult with the correct command' { 
                # -- Arrange 
                $dummy = 'dummyCommand'
                Mock Get-FileExistQuery { $dummy } 
                Mock Execute-WithResult -ParameterFilter { $Command -eq $dummy } 
            
                # -- Act            
                Test-SqlPath -SqlServer 'dummy' -Path 'dummyPath' 

                # -- Assert
                Assert-MockCalled Execute-WithResult -ParameterFilter { $Command -eq $dummy } -Times 1 
            }

            It 'Calls Execute-WithResult with the provided connection' { 
                # -- Arrange 
                $dummy = 'dummySql'
                Mock Execute-WithResult -ParameterFilter { $SqlServer -eq $dummy } 
            
                # -- Act            
                Test-SqlPath -SqlServer $dummy -Path 'dummyPath' 

                # -- Assert
                Assert-MockCalled Execute-WithResult -ParameterFilter { $SqlServer -eq $dummy } -Times 1 
            }

            It 'Calls Execute-WithResult with provided credentials' { 
                # -- Arrange 
                $dummy = Get-MockCredential
                Mock Execute-WithResult -ParameterFilter { $SqlCredential -eq $dummy } 
            
                # -- Act            
                Test-SqlPath -SqlServer 'dummy' -Path 'dummyPath' -SqlCredential $dummy
                
                # -- Assert
                Assert-MockCalled Execute-WithResult -ParameterFilter { $SqlCredential -eq $dummy} -Times 1 
            }
        }
    }


    Describe 'Get-FileExistQuery' { 
        It 'Requires path' { 
            { Get-FileExistQuery -Path '' } | Should Throw
        }

        It 'Returns the correct query with path embedded' { 
            Get-FileExistQuery -Path 'C:\temp' | Should Be "EXEC master.dbo.xp_fileexist 'C:\temp'"
        }
    }
}