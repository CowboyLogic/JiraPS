function Get-JiraUser {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( DefaultParameterSetName = 'Self' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ByUserName' )]
        [AllowEmptyString()]
        [Alias('User', 'Name')]
        [String[]]
        $UserName,

        [Parameter( Position = 0, Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ByAccountId' )]
        [AllowEmptyString()]
        [String[]]
        $AccountId,

        [Parameter( Position = 0, Mandatory, ParameterSetName = 'ByInputObject' )]
        [Object[]] $InputObject,

        [Parameter( ParameterSetName = 'ByInputObject' )]
        [Parameter( ParameterSetName = 'ByUserName' )]
        [Parameter( ParameterSetName = 'ByAccountId' )]
        [Switch]$Exact,

        [Switch]
        $IncludeInactive,

        [Parameter( ParameterSetName = 'ByUserName' )]
        [Parameter( ParameterSetName = 'ByAccountId' )]
        [ValidateRange(1, 1000)]
        [UInt32]
        $MaxResults = 50,

        [Parameter( ParameterSetName = 'ByUserName' )]
        [Parameter( ParameterSetName = 'ByAccountId' )]
        [ValidateNotNullOrEmpty()]
        [UInt64]
        $Skip = 0,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop

        $selfResourceUri = Get-JiraRestApiUri -Resource "myself"
        $searchResourceUri = Get-JiraRestApiUri -Resource "user/search"
        $exactResourceUri = Get-JiraRestApiUri -Resource "user"

        # Add query parameter based on API version
        $apiVersion = Get-JiraApiVersion
        if ($apiVersion -eq "3") {
            $searchResourceUri += "?accountId={0}"
            $exactResourceUri += "?accountId={0}"
        }
        else {
            $searchResourceUri += "?username={0}"
            $exactResourceUri += "?username={0}"
        }

        if ($IncludeInactive) {
            $searchResourceUri += "&includeInactive=true"
        }
        if ($MaxResults) {
            $searchResourceUri += "&maxResults=$MaxResults"
        }
        if ($Skip) {
            $searchResourceUri += "&startAt=$Skip"
        }
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $ParameterSetName = ''
        switch ($PsCmdlet.ParameterSetName) {
            'ByInputObject' {
                # Determine if we should use username or accountId based on API version and available properties
                $apiVersion = Get-JiraApiVersion
                if ($apiVersion -eq "3" -and $InputObject.AccountId) {
                    $AccountId = $InputObject.AccountId
                    $ParameterSetName = 'ByAccountId'
                    $Exact = $true
                }
                elseif ($InputObject.Name) {
                    $UserName = $InputObject.Name
                    $ParameterSetName = 'ByUserName'
                    $Exact = $true
                }
                else {
                    throw "InputObject must have Name or AccountId property"
                }
            }
            'ByUserName' { $ParameterSetName = 'ByUserName' }
            'ByAccountId' { $ParameterSetName = 'ByAccountId' }
            'Self' { $ParameterSetName = 'Self' }
        }

        switch ($ParameterSetName) {
            "Self" {
                $resourceURi = $selfResourceUri

                $parameter = @{
                    URI        = $resourceURi
                    Method     = "GET"
                    Credential = $Credential
                }
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                $result = Invoke-JiraMethod @parameter

                # Recursively call Get-JiraUser with the appropriate parameter based on API version
                $apiVersion = Get-JiraApiVersion
                if ($apiVersion -eq "3" -and $result.accountId) {
                    Get-JiraUser -AccountId $result.accountId -Exact
                }
                else {
                    Get-JiraUser -UserName $result.Name -Exact
                }
            }
            "ByAccountId" {
                $resourceURi = if ($Exact) { $exactResourceUri } else { $searchResourceUri }

                foreach ($accountId in $AccountId) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$accountId]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$accountId [$accountId]"

                    $parameter = @{
                        URI        = $resourceURi -f $accountId
                        Method     = "GET"
                        Credential = $Credential
                    }
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    if ($users = Invoke-JiraMethod @parameter) {
                        foreach ($item in $users) {
                            $parameter = @{
                                URI        = "{0}&expand=groups" -f $item.self
                                Method     = "GET"
                                Credential = $Credential
                            }
                            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                            $result = Invoke-JiraMethod @parameter

                            Write-Output (ConvertTo-JiraUser -InputObject $result)
                        }
                    }
                    else {
                        $errorMessage = @{
                            Category         = "ObjectNotFound"
                            CategoryActivity = "Searching for user"
                            Message          = "No results when searching for user $accountId"
                        }
                        Write-Error @errorMessage
                    }
                }
            }
            "ByUserName" {
                $resourceURi = if ($Exact) { $exactResourceUri } else { $searchResourceUri }

                foreach ($user in $UserName) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$user]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$user [$user]"

                    $parameter = @{
                        URI        = $resourceURi -f $user
                        Method     = "GET"
                        Credential = $Credential
                    }
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    if ($users = Invoke-JiraMethod @parameter) {
                        foreach ($item in $users) {
                            $parameter = @{
                                URI        = "{0}&expand=groups" -f $item.self
                                Method     = "GET"
                                Credential = $Credential
                            }
                            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                            $result = Invoke-JiraMethod @parameter

                            Write-Output (ConvertTo-JiraUser -InputObject $result)
                        }
                    }
                    else {
                        $errorMessage = @{
                            Category         = "ObjectNotFound"
                            CategoryActivity = "Searching for user"
                            Message          = "No results when searching for user $user"
                        }
                        Write-Error @errorMessage
                    }
                }
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
