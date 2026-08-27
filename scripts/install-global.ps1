[CmdletBinding()]
param(
    [ValidateSet("copilot", "codex", "gemini", "junie", "all")]
    [string[]]$Provider = @("copilot"),
    [switch]$Force,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
# Use a dedicated destination override for CI/tests without repurposing HOME.
$TargetHome = if ($env:SDLC_INSTALL_HOME) { $env:SDLC_INSTALL_HOME } else { $HOME }

if ($Provider -contains "all") {
    $Provider = @("copilot", "codex", "gemini", "junie")
}

function Install-SymbolicLink {
    param(
        [Parameter(Mandatory)]
        [string]$Source,
        [Parameter(Mandatory)]
        [string]$Destination
    )

    $Source = (Resolve-Path $Source).Path
    $Existing = Get-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue

    if ($null -ne $Existing -and $Existing.LinkType -eq "SymbolicLink") {
        $ExistingTarget = @($Existing.Target)[0]
        if ($null -ne $ExistingTarget -and
            [System.IO.Path]::GetFullPath($ExistingTarget) -eq $Source) {
            Write-Host "unchanged $Destination"
            return
        }
    }

    if ($null -ne $Existing) {
        if (-not $Force) {
            throw "Refusing to replace $Destination (use -Force)"
        }
        if ($DryRun) {
            Write-Host "would replace $Destination -> $Source"
            return
        }
        Remove-Item -LiteralPath $Destination -Force
    }
    elseif ($DryRun) {
        Write-Host "would link $Destination -> $Source"
        return
    }

    $Parent = Split-Path -Parent $Destination
    New-Item -ItemType Directory -Path $Parent -Force | Out-Null
    try {
        New-Item -ItemType SymbolicLink -Path $Destination -Target $Source -ErrorAction Stop | Out-Null
        Write-Host "linked $Destination -> $Source"
    }
    catch {
        # Symlink creation needs admin rights or Developer Mode on Windows; fall back to a copy.
        Copy-Item -LiteralPath $Source -Destination $Destination -Force
        Write-Warning "No permission to create symlinks (enable Windows Developer Mode or run as admin for live links). Copied $Destination instead; re-run after editing sources to refresh it."
    }
}

function Install-WorkflowSkills {
    param(
        [Parameter(Mandatory)]
        [string]$DestinationRoot
    )

    Get-ChildItem (Join-Path $Root ".github/skills") -Directory | ForEach-Object {
        $Destination = Join-Path $DestinationRoot $_.Name
        Install-SymbolicLink (Join-Path $_.FullName "SKILL.md") (Join-Path $Destination "SKILL.md")
        Install-SymbolicLink (Join-Path $_.FullName "workflow.md") (Join-Path $Destination "workflow.md")
    }
}

function Get-AgentName {
    param(
        [Parameter(Mandatory)]
        [System.IO.FileInfo]$Agent
    )

    return $Agent.Name -replace "\.agent\.md$", ""
}

function Install-Copilot {
    Install-WorkflowSkills (Join-Path $TargetHome ".copilot/skills")
    Get-ChildItem (Join-Path $Root ".github/agents/*.agent.md") -File | ForEach-Object {
        Install-SymbolicLink $_.FullName (Join-Path $TargetHome ".copilot/agents/$($_.Name)")
    }
}

function Install-Codex {
    Install-WorkflowSkills (Join-Path $TargetHome ".agents/skills")
    $CodexSkills = Join-Path $Root ".codex/skills"
    Get-ChildItem $CodexSkills -Directory | ForEach-Object {
        $Skill = $_
        Get-ChildItem $Skill.FullName -File -Recurse | ForEach-Object {
            # Compatible with Windows PowerShell 5.1, where Path.GetRelativePath
            # is unavailable. Every enumerated file is guaranteed to be a child.
            $Relative = $_.FullName.Substring($Skill.FullName.Length) -replace '^[\\/]+', ''
            Install-SymbolicLink $_.FullName (Join-Path $TargetHome ".agents/skills/$($Skill.Name)/$Relative")
        }
    }
    Get-ChildItem (Join-Path $Root ".github/agents/*.agent.md") -File | ForEach-Object {
        $Name = Get-AgentName $_
        Install-SymbolicLink $_.FullName (Join-Path $TargetHome ".agents/skills/autonomous-sdlc/references/roles/$Name.agent.md")
    }
}

function Install-Gemini {
    Install-WorkflowSkills (Join-Path $TargetHome ".gemini/skills")
    Get-ChildItem (Join-Path $Root ".github/agents/*.agent.md") -File | ForEach-Object {
        $Name = Get-AgentName $_
        Install-SymbolicLink $_.FullName (Join-Path $TargetHome ".gemini/agents/$Name.md")
    }
}

function Install-Junie {
    Install-WorkflowSkills (Join-Path $TargetHome ".junie/skills")
    Get-ChildItem (Join-Path $Root ".github/agents/*.agent.md") -File | ForEach-Object {
        $Name = Get-AgentName $_
        Install-SymbolicLink $_.FullName (Join-Path $TargetHome ".junie/agents/$Name.md")
    }
}

foreach ($Name in $Provider) {
    & "Install-$Name"
}
