set-alias -name kitty -value C:\Users\Mike\Dropbox\Utilities\kitty_portable-0.70.0.9.exe
$Data = "C:\Local\Data"
$Environment = "$Data\python3.6-environment-windows.yml"
$Repo = "E:\Repo\Doyle"

function Import-Functions {
    [CmdletBinding()]
    param (
        # Specifies a path to one or more locations.
        [Parameter(Mandatory=$false,
                   Position=0,
                   ParameterSetName="Path",
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Path to the script to dot source. Default is `$Repo\Production\Import-Functions.ps1")]
        [Alias("PSPath")]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Path = "$Repo\Production\Import-Functions.ps1"
    )
    
    begin {
    }
    
    process {
        if (test-path $Path) {
            Write-Output "Running Import-Functions"
            . $Path}
        Else {Write-Error "Couldn't find Import-Functions script!"}
    }
    
    end {
    }
}
# Run Import-Functions function
Import-Functions

