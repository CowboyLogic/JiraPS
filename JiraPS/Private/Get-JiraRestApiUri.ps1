function Get-JiraRestApiUri {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Resource,

        [string]$ApiVersion = (Get-JiraApiVersion)
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $server = Get-JiraConfigServer -ErrorAction Stop

        # Ensure resource doesn't start with slash
        $Resource = $Resource.TrimStart('/')

        return "$server/rest/api/$ApiVersion/$Resource"
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
