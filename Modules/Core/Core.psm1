function Initialize-Folders 
{
<#
    .SYNOPSIS
        Ensures that folders are available and creates them if they don't already exist.
    .EXAMPLE
        Prep-Folders -Path C:\Local
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string] $Path
    )

    begin {
    }
    
    process {
        If (!(test-path $Path)) {
            Write-Output "The path $Path does not exist, creating it now."
            New-Item -Path $Path -Type Directory -Force | Out-Null
        }
    }
    
    end {
    }
}

function Backup-Files {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string] $Source
        ,
        [Parameter(Mandatory=$true)]
        [string] $Destination
        ,
        [Parameter(Mandatory=$False)]
        [string] $ArchiveOlderThan
        ,
        [Parameter(Mandatory=$False)]
        [switch] $Purge
        ,
        [Parameter(Mandatory=$False)]
        [switch] $Move
        ,
        [Parameter(Mandatory=$False)]
        [switch] $LogFiles
        ,
        [Parameter(Mandatory=$False)]
        [switch] $LogDirectories
        ,
        [Parameter(Mandatory=$False)]
        [switch] $Backup
        ,
        [Parameter(Mandatory=$False)]
        [array] $ExcludedDirectories
        ,
        [Parameter(Mandatory=$False)]
        [switch] $CopyAll
    )
    
    begin {
        $Date = Get-Date -UFormat "%Y_%m_%d_%H_%M"
        $Name = $Source.Split('\')[-1]
        $LogDir = "C:\Local\Logs"
        $Logfile = "$LogDir\Robocopy_"+$Name+"_"+$Date+".txt"
        $Options = @("/E","/XO","/R:0","/W:0","/V","/log:$Logfile","/NP","/FFT","/TEE","/NFL","/NDL")
        
        # Handle additional options from switches
        if ($CopyAll) {$Options += "/COPYALL","/DCOPY:DAT"}
        If ($Purge) {$Options += "/PURGE"}
        If ($Move) {$Options += "/MOVE"}
        if ($Backup) {$Options += "/B"}
        if ($ArchiveOlderThan) {$Options += "/MINAGE:$ArchiveOlderThan"}        
        if ($ExcludedDirectories) {
                # Can't add directory exclusion to options, they have to be part of the source, destination part of the command
                Write-Output "Excluded directories provided: $ExcludedDirectories"

                # Make sure we can see all the excluded directories
                # This is to ensure that sensitive data is never accidentally copied to an insecure location
                foreach ($Dir in $ExcludedDirectories) {
                    if ((Test-Path -Path $Dir) -eq $False) {
                        Write-Output "Excluded directory $Dir could not be found. Exiting."
                        Exit
                    }
                    Else {Write-Output "Excluded directory $Dir exists."}
                }
               
            }
        # Create Destination if it doesn't exist
        Initialize-Folders -Path $Destination
        
        # Create LogDir if it doesn't exist
        Initialize-Folders -Path $LogDir
        
    }
    
    process {
        robocopy.exe $Source $Destination /XD $ExcludedDirectories $Options
    }
    
    end {
    }
}


Function Get-TimeStamp {
    $timestamp = get-date -Format yyyy-MM-dd-HH-mm
    $timestamp
}

Function Get-Directories {
    param (
        [Parameter(Mandatory=$true)]
        [string] $Path
        
    )
    IF (Test-Path $Path) {
        # Get list of directories, use cmd /c to avoid creation of PSobjects for each file which kills performance 
        $Directories = (cmd /c "dir $Path /s /A:D" | Select-String "Directory of ") | foreach {$_.tostring().Replace('Directory of ','').Trim()}
        $Directories
    }
    Else {Write-Error "Path provided does not exist."}    
}

function Global:Set-Profile {
    [CmdletBinding()]
    
    param (
        # Specifies a path to one or more locations.
        [Parameter(Mandatory=$false,
                   Position=0,
                   ParameterSetName="Path",
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Path to the source profile script.")]
        [Alias("PSPath")]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Path = "$Repo\Production\Profiles\Profile.ps1"
    )
    
    begin {
        # NEED TO ADD - Backup old Profile. Do this after Get-Timestamp is added to core.
        # Not a priority since it's all in source control
        $Content = Get-Content -Path $Path
    }
    
    process {
        If ($Content) {Set-Content -Value $Content -Path $Profile}
    }
    
    end {
        # Should likely do some error handling/cleanup at some point
    }
}