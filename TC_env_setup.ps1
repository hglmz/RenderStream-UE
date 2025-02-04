﻿param(
    [Boolean]$debug_force_remote_disk = $False, # Force useage of the builds-agent-share install of unreal
    [string] $builds_agent_share_ip = "10.105.1.219", # to allow flexibitlity if builds agent share changes  
    [string[]] [Parameter (Position = 2, ValueFromRemainingArguments )] $RemainingArgs
)

$PsBoundParameters | Format-Table


# figure out the unreal install location
# if the the machine is a build agent or the debug param has been specified then mount the network drive
# Otherwise use the local install 


# gets the file name from the uplugin_template.json  
function select-UE_engine_from_json
 {    
    $Uplugin = Get-Content -Raw -Path 'RenderStream-UE.uplugin' | ConvertFrom-Json
    $EngineVersion = $Uplugin.EngineVersion
    $major, $minor, $micro = $EngineVersion -split "\."
    return "UE_$major.$minor"
}


function connect-network_drive{ param($server_ip) 

    $engine_version = select-UE_engine_from_json
    
    # Debug information
    # Verify and cleanup any traces of previous builds on the agents 
    Write-Host "current directory is:"; Get-Location
    Write-Host "list of connected drives"; Get-PSDrive
    Write-Host "verifying connection to builds agent share"

    if ( -not ( Test-Connection $server_ip )) {
        Throw "cannot connect to builds agent share"
    }

    write-host "Cleaning up any disks and symbolic links from previous runs"
    Get-PSDrive K -ErrorAction SilentlyContinue | Remove-PSDrive -ErrorAction SilentlyContinue

    if (test-path "..\..\link_to_unreal\"){
        (get-item ..\..\link_to_unreal\).Delete()
    }

    # Make new drive and create a directory sym link, Error action is set to stop since without this the build cannot run 
    Write-host "connecting network drive to builds agent share"
    New-PSDrive –Name "K" -PSProvider FileSystem -Root "\\$server_ip\Epic Games" -ErrorAction Stop

    Write-Host "Creating symbolic link"
    new-item -itemtype SymbolicLink -path "..\..\" -name "link_to_unreal"  -value "K:\" -ErrorAction Stop

    # N.B Making the symbolic link requires elevated permissions; to get this working without elevating the script you need to go to:
    #     win search > Local security policy > local policy > user rights assignment > create symbolic links > add builds user  


    # Verify drive and symlink setups are working 
    write-host "Can access the $engine_version build tool through network drive? "
    write-host "K:\$engine_version\Engine\Build\BatchFiles\RunUAT.bat"

    if (-not (Test-Path "K:\$engine_version\Engine\Build\BatchFiles\RunUAT.bat")){

        throw "cannot access shared drive on builds agent share"
    }

    #write-host "check that symbolic link can be accessed"
    #write-host "C:\link_to_unreal\$engine_version"
    #if (-not (Test-Path "C:\link_to_unreal\$engine_version")){
#
    #    throw "cannot access unreal engine through symbolic link"
    #}

    # For packaging on Team City    
}

connect-network_drive $builds_agent_share_ip

$engine_version = select-UE_engine_from_json
$build_tool_path = "C:\link_to_unreal\$engine_version"
# This shouldn't be done, ideally we should use the service pipes to send information between script and let teamcity call them,
# but the refrence to the mapped drive will be lost when the script ends, therefore its better to call the package step from
# here  
Invoke-Expression ".\package_plugin.ps1 -unreal_engine_path $build_tool_path"

