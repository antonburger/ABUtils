Set-StrictMode -Version Latest

function Get-GitFileContent
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Alias('Repo')]
        [string]
        $RepoDirectory = '.',

        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter({
            param ($commandName, $paramName, $wordToComplete, $commandAst, $boundParameters)

            $repo = if ($boundParameters.ContainsKey('RepoDirectory')) { $boundParameters.RepoDirectory } else { '.' }

            Get-GitRevisions -RepoDirectory $repo -ErrorAction SilentlyContinue | Where-Object { $_ -ilike "${wordToComplete}*" }
        })]
        [string]
        $Revision,

        [Parameter(Mandatory, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter({
            param ($commandName, $paramName, $wordToComplete, $commandAst, $boundParameters)

            $rev = $boundParameters.Revision
            if ($null -eq $rev) { return @() }
            $repo = if ($boundParameters.ContainsKey('RepoDirectory')) { $boundParameters.RepoDirectory } else { '.' }

            Get-GitRevisionFiles -RepoDirectory $repo -Revision $rev -ErrorAction SilentlyContinue | Where-Object { $_ -ilike "${wordToComplete}*" }
        })]
        [string]
        $FilePath
    )

    $gitdir = Resolve-GitRepo $RepoDirectory

    $result = & git -C "$gitdir" cat-file -p "${Revision}:${FilePath}" 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw $result
    }

    $result
}

function Resolve-GitRepo
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Alias('Repo')]
        [string]
        $RepoDirectory = '.'
    )

    $RepoDirectory = Resolve-Path -Path $RepoDirectory -ErrorAction Stop
    $gitdir = & git -C "$RepoDirectory" rev-parse --absolute-git-dir 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Not a git directory: $RepoDirectory"
        return $null
    }

    Resolve-Path $gitdir
}

function Get-GitRevisions
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Alias('Repo')]
        [string]
        $RepoDirectory = '.'
    )

    $repo = Resolve-GitRepo -RepoDirectory $RepoDirectory
    if ($null -eq $repo)
    {
        return $null
    }

    @(& git -C "$repo" for-each-ref --format='%(refname:short)') +
        @(& git -C "$repo" for-each-ref --format='%(refname)') +
        @(& git -C "$repo" rev-list --all --abbrev-commit)
}

function Get-GitRevisionFiles
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Alias('Repo')]
        [string]
        $RepoDirectory = '.',

        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Revision
    )

    $repo = Resolve-GitRepo -RepoDirectory $RepoDirectory
    if ($null -eq $repo)
    {
        return $null
    }

    $files = & git -C "$repo" ls-tree -r --name-only "$Revision"
    if ($LASTEXITCODE -ne 0)
    {
        Write-Error $files
        return $null
    }

    $files
}
