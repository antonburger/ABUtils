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
            $repo = Resolve-GitRepo $repo -ErrorAction SilentlyContinue
            if ($null -eq $repo) { return @() }

            $revisions = @(& git -C "$repo" for-each-ref --format='%(refname:short)') +
                @(& git -C "$repo" for-each-ref --format='%(refname)') +
                @(& git -C "$repo" rev-list --all --abbrev-commit)

            $revisions | Where-Object { $_ -ilike "${wordToComplete}*" }
        })]
        [string]
        $Revision,

        [Parameter(Mandatory, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter({
            param ($commandName, $paramName, $wordToComplete, $commandAst, $boundParameters)

            if (-not $boundParameters.ContainsKey('Revision')) { return @() }
            $rev = $boundParameters.Revision
            $repo = if ($boundParameters.ContainsKey('RepoDirectory')) { $boundParameters.RepoDirectory } else { '.' }
            $repo = Resolve-GitRepo $repo -ErrorAction SilentlyContinue
            if ($null -eq $repo) { return @() }

            $files = & git -C "$repo" ls-tree -r --name-only "$rev"

            if ($LASTEXITCODE -ne 0) { return @() }

            $files | Where-Object { $_ -ilike "${wordToComplete}*" }
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
