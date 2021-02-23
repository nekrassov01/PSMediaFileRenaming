#Requires -Version 5.1

<#
.SYNOPSIS
Get the latest serial number that is not used for the file name in the folder.

.NOTES
Author: nekrassov01
#>

function Get-FileNameWithLatestSerialNumber
{
    [CmdletBinding()]
    [OutputType([psobject[]])]
    param
    (
        [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo[]]$TargetDirectory,

        [Parameter(Position = 1, Mandatory = $false)]
        [string]$Format,

        [Parameter(Position = 2, Mandatory = $false)]
        [string]$Extension,

        [Parameter(Position = 3, Mandatory = $false)]
        [int]$Limit = 999
    )
    
    begin
    {
        Set-StrictMode -Version Latest
    }

    process
    {
        try
        {
            $padding = '0' * ($limit | Measure-Object -Character).Characters

            foreach ($t in $targetDirectory)
            {
                # Run only if the parameter passed is a directory
                if ((Get-Item -LiteralPath $t).PSIsContainer)
                {
                    for ($i = 1; $i -le $limit + 1; $i++)
                    {
                        $serialNumber = $i.ToString($padding)

                        if ($PSBoundParameters.ContainsKey('Format'))
                        {
                            $newName = [System.String]::Format($format, $serialNumber)
                        }
                        else
                        {
                            $newName = $serialNumber
                        }

                        if ($PSBoundParameters.ContainsKey('Extension'))
                        {
                            $newName = $newName, $extension -join $null
                        }

                        $newFilePath = Join-Path -Path $t -ChildPath $newName

                        # Run only if the same file path does not exist
                        if (-not (Test-Path -LiteralPath $newFilePath))
                        {
                            # If the upper limit has not been reached, return the number and exit
                            if ($i -le $limit)
                            {
                                $obj = [PSCustomObject]@{
                                    Directory    = $t
                                    Name         = $newName
                                    FullName     = $newFilePath
                                    Extension    = $extension
                                    Format       = $format
                                    SerialNumber = $serialNumber
                                    Limit        = $limit
                                }
                                
                                $PSCmdlet.WriteObject($obj)    
                                break
                            }
                            else
                            {
                                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                                    [System.Management.Automation.PSArgumentOutOfRangeException]::new(),
                                    'ResultReachedLimit',
                                    [System.Management.Automation.ErrorCategory]::InvalidResult,
                                    $t
                                )
                                $PSCmdlet.ThrowTerminatingError($errorRecord)
                            }
                        }
                    }
                }
                else
                {
                    $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                        [System.Management.Automation.PSArgumentException]::new('You will need to specify the directory'),
                        'ItemTypeException',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $t
                    )
                    $PSCmdlet.ThrowTerminatingError($errorRecord)
                }
            }
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}
