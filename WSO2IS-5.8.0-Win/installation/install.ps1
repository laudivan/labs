$Env:CARBON_HOME = "C:\Aliare\WSO2IS\wso2is-5.8.0"
[System.Environment]::SetEnvironmentVariable(
    "CARBON_HOME", 
    $Env:CARBON_HOME, 
    [System.EnvironmentVariableTarget]::Machine
)

$Env:JAVA_HOME = "C:\Aliare\jdk1.8.0_351"
[System.Environment]::SetEnvironmentVariable(
    "JAVA_HOME", 
    $Env:JAVA_HOME, 
    [System.EnvironmentVariableTarget]::Machine
)

New-Item -ItemType Directory -Path 'C:\Aliare\WSO2IS'

Expand-Archive -Path "$env:USERPROFILE\Downloads\wso2is-5.8.0-rc1.zip" -Force -DestinationPath 'C:\Aliare\WSO2IS'

Expand-Archive -Path "$env:USERPROFILE\Downloads\yajsw-stable-11.11.zip" -Force -DestinationPath 'C:\Aliare\WSO2IS'

& "$env:USERPROFILE\Downloads\jdk-8u351-windows-x64.exe" /s ADDLOCAL="ToolsFeature,SourceFeature,PublicjreFeature" INSTALLDIR=$Env:JAVA_HOME


Set-Location -Path C:\Aliare\WSO2IS\yajsw-stable-11.11\bat

.\installService.bat

.\startService.bat