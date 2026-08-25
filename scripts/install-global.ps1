[CmdletBinding()]
param(
    [ValidateSet("copilot", "codex", "gemini", "junie", "all")]
    [string[]]$Provider = @("copilot"),
    [switch]$Force,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

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
    New-Item -ItemType SymbolicLink -Path $Destination -Target $Source | Out-Null
    Write-Host "linked $Destination -> $Source"
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
    Install-WorkflowSkills (Join-Path $HOME ".copilot/skills")
    Get-ChildItem (Join-Path $Root ".github/agents/*.agent.md") -File | ForEach-Object {
        Install-SymbolicLink $_.FullName (Join-Path $HOME ".copilot/agents/$($_.Name)")
    }
}

function Install-Codex {
    Install-WorkflowSkills (Join-Path $HOME ".agents/skills")
    Get-ChildItem (Join-Path $Root ".github/agents/*.agent.md") -File | ForEach-Object {
        $Name = Get-AgentName $_
        Install-SymbolicLink $_.FullName (Join-Path $HOME ".agents/skills/$Name/SKILL.md")
    }
}

function Install-Gemini {
    Install-WorkflowSkills (Join-Path $HOME ".gemini/skills")
    Get-ChildItem (Join-Path $Root ".github/agents/*.agent.md") -File | ForEach-Object {
        $Name = Get-AgentName $_
        Install-SymbolicLink $_.FullName (Join-Path $HOME ".gemini/agents/$Name.md")
    }
}

function Install-Junie {
    Install-WorkflowSkills (Join-Path $HOME ".junie/skills")
    Get-ChildItem (Join-Path $Root ".github/agents/*.agent.md") -File | ForEach-Object {
        $Name = Get-AgentName $_
        Install-SymbolicLink $_.FullName (Join-Path $HOME ".junie/agents/$Name.md")
    }
}

foreach ($Name in $Provider) {
    & "Install-$Name"
}
