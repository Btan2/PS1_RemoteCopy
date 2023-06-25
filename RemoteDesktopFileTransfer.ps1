#
# Check if string is an Exit/Quit command
function QuitStr{
    param(
        [Parameter (Mandatory = $true)][String]$InputStr
    )

    $str = $InputStr.toUpper()
    if($str.Length -lt 1){
     return $false
    }
    return $str -eq "Q" -Or $inp -eq "QUIT" -Or $str -eq "RETURN" -Or $str -eq "EXIT" -Or $str -eq "BACK"
}

#
# Set File Extension
function FilterByFileType{   
    Write-Host "----------------------------------------"
    Write-Host "       File Extension Filter   "
    Write-Host ""

    while(-1){
        Write-Host ""
        Write-Host "Specify which file types are available during file copying procedures."
        Write-Host "File extension must contain '.' symbol before extension type"
        Write-Host "Can include multiple types by seperating each extension by spaces"
        Write-Host "   e.g. '.txt .jpg .xslx'"
        Write-Host ""
        Write-Host "To show all file types, press Enter with no input."    
        Write-Host ""

        #$fe = @("*.txt", "*.xlsx", "*.png", "*.jpg", "*.tif")

        $inp = Read-Host "Enter file extension"

        if($inp.Length -ge 1){
            if(QuitStr -InputStr $inp){
                $fe = @("*")
                break;
            }
            else{
                $fe = @()

                foreach($fx in $inp.Split(" ")){
                    if($fx.Contains("*")){
                    }
                    elseif($fx.StartsWith(".")){
                        $fe += "*$fx"
                    }
                }

                if($fe.Length -ge 1){
                    break;
                }
            }
            
        }
        else{
            $fe = @("*")
            break;
        }
    }

    Write-Host ""
    Write-Host "Search Filter: $fe"
    Write-Host ""
    return $fe
}

#
# Set Search Pathing (turn recursion on/off)
function SetSearchPath{
    param(
        [Parameter (Mandatory = $true)][Boolean]$currentValue
    )
    Write-Host ""
    Write-Host "----------------------------------------"
    Write-Host "         Search Path Settings"
    Write-Host ""
    Write-Host ""

    while(-1){
        Write-Host "Recursion  ON; Search all sub-folders --------------------------- [ 1 ]"
        Write-Host "Recursion OFF; Only search current folder ----------------------- [ 2 ]"
        Write-Host ""
        Write-Host "Return ---------------------------------------------------------- [ 3 ]"
        Write-Host ""
        $inp = Read-Host " Enter option 1-3"
        Write-Host ""
        
        if($inp.Length -ge 1){
            if(QuitStr -InputStr $inp){
                Write-Host ""        
                return $currentValue
            }
        }
                
        switch($inp -as [int]){
            1 { 
                Write-Host "Recursive Search: $true"
                Write-Host ""        
                Write-Host ""        
                return $true 
              }
            2 { 
                Write-Host "Recursive Search: $false"
                Write-Host ""        
                Write-Host ""                        
                return $false
              }
            3 {
                Write-Host "Recursive Search: $currentValue"
                Write-Host ""        
                Write-Host ""        
                return $currentValue
              }

            default {}
        }
    }
}

