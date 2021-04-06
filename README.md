StorageHC_PSTK
Please find below pre-requisites for the script setup.

1.	Install Nuget (Required to install posh-ssh)
Run in Powershell:
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

2.	Install posh-ssh (Dependency Nuget, Required to ssh to Cluster)
3.	Run in Powershell:
Find-Module Posh-SSH | Install-Module

4.	Install NetApp PSTK(Required to connect to the cluster):
Download and Install
https://mysupport.netapp.com/site/tools/tool-eula/powershell-toolkit

5.	Download and unzip PSTools(Required for executing the script as NT Autority\system as Opsramp requirement):
https://docs.microsoft.com/en-us/sysinternals/downloads/pstools
