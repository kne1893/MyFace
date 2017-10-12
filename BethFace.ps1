function Get-BethFace {
    $Beth.Update = $true
}

function Set-BethContinuous {
    $Beth.Update = $true
    $Beth.Instantaneous = $false
}

function Set-BethInstaneous {
    $Beth.Instantaneous = $true
}

function Stop-BethFace {
    $Beth.Running = $false
}

function Set-BethSleep {
    $Beth.Thoughts = @("")
    $Beth.Update = $true
}

function Set-BethAwake {
    $Beth.Thoughts = @("Code","Chocolate","Ryan")
    $Beth.Update = $true
}

function Set-BethTalkToRyan {
    $Beth.RyanTime = [DateTime]::Now
    $Beth.Update = $true
}

# Initialize Beth
$Beth = [hashtable]::Synchronized(@{})
$Beth.Running = $true
$Beth.Host = $host
Write-Host "How many days since Beth has talked to Ryan?"
$timeFromRyan = Read-Host
$Beth.RyanTime = [DateTime]::Now.AddDays(-$timeFromRyan)
Set-BethAwake

# Initialize runspace
$runspace = [runspacefactory]::CreateRunspace()
$runspace.Open()
$runspace.SessionStateProxy.SetVariable('Beth',$Beth)

# Initialize script
$powershell = [powershell]::Create() 
$powershell.Runspace = $runspace

$powershell.AddScript( {
        $FacialExpression = @{ "Elated" = "=D"; "Overjoyed" = ":D"; "Neutral" = ":|";
              "Distressed" = ":-/";  "Sad" = ":("; "Super Sad"  = ":`("; "Surprised" = ":-0" ; "Sleep" =  "(ー。ー) zzz" }
        while($Beth.Running) {
            $Beth | Format-List
            if($Beth.Thoughts.Contains("Ryan")){
                $daysSinceRyan = $([DateTime]::Now - $Beth.RyanTime).Days
                switch ($daysSinceRyan) 
                { 
                    {0..1 -contains $_} { $Beth.Face = "Elated" } 
                    {2..4 -contains $_} { $Beth.Face = "Overjoyed" } 
                    {5..8 -contains $_} { $Beth.Face = "Neutral" } 
                    {9..13 -contains $_} { $Beth.Face = "Distressed" } 
                    {14..19 -contains $_} { $Beth.Face = "Sad" } 
                    {20..26 -contains $_} { $Beth.Face = "Super Sad" } 
                    default { $Beth.Face = "Surprised" }
                }
                
            } else {
                $Beth.Face = "Sleep"
            }
            if($Beth.Update) {
                $Beth.host.ui.WriteVerboseLine("Beth is $($FacialExpression.$($Beth.Face))") 
                if($Beth.Instantaneous) { $Beth.Update = $false }
            }
            Start-Sleep 1
        }
        $Beth.host.UI.WriteVerboseLine("Beth is shutting down")
    })

$handle = $powershell.BeginInvoke()