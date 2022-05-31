function Pause($message="Appuyer sur une touche pour continuer")
{ 
 Write-Host -noNewline $message
 $null = $host.UI.rawUI.ReadKey("Noecho,includeKeydown")
}

function Win10() {
    $DefaultPath = "C:\Users\Administrateur\Desktop\VM"
    $switchName = "WAN"
    $NOMDELAVM = Read-Host "Saisir nom VM"
    New-Item -ItemType Directory -Name $NOMDELAVM -path $DefaultPath
    Copy-Item -Path "C:\Users\Administrateur\Desktop\SYSPREP\SRV-CORE.vhdx" -Destination $DefaultPath\$NOMDELAVM\$NOMDELAVM.vhdx
    New-VM -Name $nomdelavm -Generation 1 -MemoryStartupBytes 512MB -SwitchName $SwitchName
    Add-VMHardDiskDrive -VMName $NOMDELAVM -Path $DefaultPath\$NOMDELAVM\$NOMDELAVM.vhdx
    Set-VM -Name $NOMDELAVM -ProcessorCount 2
    Set-VM -Name $NOMDELAVM -CheckpointType Disabled
    Set-VMBios $NOMDELAVM -StartupOrder @("IDE", "CD", "Floppy", "LegacyNetworkAdapter")
    Start-VM -Name $NOMDELAVM
}
function Win19Ggui() {
    $DefaultPath = "C:\Users\Administrateur\Desktop\VM"
    $switchName = "WAN"
    $NOMDELAVM = Read-Host "Saisir nom VM"
    New-item -ItemType Directory -Name $NOMDELAVM -path $DefaultPath
    Copy-Item -Path "C:\Users\Administrateur\Desktop\SYSPREP\SRV-GUI.vhdx" -Destination "$DefaultPath\$NOMDELAVM\$NOMDELAVM.vhdx"
    New-VM -Name $NOMDELAVM -Generation 1 -MemoryStartupBytes 4GB  -SwitchName $SwitchName -BootDevice NetworkAdapter -Path $DefaultPath #-NewVHDSizeBytes 50GB#
    Add-VMHardDiskDrive -VMName $NOMDELAVM -Path "$DefaultPath\$NOMDELAVM\$NOMDELAVM.vhdx"
    Set-VM -Name $NOMDELAVM -ProcessorCount 2
    Set-VM -Name $NOMDELAVM -CheckpointType Disabled
    Set-VMBios $NOMDELAVM -StartupOrder @("IDE", "CD", "Floppy", "LegacyNetworkAdapter")
    Start-VM -Name $NOMDELAVM
}
function win19core() {
    $DefaultPath = "C:\Users\Administrateur\Desktop\VM"
    $switchName = "WAN"
    $NOMDELAVM = Read-Host "Saisir nom VM"
    New-Item -ItemType Directory -Name $NOMDELAVM -path $DefaultPath
    Copy-Item -Path "C:\Users\Administrateur\Desktop\SYSPREP\SRV-CORE.vhdx" -Destination $DefaultPath\$NOMDELAVM\$NOMDELAVM.vhdx
    New-VM -Name $nomdelavm -Generation 1 -MemoryStartupBytes 512MB -SwitchName $SwitchName
    Add-VMHardDiskDrive -VMName $NOMDELAVM -Path $DefaultPath\$NOMDELAVM\$NOMDELAVM.vhdx
    Set-VM -Name $NOMDELAVM -ProcessorCount 2
    Set-VM -Name $NOMDELAVM -CheckpointType Disabled
    Set-VMBios $NOMDELAVM -StartupOrder @("IDE", "CD", "Floppy", "LegacyNetworkAdapter")
    Start-VM -Name $NOMDELAVM
}

