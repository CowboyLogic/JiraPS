function Get-JiraUserIdentifier {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$User,

        [string]$ApiVersion = (Get-JiraApiVersion)
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($ApiVersion -eq "3") {
            # v3 requires accountId
            if ($User.AccountId) {
                return @{
                    ParameterName = "accountId"
                    Value = $User.AccountId
                }
            }
            elseif ($User -is [string]) {
                # Assume string is accountId in v3 mode
                return @{
                    ParameterName = "accountId"
                    Value = $User
                }
            }
            else {
                $errorMessage = "accountId is required for API v3. User object must have AccountId property or be a string representing accountId."
                $exception = ([System.ArgumentException]$errorMessage)
                $errorId = "ParameterType.InvalidUserForV3"
                $errorCategory = 'InvalidArgument'
                $errorTarget = $User
                $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                $PSCmdlet.ThrowTerminatingError($errorItem)
            }
        }
        else {
            # v2 uses username
            if ($User.Name) {
                return @{
                    ParameterName = "username"
                    Value = $User.Name
                }
            }
            elseif ($User -is [string]) {
                return @{
                    ParameterName = "username"
                    Value = $User
                }
            }
            else {
                $errorMessage = "username is required for API v2. User object must have Name property or be a string representing username."
                $exception = ([System.ArgumentException]$errorMessage)
                $errorId = "ParameterType.InvalidUserForV2"
                $errorCategory = 'InvalidArgument'
                $errorTarget = $User
                $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                $PSCmdlet.ThrowTerminatingError($errorItem)
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
