function Pause($message="Appuyer sur une touche pour continuer")
{ 
 Write-Host -noNewline $message
 $null = $host.UI.rawUI.ReadKey("Noecho,includeKeydown")
}


function initialize(){
    
    $test = Get-Disk
    $diskNumber = Read-Host "Sélectionner un disque: "
    Clear-Disk -Number $diskNumber -Confirm
    Initialize-Disk $diskNumber
    Set-Disk -Number $diskNumber -IsOffline $false
    Write-Host "The disk",$diskNumber,"has been initialized."
}

function partition(){
    $diskNumber = Read-Host "Sélectionner un disque: "
    $letter = Read-Host "Entrez la lettre que vous voulez lui attribuer: "
    New-Partition -DiskNumber  $diskNumber -usemaximumsize -DriveLetter $letter | Format-Volume -filesystem NTFS -NewFileSystemLabel LUN `
    | Get-Partition -DiskNumber $diskNumber
    
    Write-Host (Get-Disk -Number 1).friendlyname "has been partitioned."
}

function createLun(){
    #installer role iscsi
    #create new virtual disk
    Install-WindowsFeature -Name FS-iSCSITarget-Server -IncludeAllSubFeature -IncludeManagementTools

}

function menu(){
    Write-Host "1: Initialiser un disque."
    Write-Host "2: Paritionner un disque."
    Write-Host "3: Creation LUN  ISCSI."
    Write-Host "4: Quatrieme item ?"
    Write-Host "Q: Quitter."

    $ch = Read-Host "Votre choix: "
    switch($ch){
        1 {initialize;Pause;menu}
        2 {partition;Pause;menu}
        3 {createLun;Pause;menu}
        4 {;Pause;menu}
        Q {exit}
        default {menu}
    }
}

menu
