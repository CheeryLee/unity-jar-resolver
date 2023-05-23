[string] $global:MsBuildPath = ""
[string] $global:UnityPath = ""
[string] $global:Configuration = "Release"
[bool] $global:KeepAll = $false

function Build {
    [string] $MsBuildExe = $global:MsBuildPath + "\MSBuild.exe"
    [string] $OutputPath = "$PSScriptRoot\..\output"

    if ($global:MsBuildPath -eq "" -or -not (Test-Path -Path $MsBuildExe -PathType Leaf)) {
        PrintError -Message ("MSBuild executable wasn't found at this path: " + $global:MsBuildPath)
        exit
    }

    if ($global:UnityPath -eq "" -or -not (Test-Path -Path $global:UnityPath)) {
        PrintError -Message ("Path to Unity is wrong, folder doesn't exist: " + $global:UnityPath)
        exit
    }

    # clean bin and obj folders
    Get-ChildItem "$PSScriptRoot\..\source" -Include bin,obj -Recurse | ForEach-Object {
        Remove-Item $_.FullName -Force -Recurse
    }

    if (-not (Test-Path $OutputPath)) {
        New-Item $OutputPath -ItemType Directory
    }

    # clean build folder
    Get-ChildItem $OutputPath | ForEach-Object {
        Remove-Item $_.FullName -Force
    }

    PrintLog -Message ("MsBuildPath: " + $global:MsBuildPath)
    PrintLog -Message ("UnityPath: " + $global:UnityPath)
    PrintLog -Message ("Configuration: " + $global:Configuration)

    [string[]] $ProcArgs = "-property:UnityHintPath=`"$UnityPath\Editor\Data\Managed`"",
        "-property:UnityIosPath=`"$UnityPath\Editor\Data\PlaybackEngines\iOSSupport`"" ,
        "-property:OutputPath=`"$OutputPath`"",
        "-property:Configuration=$Configuration",
        "-m",
        "`"$PSScriptRoot\..\source`""
    
    & $MsBuildExe $ProcArgs

    if ($global:KeepAll -ne $true) {
        Get-ChildItem $OutputPath | Where-Object {
            $_.Name -notlike "Google*"
        } | ForEach-Object {
            Remove-Item $_.FullName -Force
        }
    }
}

function ParseArguments {
    param (
        [string[]] $ScriptArgs
    )

    if ($ScriptArgs[0] -eq "-h" -or $ScriptArgs[0] -eq "-help" -or $ScriptArgs.Count -eq 0) {
        PrintHelp
        exit
    }

    foreach ($ArgPair in $ScriptArgs) {
        [string[]] $ArgPairSplit = $ArgPair.Split("=")

        switch ($ArgPairSplit[0]) {
            "-msBuildPath"
            {
                $global:MsBuildPath = $ArgPairSplit[1].Replace("`"", "")

            }
            "-unityPath"
            {
                $global:UnityPath = $ArgPairSplit[1].Replace("`"", "")
            }
            "-configuration"
            {
                if ($ArgPairSplit[1] -ne "Debug" -and $ArgPairSplit[1] -ne "Release") {
                    PrintError -Message ("Build configuration is unknown: " + $ArgPairSplit[1])
                    exit
                }

                $global:Configuration = $ArgPairSplit[1]
            }
            "-keepAll"
            {
                $global:KeepAll = $true
            }
            Default
            {
                PrintError -Message ("Unknown argument has been passed: " + $ArgPairSplit[0])
                exit
            }
        }
    }
}

function PrintHelp {
    PrintLog -Message "EDM4U build script for Windows
    Arguments:
        -msBuildPath=<path>             - path to MSBuild executable
        -unityPath=<path>               - path to Unity installation
        -configuration=<Debug|Release>  - build configuration
        -keepAll                        - keep all assemblies after build
        -help, -h                       - show this help
    "
}

function PrintLog {
    param (
        [string] $Message = ""
    )

    [System.Console]::ResetColor()
    [System.Console]::Error.WriteLine($Message)
}

function PrintError {
    param (
        [string] $Message = ""
    )

    [System.Console]::ForegroundColor = "red"
    [System.Console]::Error.WriteLine($Message)
    [System.Console]::ResetColor()
}

ParseArguments -ScriptArgs $args
Build