#
# Copy File Menu
function CopyFiles{
    param(
        [Parameter (Mandatory = $true)][Boolean]$Recursive,
        [Parameter (Mandatory = $true)]$Include
    )

    Write-Host ""
    Write-Host "-----------------------------------"
    Write-Host "   COPY FILES TO REMOTE DESKTOP"
    Write-Host ""
    Write-Host ""

    # Get Remote Desktop Connection
    [ValidateScript({ Test-Connection -ComputerName $_ -Quiet -Count 1 })]
    [ValidateNotNullOrEmpty()]
    [string[]]$ComputerName = $env:COMPUTERNAME

    $username = ""
    $pcName = ""
    foreach ($comp in $ComputerName) {
        $output = (Get-WmiObject -Class win32_computersystem -ComputerName $comp).UserName
        $pcName = $output.Split("\")[0]
        $username = $output.Split("\")[1]
    }

    while(-1){   
        Write-Host "Remote Desktop: $pcName"     
        Write-Host "User: $username"
        Write-Host ""
        Write-Host "Copy Directory: $scriptPath\" 
        Write-Host ""
        Write-Host "Recursive Search: $Recursive"
        Write-Host "File Extension(s): $Include"
        Write-Host ""

        # Get list of files according to $Extension Include array
        $fileList = ""
        if($Recursive -eq $true){
            $fileList = Get-ChildItem -Path $scriptPath\ -Include $Include -Recurse | Select-Object FullName
        }
        else{
            $fileList = Get-ChildItem -Path $scriptPath\* -Include $Include | Select-Object FullName
        }
        
        # Print file list, last names only
        $fCount = 0;
        foreach($f in $fileList){
            $fCount += 1;
            Write-Host "[$fCount]" --- $f.FullName.Split("\")[-1]
        }

        if($fCount -eq 0){      
            Write-Host "+----------------+"    
            Write-Host "| NO FILES FOUND |"
            Write-Host "+----------------+"
            Write-Host ""            
            Read-Host "Press enter to continue"
            return
        }

        Write-Host ""
        Write-Host "[q] --- Return"
        Write-Host ""
        $inp = Read-Host " Enter file number 1 -> $fCount"
        Write-Host ""
        
        if($inp.Length -ge 1){
            if(QuitStr -InputStr $inp){
                Write-Host ""        
                return
            }
        }

        # User input selects which file to copy 
        if($inp -as [int]){
            $inpNUMBER = $inp -as [int]

            if(($inpNUMBER -le $fCount)){
                $copyFile = $fileList[$inpNUMBER-1].FullName

                $destination = "C:\users\$username\Desktop\"

                Write-Host "FILE: $copyFile"
                Write-Host "DESTINATION: $destination"        
                Write-Host ""
            
                # Confirm and copy to $destination
                $inpConfirm = Read-Host " Confirm copy FILE to DESTINATION? (y/n)"
                $inpConfirm= $inpConfirm.ToString().ToUpper()  
                if($inpConfirm -eq "Y" -Or $inpConfirm -eq "YES"){
                    Write-Host "Sending FILE --> DESTINATION"
                    Copy-Item -Path $copyFile -Destination $destination
                    Write-Host "..."
                    write-Host "FILE sent"
                    Write-Host ""
                    return
                }
            }
        }
    }   

}

#
# Copy File Menu
function Get-CopyFileMenu{
    $include = @("*")
    $recursive = $false;

    while(-1){
        Write-Host "----------------------------------------"
        Write-Host "                 MENU    "
        Write-Host ""        
        Write-Host ""
        Write-Host "Copy files ------------------------ [ 1 ]"
        Write-Host "Search Filters -------------------- [ 2 ]"
        Write-Host "Search Path Settings -------------- [ 3 ]"        
        Write-Host ""
        Write-Host "END ------------------------------- [ 4 ]"
        Write-Host ""

        $inp = Read-Host " Select Menu option 1 -> 4"
        Write-Host ""

        if($inp.Length -ge 1){
            if(QuitStr -InputStr $inp){
                return
            }
        }
        
        if($inp -as [int]){
            switch($inp -as [int]){
                1 { CopyFiles -Recursive $recursive -Include $include }
                2 { $include = FilterByFileType }
                3 { $recursive = SetSearchPath -currentValue $recursive }
                4 { return }
                default { -1 }
            }
        }
        
    } 

}

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
cd $scriptPath

Write-Host ""
Write-Host "----------------------------------------"
Write-Host "    POWERSHELL REMOTE FILE TRANSFER  "
Write-Host "----------------------------------------"

Get-CopyFileMenu




#Write-Host "Copying File..."
#Copy-Item -Path TEST_COPY1.txt -Destination C:\users\Moobly\Desktop\
#write-Host "FILE COPIED"

#Write-Host "Copying Multiple Files..."
#Copy-Item -Path C:\WORK\TEST_COPY1.txt, C:\WORK\TEST_COPY2.txt -Destination C:\users\Moobly\Desktop\
#write-Host "MULTIPLE FILES COPIED"

#Write-Host "Copying Folder (FULL)..."
#Copy-Item -Recurse -Path \TEST_FOLDER\ -Destination C:\Users\Moobly\Desktop\TEST_FOLDER
#write-Host "FOLDER & FILES COPIED"

# Copy multiple items
# Copy-Item -Path C:\WORK\copy_file1.txt,C:\WORK\copy_file2.txt -Destination C:\users\Moobly\Desktop\


#function Get-RemoteConnection{
#   $MYSESSION = New-PSSession -ComputerName PC02.TECH.LOCAL
#
#   ##Copy-Item -Path "C:\test.txt" -Destination "C:\" -ToSession $MYSESSION
#}

#function Get-CopyFolder{
#    Write-Host ""
#    Write-Host "[ COPY FILES ]"
#    Write-Host ""
#    Write-Host "DIRECTORY: ${scriptPath}"
#    Write-Host ""
#}
