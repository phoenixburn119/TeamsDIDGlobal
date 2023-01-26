$Global:Username = $null
$Global:UserNameEmail = $null

function Write-Log {
    Param(
        $Message,$Path = ".\Logs\Audit-Log $($env:username) $((get-date).ToString("MM-dd-yyyy")).txt"
    )

    function TS {Get-Date -Format 'hh:mm:ss'}
    "[$(TS)]$Message" | Tee-Object -FilePath $Path -Append | Write-Verbose
}
Function MenuCreate {
    #Creates a main menu that detects userID's existance and also displays it. 
    Write-Host "Please select an option..." -ForeGroundColor Yellow
    if ($Global:UserName) {
        Write-Host "Selected User: $Global:UserName"
        Write-Host "    -->Email: $Global:UserNameEmail"
    }
    Write-Host "1: Select a user."
    Write-Host "2: Check status of number."
    If($Global:Username) {
        Write-Host ""
        Write-Host "3: <Standard> Assign Number to user."
        Write-Host "4: Lookup selected users Teams info."
        Write-Host "9: Check/Reconnect to MicrosoftTeams."
        Write-Host "Q: Press 'Q' to quit."
        # Write-Host "Technical Contact: USERNAME/EMAIL"
    }
}
Function MicrosoftTeamsConnect {
    Write-Host "Checking connection to MicrosoftTeams..." -BackgroundColor DarkGray
    Try{
        # Enter test email to verify connection to Teams. REQUIRED
        Get-CsOnlineUser -Identity Account@domain.com | Out-null
        Write-Host "Thanks for connecting to MicrosoftTeams prior ;)"
    } Catch{
        Write-Warning "Connecting to MicrosoftTeams...Please follow the popup"
        Connect-MicrosoftTeams
    }
    Pause
}
Function ModuleChecker {
    Write-Host "        Module Checker Initiated        " -ForegroundColor DarkBlue -BackgroundColor White
    Write-Log "$($env:username) initiated DIDGlobalAssignment startup."
    # Checks if the .\Logs folder exists in current directory so logs can be created.
    Try{
        If(Test-Path -Path .\Logs ) {
            Write-Host "Logs Directory....Passed" -ForegroundColor Green
        } Else {
            mkdir .\Logs
        }
    } Catch {
        Write-Host "FAIL: Logs Directory Creation Failed" -ForegroundColor Red
        Start-Sleep -Seconds 5
        Exit
    }
    #Checks if the required modules are installed.
    Write-Host "    Checking for required module...    " -BackgroundColor DarkGray
    If ((Get-InstalledModule -Name MicrosoftTeams).Name -eq "MicrosoftTeams") { #Checks for the install of MicrosoftTeams
        Write-Host "MicrosoftTeams...Passed" -ForegroundColor Green
    }
    Else {
        Write-Warning "Please run the following command in elevated powershell:"
        Write-Host "Install-Module MicrosoftTeams"
        Pause
        Exit
    }
    MicrosoftTeamsConnect
    Write-Log "$($env:username) has finished the DIDGlobalAssignment startup procedure."
    Start-Sleep -seconds 1
}
Function GetUserInfo {
    Try {
        $StoredInfo = Get-CsOnlineUser -Identity $Global:UserNameEmail
        Write-Host "User info listed below" -ForeGroundColor Green
        $StoredInfo | Format-List DisplayName,SipAddress,LineURI,OnPremLineURI,EnterpriseVoiceEnabled,HostedVoicemail,OnlineVoiceRoutingPolicy
    }Catch {
        Write-Error $_
        Write-Log "FAILED: $_"
    }
    Pause
}
Function UserSelect {
    # Receives user input for username and domain and tests if they exist.
    $Global:UserName = Read-Host -Prompt "Enter users username (first.last)"
    do {
        Write-Host '1: Domain1'
        Write-Host '2: Domain2'
        Write-Host '3: Domain3'
        write-host -nonewline "Select the users domain: "
        $choice = read-host
        $ok = $choice -match '^[123]+$'
        if ( -not $ok) { write-host "Invalid selection" }
    } until ( $ok )
    switch -Regex ( $choice ) {
        "1"{$Domain = "Domain1"}
        "2"{$Domain = "Domain2"}
        "3"{$Domain = "Domain3"}
    }
    $Global:UserNameEmail = $Global:UserName + "@" + $Domain
    If($null -eq (Get-CsOnlineUser -Identity $Global:UserNameEmail)) {
        Write-Error "User $Global:UserNameEmail not found."
        Write-Log "User $Global:UserNameEmail not found."
        Start-Sleep -s 2
        $Global:UserNameEmail = $null
        $Global:UserName = $null
        Break
    } Else {
        Write-Host "User $Global:UserNameEmail was found." -ForegroundColor Green
        Write-Log "User $Global:UserNameEmail was found."
    }
}
Function GetUserInfo {
    Try {
        $StoredInfo = Get-CsOnlineUser -Identity $Global:UserNameEmail
        Write-Host "User info listed below" -ForeGroundColor Green
        $StoredInfo | Format-List DisplayName,SipAddress,LineURI,OnPremLineURI,EnterpriseVoiceEnabled,HostedVoicemail,OnlineVoiceRoutingPolicy
    }Catch {
        Write-Error $_
    }
    Pause
}
Function NumberAssign {
    MicrosoftTeamsConnect
    $AssignedDID = Read-Host -Prompt "Enter DID Number (This format tel:+19994445555)"
    $NumPull = $AssignedDID
    $NumPull -match "tel:(?<content>.*)"
    $Pull = $matches['content']
    # Attempts to get account associated with user provided number.
    $TryGetDID = get-csonlineuser -Filter "LineURI -eq '$AssignedDID'"
    # Allows you to select the voice routing policy. To add new answers write in Write-Host and Global fields.
    do {
        Write-Host '1: RoutePolicy1'
        Write-Host '2: RoutePolicy2'
        Write-Host '3: RoutePolicy3'
        Write-Host '4: RoutePolicy4'
        Write-Host '5: RoutePolicy5'
        Write-Host '6: RoutePolicy6'
        write-host -nonewline "Type your choice and press Enter: "
        $choice = read-host
        $ok = $choice -match '^[123456]+$'
        if ( -not $ok) { write-host "Invalid selection" }
    } until ( $ok )
    switch -Regex ( $choice ) {
        "1"{$RoutePolicy = "RoutePolicy1"}
        "2"{$RoutePolicy = "RoutePolicy2"}
        "3"{$RoutePolicy = "RoutePolicy3"}
        "4"{$RoutePolicy = "RoutePolicy4"}
        "5"{$RoutePolicy = "RoutePolicy5"}
        "6"{$RoutePolicy = "RoutePolicy6"}
    }
    # Initial start of number/policy setting. Tests if number is taken.
    If($null -eq $TryGetDID) {
        # After test passes the number is assigned
        Try{
            Set-CsPhoneNumberAssignment -Identity $Global:UserNameEmail -PhoneNumber $Pull -PhoneNumberType DirectRouting
            Write-Host "Number was set sucessfully" -ForegroundColor Green
            Write-Log "Number $Pull for $Global:UserNameEmail was assigned."
        }Catch{
            Write-Warning "FAIL: Number $Pull for $Global:UserNameEmail was not assigned. Error: $_" -ForegroundColor Red
            Write-Log "FAIL: Number $Pull for $Global:UserNameEmail was not assigned. Error: $_"
            Pause
            Return
        }
    }
    Else {
        Write-Host "FAIL: Number $Pull for $Global:UserNameEmail was not set, number already belongs to user. Error: $_" -ForegroundColor Red
        Write-Log "FAIL: Number $Pull for $Global:UserNameEmail was not set, number already belongs to user. Error: $_"
        Pause
        Return
    }
    # Grants the voice routing policy.
    Try{
        Grant-CsOnlineVoiceRoutingPolicy -Identity $Global:UserNameEmail -PolicyName $RoutePolicy
        Write-Host "Policy $RoutePolicy was assigned to $Global:UserNameEmail."
        Write-Log "Policy $RoutePolicy was assigned to $Global:UserNameEmail."
        Write-Warning "Five second sleep started..."
        Start-Sleep -second 5
    } Catch{
        Write-Host "FAIL: Policy $RoutePolicy was not assigned. $_" -ForegroundColor Red
        Write-Log "FAIL: Policy $RoutePolicy was not assigned. $_"
    }
    GetUserInfo
}

ModuleChecker
While($true) {
    Clear-Host
    MenuCreate
    $Selection = Read-Host "Please make a selection"
    switch ($Selection) {
        '1' { UserSelect }
        '2' { NumberLookup }
        '3' { NumberAssign }
        '4' { GetUserInfo }
        '9' { MicrosoftTeamsConnect }
        'q' {
            write-Host 'Hope we could help!'
            Disconnect-MicrosoftTeams
            Clear-Host
            Return
        }
    }
}