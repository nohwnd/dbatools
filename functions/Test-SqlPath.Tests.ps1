$root = Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path
Import-Module "$root\dbatools.psd1"

function Get-FileExistsMockData {
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
    <File_x0020_is_x0020_a_x0020_Directory>1</File_x0020_is_x0020_a_x0020_Directory>
    <Parent_x0020_Directory_x0020_Exists>1</Parent_x0020_Directory_x0020_Exists>
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

Describe 'Test-SqlPath' {
    It 'Returns true when file exists' {
        # -- Arrange
        Mock Execute-WithResult { Get-FileExistsMockData } -ModuleName 'dbatools'

        # -- Act
        $actual = Test-SqlPath -SqlServer 'dummy' -Path 'dummyPath' 
        
        # -- Assert
        $actual | Should Be True
    }
}

InModuleScope -ModuleName dbatools {
    Describe 'Get-FileExistQuery' { 
        It 'Requires path' { 
            { Get-FileExistQuery -Path '' } | Should Throw
        }

        It 'Returns the correct query with path embedded' { 
            Get-FileExistQuery -Path 'C:\temp' | Should Be "EXEC master.dbo.xp_fileexist 'C:\temp'"
        }
    }
}