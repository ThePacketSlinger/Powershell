
Function Global:Get-Software {
    <#
I knew I needed something to inventory software that pulled from the registry rather than
using WMI which not only takes forever but it also triggers consistency checks and possible repairs of each installed item.
While researching I came across an article (https://mcpmag.com/articles/2017/07/27/gathering-installed-software-using-powershell.aspx)
that covered the issue and showed how to pull this all from the registry instead. I was pretty relieved when I saw this because
I know that the uninstall trees in the registry are inconsistent and don't always have all the properties and I wasn't sure
how I was going to handle all of that. Luckily, this implementation was really good and already did everything I needed. 

I copied  the code from the article and edited it in Code after failing to find it 
on GitHub. I did eventually find it (https://github.com/proxb/ServerInventoryReport/blob/master/Invoke-ServerInventoryDataGathering.ps1 Get-Software function starts on line 405)

All of the changes I've made have been purely cosmetic (white space / indentation) and comments.

Registry paths:
    HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
    HKLM:\SOFTWARE\Wow6432node\Microsoft\Windows\CurrentVersion\Uninstall
#>
    [OutputType('System.Software.Inventory')]  
    [Cmdletbinding()]   
    Param(   
        [Parameter(ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]   
        [String[]]$Computername = $env:COMPUTERNAME  
    )           
    Begin {}  
    Process {       
        ForEach ($Computer in  $Computername) {   
            If (Test-Connection -ComputerName  $Computer -Count  1 -Quiet) {  
                $Paths = @("SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall", "SOFTWARE\\Wow6432node\\Microsoft\\Windows\\CurrentVersion\\Uninstall")           
                ForEach ($Path in $Paths) {   
                    Write-Verbose  "Checking Path: $Path"
                    #  Create an instance of the Registry Object and open the HKLM base key   
                    Try { $reg = [microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine', $Computer, 'Registry64') } 
                    Catch { Write-Error $_ ; Continue; } 
                    #  Drill down into the Uninstall key using the OpenSubKey Method   
                    Try {
                        $regkey = $reg.OpenSubKey($Path)    
                        # Retrieve an array of string that contain all the subkey names   
                        $subkeys = $regkey.GetSubKeyNames()        
                        # Open each Subkey and use GetValue Method to return the required  values for each 
                        ForEach ($key in $subkeys) {     
                            Write-Verbose "Key: $Key"  
                            $thisKey = $Path + "\\" + $key   
                            Try {    
                                $thisSubKey = $reg.OpenSubKey($thisKey)     
                                # Prevent Objects with empty DisplayName   
                                $DisplayName = $thisSubKey.getValue("DisplayName")  
                                If ($DisplayName -AND $DisplayName -notmatch '^Update  for|rollup|^Security Update|^Service Pack|^HotFix') {  
                                    $Date = $thisSubKey.GetValue('InstallDate')  
                                    If ($Date) {  
                                        Try { $Date = [datetime]::ParseExact($Date, 'yyyyMMdd', $Null) } 
                                        Catch {  
                                            Write-Warning "$($Computer): $_ <$($Date)>"  
                                            $Date = $Null  
                                        }  
                                    } 
                            
                                    # Create New Object with empty Properties   
                                    $Publisher = Try { $thisSubKey.GetValue('Publisher').Trim() }   
                                    Catch { $thisSubKey.GetValue('Publisher') }  
                                    #Some weirdness with trailing [char]0 on some strings
                                    $Version = Try { $thisSubKey.GetValue('DisplayVersion').TrimEnd(([char[]](32, 0))) } 
                                    Catch { $thisSubKey.GetValue('DisplayVersion') }  
                                    $UninstallString = Try { $thisSubKey.GetValue('UninstallString').Trim() }   
                                    Catch { $thisSubKey.GetValue('UninstallString') }  
                                    $InstallLocation = Try { $thisSubKey.GetValue('InstallLocation').Trim() }   
                                    Catch { $thisSubKey.GetValue('InstallLocation') }  
                                    $InstallSource = Try { $thisSubKey.GetValue('InstallSource').Trim() } 
                                    Catch { $thisSubKey.GetValue('InstallSource') }  
                                    $HelpLink = Try { $thisSubKey.GetValue('HelpLink').Trim() }   
                                    Catch { $thisSubKey.GetValue('HelpLink') }  

                                    $Object = [pscustomobject]@{
                                        Computername    = $Computer
                                        DisplayName     = $DisplayName
                                        Version         = $Version
                                        InstallDate     = $Date
                                        Publisher       = $Publisher
                                        UninstallString = $UninstallString
                                        InstallLocation = $InstallLocation
                                        InstallSource   = $InstallSource
                                        HelpLink        = $thisSubKey.GetValue('HelpLink')
                                        EstimatedSizeMB = [decimal]([math]::Round(($thisSubKey.GetValue('EstimatedSize') * 1024) / 1MB, 2))  
                                    }
                            
                                    $Object.pstypenames.insert(0, 'System.Software.Inventory')  
                                    Write-Output $Object  
                                } # End of If DisplayName filter 
                            } # End of try block for open sub key 
                            Catch { Write-Warning "$Key : $_" }     
                        } # End of foreach key in subkeys block "Open each Subkey and use GetValue Method to return the required  values for each"
                    }
                    Catch {}     
                    $reg.Close()   
                } # End of foreach path in paths loop   
            } # End of If block for test-connection
            Else { Write-Error  "$($Computer): unable to reach remote system!" }  
        } # End of foreach computer in computers block 
    } # End of Process block   
} # End of Function block

