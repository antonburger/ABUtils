function Get-GitFileContent
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [Alias('Repo')]
        [IO.DirectoryInfo]
        $RepoDirectory = './.git',
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Revision = 'master',
        [Parameter(Mandatory, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
    )
}