function CreateAdds(){
    $name = Read-Host "Saisir nom VM"
    $domainName = Read-Host "Saisir un nom de domaine"
    $NetBiosName = $domainName.ToUpper
    Get-Disk | Where-Object IsSystem -eq $False

    for (i=1;i!=3;i++){Initialize-Disk -Number i}
    New-Partition -DiskNumber 1 -DriveLetter B -UseMaximumSize
    New-Partition -DiskNumber 1 -DriveLetter L -UseMaximumSize
    New-Partition -DiskNumber 1 -DriveLetter S -UseMaximumSize

    Import-Module ADDSDeployement
    Install-ADDSForest -CreateDnsDelegation:$false -ForestMode "7" -DomainMode "7" -DomainNetbiosName $NetBiosName -InstallDns:$true -CreateDnsDelegation:$false `
    -DatabasePath "B:\BDD" -LogPath "L:\LOGS" -SysvolPath "S:\SYSVOL" -NoRebootOnCompletion:$false -Force:$true
}

function CreationDisks(){
   # Import-Module ActiveDirectory
  #  $domain=Read-Host "Entrez le nom de domaine: "
 #   $netbios=$domain.ToUpper()
#    if (!(Get-Module -ListAvailable -Name ActiveDirectory))
    $name = Read-Host "Saisir nom VM"
    $DefaultPath = "C:\Users\Administrateur\Desktop\VM\"+$name
    NEW-VHD $DefaultPath"\logs.vhdx" -SizeBytes 4196MB
    NEW-VHD $DefaultPath"\sysvol.vhdx" -SizeBytes 4196MB
    NEW-VHD $DefaultPath"\bdd.vhdx" -SizeBytes 4196MB
    
    Add-VMHardDiskDrive -VMName $name -ControllerType SCSI -ControllerNumber 0 -Path $DefaultPath"\bdd.vhdx"
    Add-VMHardDiskDrive -VMName $name -ControllerType SCSI -ControllerNumber 0 -Path $DefaultPath"\logs.vhdx"
    Add-VMHardDiskDrive -VMName $name -ControllerType SCSI -ControllerNumber 0 -Path $DefaultPath"\sysvol.vhdx"
}

function dnsappli(){
    Get-DnsClientServerAddress
    $intindex=Read-Host "Choisir une interface: "
    $networkcidr=Read-Host "Saisir l'adresse du réseau et le masque au format IP/CIDR"
    $ipv4intindex=(Get-NetIPAddress -InterfaceIndex $intindex -AddressFamily IPv4).IPAddress

    Disable-NetAdapterBinding -Name Ethernet -ComponentID ms_tcpip6 -PassThru
    Add-DnsServerPrimaryZone -NetworkId $networkcidr -ReplicationScope Domain -DynamicUpdate secure
    Set-DnsClientServerAddress -InterfaceIndex $intindex -ServerAddresses $ipv4intindex
    ipconfig /registerdns
    nslookup
}

function domainjoin(){
    $domainname=Read-Host "Saisir le domaine à joindre: "
    $useradmin=Read-Host "Saisir le nom du compte admin du domain: "
    $compteadmin=$useradmin+"@"+$domainname
    
    $cred = Get-Credential -Credential $compteadmin
    Add-Computer -DomainName $domainname -Credential $cred -Restart -Force
}

function RemoveDisks(){
    $name = Read-Host "Saisir le nom de la vm: "
    Get-VMHardDiskDrive -VMName test -ControllerType SCSI| ft -Property ControllerLocation, Path
    $DefaultPath = "C:\Users\Administrateur\Desktop\VM\"+$name
    Write-Host "1: Un seul disques"
    Write-Host "2: Plusieurs disques"
    $ch = Read-Host "Voulez-vous supprimer un ou plusieurs disques"
    switch($ch){
        1 {
            $disk_to_remove = Read-Host "Saisir le numero du disque: "
            Remove-VMHardDiskDrive -ControllerLocation $disk_to_remove -VMName $name -ControllerType SCSI -ControllerNumber 0
            $CHEMIN = Get-VMHardDiskDrive -VMName test -ControllerType SCSI -ControllerLocation $disk_to_remove | Select Path -ExpandProperty Path
            Remove-Item -Path $CHEMIN
        }
        2 {
            $n = 0
            $disklist = New-Object -TypeName System.Collections.ArrayList;
            $going = $True
            while ($going){
                $t = Read-Host "Saisir le numéro du disque: "
                $disklist.Add($t)
                $n = $n + 1
                $test = Read-Host "Voulez-vous en ajouter un autre ? Y/N"
                if ($test -eq "Y" -or $test -eq "y"){
                    continue
                }
                elseif ($test -eq "N" -or $test -eq "n"){
                    $going = $False
                }
                else{
                    $test = Read-Host "Voulez-vous en ajouter un autre ? Y/N"
                }
            }
            foreach ($d in $disklist){
                Remove-VMHardDiskDrive -ControllerLocation $d -VMName $name -ControllerType SCSI -ControllerNumber 0
                $CHEMIN = Get-VMHardDiskDrive -VMName test -ControllerType SCSI -ControllerLocation $d | Select Path -ExpandProperty Path
                Remove-Item -Path $CHEMIN
            }
        }
    }


}

function PartDisk() {

    Get-Disk
    $diskbddad = Read-Host "selectionner le numéro de disque de la BDD"
    Initialize-Disk -Number $diskbddad
    New-Partition -DiskNumber $diskbddad -DriveLetter B -Size 4GB
    Format-Volume -DriveLetter B -FileSystem NTFS -Confirm:$false -NewFileSystemLabel "BDD"
    Get-volume | Format-Table
    Get-Disk | Format-Table


    $disklogsad = Read-Host "selectionner le numéro de disque des logs"
    Initialize-Disk -Number $disklogsad
    New-Partition -DiskNumber $disklogsad -DriveLetter L -Size 4GB
    Format-Volume -DriveLetter L -FileSystem NTFS -Confirm:$false -NewFileSystemLabel "LOGS"
    Get-volume | Format-Table
    Get-Disk | Format-Table

    $disksysvolad = Read-Host "selectionner le numéro de disque SYSVOL"
    Initialize-Disk -Number $disksysvolad
    New-Partition -DiskNumber $disksysvolad -DriveLetter S -Size 4GB
    Format-Volume -DriveLetter S -FileSystem NTFS -Confirm:$false -NewFileSystemLabel "SYSVOL"
    Get-volume | Format-Table
    Get-Disk | Format-Table
}

function installadds() {


    $domaineNameVar = Read-Host "Saisir le nom du domaine sans l'extension"
    $extensionDomain = Read-Host "Saisir l'extension du domaine sans le point"

    $netbiosname = ($domaineNameVar).ToUpper()
    $domainenamecp = $domaineNameVar + "." + $extensionDomain
    Add-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -includeAllSubFeature
    Import-Module ADDSDeployement
    $ForestConfiguration = @{
        '-DatabasePath'         = 'B:\BDD';
        '-DomainMode'           = 'Default';
        '-DomainName'           = $domainenamecp;
        '-DomainNetbiosName'    = $netbiosname;
        '-ForestMode'           = 'Default';
        '-InstallDns'           = $true;
        '-LogPath'              = 'L:\LOGS';
        '-NoRebootOnCompletion' = $false;
        '-SysvolPath'           = 'S:\SYSVOL';
        '-Force'                = $true;
        '-CreateDnsDelegation'  = $false 
    }
    Install-ADDSforest @$ForestConfiguration   
}


function Startmenu(){
    Clear-Host
    Write-Host
    "************PROJET TSSR************
      ********************************* "


    Write-Host "1:Creer une machine Virtuelle"

    #Write-Host "2:Creation SRV-GUI"
    Write-Host "Q:Quittez le script"
    $choix = Read-Host "Que souhaitez-vous faire ?"
    switch ($choix) {
        1 {menu}
        Q {exit}
        default { Startmenu }

    }
}


function menu() {
    #Clear-Host
    Write-Host
    "************PROJET TSSR************
      ********************************* "


 
    Write-Host "1:Creation SRV-CORE"
    Write-Host "2:Creation SRV-GUI"
    Write-Host "3:Win10Client"
    Write-Host "4:Création Disques"
    Write-Host "5:Supression Disques"
    Write-Host "6:Creation ADDS"
    Write-Host "7:Gérer les disques"
    Write-Host "8:Dns Config"
    Write-Host "9:Jonction du domaine"

    Write-Host "Q:retour"


    $choix = Read-Host "Que souhaitez-vous faire ?"
    switch ($choix) {
        1 { win19core;Pause;menu }
        2 { Win19Ggui;Pause;menu }
        3 { Win10;Pause;menu }
        4 { CreationDisks;Pause;menu }
        5 { RemoveDisks;Pause;menu }
        6 { installadds;Pause;menu }
        7 { PartDisk;Pause;menu }
        8 { domainjoin;Pause;menu }
        9 { dnsappli;Pause;menu }
        Q { exit }
        default { menu }
    }
}
Startmenu