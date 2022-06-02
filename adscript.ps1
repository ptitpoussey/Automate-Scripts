function Pause($message="Appuyer sur une touche pour continuer")
{ 
    Write-Host -noNewline $message
    $null = $host.UI.rawUI.ReadKey("Noecho,includeKeydown")
}



function displayOu(){
    Clear-Host
    Write-Host "Affichage liste OU"
    Write-Host "_________________________________________________________________"
    Get-ADOrganizationalUnit -Filter * -Properties CanonicalName | Select-Object -Property CanonicalName
    Write-Host "_________________________________________________________________"
}


function ou_exist{
    $chemin=(get-addomain).distinguishedname
    $ouname = Read-Host "Sasisir le nom de votre OU: "
    $fullpath= "OU="+$ouname+","+$chemin
    $userpath = "OU=UTILISATEURS,"+$fullpath
    $grouppath = "OU=GROUPES,"+$fullpath
    $utilspath = "OU=UTILISATEURS,"+$fullpath
    $file = import-csv -path "./liste.csv" -Delimiter ";" -Encoding UTF8
    
    
    function isOuExist($path){
        Try{
            if (Get-ADOrganizationalUnit -Identity $path){
                return $True
            }
        }
        Catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
                Write-Output ("L'OU n'existe pas.")
                return $False | out-null
        }
    }

    function getMembers(){
        $ch = Read-Host "Voulez-vous afficher tous les membres d'une UO(*1) ou d'un groupe(*2) ? (1 | 2)"

        switch($ch){
            1 {
                Clear-Host
                displayOu
                $uo = Read-Host "Saisir le nom de l'UO: "
                $temp = "OU="+$uo+","+$chemin
                $ok = isOuExist($temp)
                if ($ok -eq $true){
                    Write-Host "Tous les membres de "$uo " sont :"
                    Get-ADUser -Filter * -SearchBase $fullpath | Select-Object DistinguishedName,Name,UserPrincipalName
                }
                else{
                    isOuExist($temp)
                }
            }
            2 {
                try{
                    Clear-Host
                    $group = Read-Host "Saisir le nom du groupe: "
                    Get-ADGroupMember -Identity $group | Select-Object Name | ft
                    $going = $False
                }
                catch{
                    Write-Host $group "n'existe pas."
                }
            }
            default { Write-Host "Choix incorrecte"; getMembers }
        }
    }

    function createSousOu(){
        New-ADOrganizationalUnit -Name GROUPES -Path $fullpath -verbose -ProtectedFromAccidentalDeletion $false
        New-ADOrganizationalUnit -Name IMPRIMANTES -Path $fullpath -verbose -ProtectedFromAccidentalDeletion $false
        New-ADOrganizationalUnit -Name ORDINATEURS -Path $fullpath -verbose -ProtectedFromAccidentalDeletion $false
        New-ADOrganizationalUnit -Name SERVEURS -Path $fullpath -verbose -ProtectedFromAccidentalDeletion $false
        New-ADOrganizationalUnit -Name UTILISATEURS -Path $fullpath -verbose -ProtectedFromAccidentalDeletion $false
        foreach ($ligne in $file){
            $service = $ligne.service.toUpper()
            try {
                New-ADOrganizationalUnit -Name $service -Path $utilspath -Verbose -ProtectedFromAccidentalDeletion $false
            }
            catch { Write-Host "Something went wrong..." }
        }
    }

    function permissions()
    {
        $cheminservices="\\SRV-CORE\partage\services\*"
        $cheminperso="\\srv-CORE\partage\perso\*"
 
        $listedossierservice=Get-ChildItem -Path $cheminservices -Directory
        $listedossierperso=Get-ChildItem -Path $cheminperso -Directory
 
        ###################### DOSSIER SERVICE ################################
 
        Foreach ($dossier in $listedossierservice)
        {
            $chemin=$dossier.fullname                          ###fullname nom de fichier chemin absolu 
            $acl=(Get-Item $chemin).GetAccessControl('Access') ###va chercher les acl de chaque dossier
            $gdl="GDL_"+$dossier.name+"_RW"                   ###name juste le nom du fichier ###ar access rule
            $ar=New-Object security.accesscontrol.filesystemaccessrule($gdl,'ReadAndExecute,Write','ContainerInherit,ObjectInherit','none','Allow') ###ar access rule
            $acl.SetAccessRule($ar)  ### applique les access
            Set-Acl -Path $chemin -AclObject $acl -Verbose ### enregistre les acl
        }
 
        ###################### DOSSIER PERSO #########################################
 
        Foreach ($dossier in $listedossierperso)
        {
            $chemin=$dossier.fullname                           
            $acl=(Get-Item $chemin).GetAccessControl('Access')
            $nomuser=$dossier.name          
            $ar=New-Object security.accesscontrol.filesystemaccessrule($nomuser,'Modify','ContainerInherit,ObjectInherit','none','Allow')
            $acl.SetAccessRule($ar)  
            Set-Acl -Path $chemin -AclObject $acl -Verbose
        }
 
    }
    function createGroups()
    {
        New-ADGroup -GroupCategory Security -GroupScope Global -Name GG_TOUS -Path $grouppath -Verbose
        New-ADGroup -GroupCategory Security -GroupScope Global -Name GG_PERMANENT -Path $grouppath -Verbose
        New-ADGroup -GroupCategory Security -GroupScope Global -Name GG_TEMPORAIRE -Path $grouppath -Verbose
   
        New-ADGroup -GroupCategory Security -GroupScope DomainLocal -Name GDL_TOUS_R -Path $grouppath -Verbose
        New-ADGroup -GroupCategory Security -GroupScope DomainLocal -Name GDL_TOUS_RW -Path $grouppath -Verbose
        New-ADGroup -GroupCategory Security -GroupScope DomainLocal -Name GDL_TOUS_M -Path $grouppath -Verbose
 
        New-ADGroup -GroupCategory Security -GroupScope DomainLocal -Name GDL_TEMPORAIRE_R -Path $grouppath -Verbose
        New-ADGroup -GroupCategory Security -GroupScope DomainLocal -Name GDL_TEMPORAIRE_RW -Path $grouppath -Verbose
 
        New-ADGroup -GroupCategory Security -GroupScope DomainLocal -Name GDL_PERMANENT_R -Path $grouppath -Verbose
        New-ADGroup -GroupCategory Security -GroupScope DomainLocal -Name GDL_PERMANENT_RW -Path $grouppath -Verbose
    
 
        foreach ($ligne in $file)
        {
            $service = $ligne.service.toUpper()
            $GG="GG_"+$service
            $GU="GU_"+$service
            $GDL_R="GDL_"+$service+"_R"
            $GDL_RW="GDL_"+$service+"_RW"
            $GDL_M="GDL_"+$service+"_M"
            $GDL_F="GDL_"+$service+"_F"
            try {
               New-ADGroup -GroupCategory Security -GroupScope Global -Name $GG -Path $grouppath -Verbose
            }
            catch{}
            try {
               New-ADGroup -GroupCategory Security -GroupScope Universal -Name $GU -Path $grouppath -Verbose
            }
            catch{}
            try {
               New-ADGroup -GroupCategory Security -GroupScope Domainlocal -Name $GDL_R -Path $grouppath -Verbose
            }
            catch{}
            try {
               New-ADGroup -GroupCategory Security -GroupScope Domainlocal -Name $GDL_RW -Path $grouppath -Verbose
            }
            catch{}
            try {
               New-ADGroup -GroupCategory Security -GroupScope Domainlocal -Name $GDL_M -Path $grouppath -Verbose
            }
            catch{}
            try {
               New-ADGroup -GroupCategory Security -GroupScope Domainlocal -Name $GDL_F -Path $grouppath -Verbose
            }catch{}
            Add-ADGroupMember $GU -Members -verbose $GG
            Add-ADGroupMember $GDL_R -Members $GU -Verbose
            Add-ADGroupMember $GDL_RW -Members $GU -Verbose
            Add-ADGroupMember $GDL_M -Members $GU -Verbose
            Add-ADGroupMember $GDL_F -Members $GU -Verbose
             
            Add-ADGroupMember GG_TOUS -Members $GG -Verbose
            Add-ADGroupMember GG_PERMANENT -Members $GG -Verbose
            Add-ADGroupMember GG_TEMPORAIRE -Members $GG -Verbose
        }
 
        Add-ADGroupMember GDL_TOUS_R -Members GG_TOUS -Verbose
        Add-ADGroupMember GDL_TOUS_RW -Members GG_TOUS -Verbose
        Add-ADGroupMember GDL_TOUS_M -Members GG_TOUS -Verbose
 
        Add-ADGroupMember GDL_PERMANENT_R -Members GG_PERMANENT -Verbose
        Add-ADGroupMember GDL_PERMANENT_RW -Members GG_PERMANENT -Verbose
 
        Add-ADGroupMember GDL_TEMPORAIRE_R -Members GG_TEMPORAIRE -Verbose
        Add-ADGroupMember GDL_TEMPORAIRE_RW -Members GG_TEMPORAIRE -Verbose
 
        Add-ADGroupMember GG_TOUS -Members GG_PERMANENT -Verbose
        Add-ADGroupMember GG_TOUS -Members GG_PERMANENT -Verbose            
    }

    function createFolders(){
        $servicesPath = "\\SRV-CORE\partage\services\"
        $persoPath = "\\SRV-CORE\partage\perso\"

        $testPath = $servicesPath+$service
        $existe=Test-Path $testPath

        if (!$existe){
            New-Item -ItemType Directory -Name $service -Path $servicesPath
        }
        New-Item -ItemType Directory -Name $sam -Path $persoPath
    }

    function createUsers(){
        $password=ConvertTo-SecureString("Form@tion2020") -AsPlainText -Force
        foreach ($ligne in $file){
            $name=$ligne.prenom.substring(0,1).ToUpper()+$ligne.prenom.substring(1).ToLower()
            $firstName=$ligne.nom.ToUpper()
            $fullname=$name+" "+$firstName
            $sam=$name.ToLower()+"."+$firstName.ToLower()
            $upn=$sam+"@"+$env:USERDNSDOMAIN.ToLower()
            $function=$ligne.fonction.substring(0,1).ToUpper()+$ligne.prenom.substring(1).ToLower()
            $service=$ligne.service.ToUpper()
            $description=$ligne.description
            $mail=$upn
            $userpath="OU="+$service+","+$utilspath
            $group="GG_"+$service

            New-ADUser -GivenName $name -Surname $firstName -Name $fullname -DisplayName $fullname -SamAccountName $sam -UserPrincipalName $upn -Title $function -Department $service -Description $description -EmailAddress $mail -Path $userpath -AccountPassword $password -ChangePasswordAtLogon $true -Enabled $true -Verbose
            Add-ADGroupMember $group -Members $sam
            createFolders($service,$sam)
        }
    }
    

    function removeOu(){
        displayOu
        $path = Read-Host "Saisir l'OU a supprimé: "
        $tempPath = "OU="+$path+","+$chemin
        $ok = isOuExist($tempPath)
        if ($ok -eq $True){
            Set-ADOrganizationalUnit -Identity $tempPath -ProtectedFromAccidentalDeletion $false
            Remove-ADOrganizationalUnit -Identity $tempPath
            Write-Host $path "has been successfully deleted."
        } #delete les childs 
        else{
            isOuExist($tempPath)
        }
    }

    function removeGroup(){
        Clear-Host
        Get-ADGroup -Filter * | Select-Object Name ,distinguishedname | ft
        $group_to_delete = Read-Host "Entrez le nom du groupe à supprimer."

    }

    function auto(){
        createSousOu
        createGroups
        createUsers
    }

    function admenu(){
        Clear-Host
        Write-Host "1: Affichage des OU. <-- Fait"
        Write-Host "2: Ajout d'UO en lots. <-- Fait"
        Write-Host "3: Creation groupes (GG GU GDL). <-- Fait"
        Write-Host "4: Affiche les membres d'un groupe / d'une OU. <-- Fait"
        Write-Host "5: Creation users en lots.(Fichier CSV)"
        Write-Host "6: Permissions."
        Write-Host "7: Supprimer une UO ou un Groupe. <-- Fait"
        Write-Host "8: Création auto"
        Write-Host "9: Retour en arrière."
        Write-Host "10: Retour en arrière."
        Write-Host "Q: Quitter"
        $choix = Read-Host "Saisir votre choix: "
        switch ($choix){
            1 {displayOu;Pause;admenu}
            2 {createSousOu;Pause;admenu}
            3 {createGroups;Pause;admenu}
            4 {getMembers;Pause;admenu}
            5 {createUsers;Pause;admenu}
            6 {;Pause;admenu}
            7 {
                Clear-Host
                $ch = Read-Host "Voulez-vous supprimer une OU(*1) ou un Groupe(*2)"
                switch ($ch){
                    1 {removeOu;Pause;admenu}
                    2 {removeGroup;Pause;admenu}
                    default {"flemme de gérer l'exception"}
                }                
               ;Pause;admenu}
            8 {auto;Pause;admenu}
            9 {permissions;Pause;admenu}
            10 {menu}
            Q {exit}
            default {admenu}
        }
    }
    $ok = isOuExist($fullpath)
    if ($ok -eq $true){
        admenu
    }
    else{
        isOuExist($fullpath)
    }
}

function ou_not_exist(){ 
    $chemin=(get-addomain).distinguishedname
    $ou = Read-Host "Saisir le nom de votre OU: "
    $fullpath = "OU="+$ou+","+$chemin
    New-ADOrganizationalUnit -Name $ou -Path $chemin -verbose
    Set-ADOrganizationalUnit -Identity $fullpath -ProtectedFromAccidentalDeletion $false
    Write-Host $ou "has been successfully created."
}




function menu(){
    Write-Host "1: OU existante"
    Write-Host "2: Lister les OU existantes"
    Write-Host "3: OU non existante (création d'OU)"
    Write-Host "Q: Quitter."
    $choix = Read-Host "Votre Choix ?: "
    switch($choix){
        1 {ou_exist;menu}
        2 {displayOu;menu}
        3 {ou_not_exist;menu}
        Q {exit}
        default {menu}
    }
}

menu