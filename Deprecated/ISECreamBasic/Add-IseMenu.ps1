function Add-IseMenu {
    <#
    .Synopsis
        Helper function to add menus to the ISE
    .Description
        Makes adding menus to the Windows PowerShell Integrated Scripting Environment (ISE)
        easier.  Add-IseMenu accepts a hashtable of menus.  
        Each key is the name of the menu.
            Keys are automatically alphabetized, unless the 
        Each value can be one of three things:
            - A Script Block
                Selecting the menu item will run the script block
            - A Hashtable
                The value will be used to create a nested menu
            - A Script Block with a note property of ShortcutKey
                Selecting the menu item will run the script block.
                The ShortcutKey will be used to assign a shortcut key to the item
    .Example
        Add-IseMenu -Name "Get" @{
            "Process" = { Get-Process } 
            "Service" = { Get-Service } 
            "Hotfix" = {Get-Hotfix}
        }
    .Example
        Add-IseMenu -Name "Verb" @{
            Get = @{
                Process = { Get-Process }
                Service = { Get-Service } 
                Hotfix = { Get-Hotfix } 
            }
            Import = @{
                Module = { Import-Module } 
            }
        }
    .Example
        Add-IseMenu -Name "Favorites" @{
            "Edit Profile" = { psedit $profile } | 
                Add-Member NoteProperty ShortcutKey "CTRL + E" -PassThru
        }
    #>
    param(
        #The name of the menu to create 
        [Parameter(Mandatory=$true)]
        [String]$Name,
        # The contents of the menu
        [Parameter(Mandatory=$true)]
        [Hashtable]$Menu,
        # The root of the menu.  This is used automatically by Add-IseMenu when it 
        # creates nested menus.
        $Root,
        $tabindex,
        $Module = $null,
        # If PassThru is set, the menu items will be outputted to the pipeline
        [switch]$PassThru,
        # If Merge is set, menu items will be merged with existing menus rather than
        # recreating the entire menu.
        [switch]$Merge,
        # 
        [switch]$showEmptyMenu        
    )
    
    # todo fix Function comment
    # todo embed/remove examples from bottom
    
    Set-StrictMode -Off
    if (-not $psise) { return }
    if (-not $root) {
        # the addon menus of the other tabs can be modified too
        if ($tabindex)
        {
        $root = $psise.PowerShellTabs[$tabindex].AddOnsMenu
        }
        else
        {
        $root = $psise.CurrentPowerShellTab.AddOnsMenu
        }
    }
    if (-not $root) { # for CTP 3 only. Remove in future 
        $root = $psise.CustomMenu
    }
    $iseMenu = $root.Submenus | Where-Object {
        $_.DisplayName -eq $name
    }
    if (-not $iseMenu) {
        $iseMenu = $root.Submenus.Add($name, $null, $null)
    }
    if (-not $merge) {
        $iseMenu.Submenus.Clear()
    }

    $sorted = @{}
    $menu.keys | % {
        # Items with positive order go first, than items with no order and finally those with negative order 
        $order = ($menu[$_]).order
        If ([int]$order -lt 0 ) { $order = 1000 + $order }
        If ($order -eq $null) { $order = 500 }
        $order = "{0,3}{1}" -f $order, $_
        $sorted[$order] = $_ , ($menu[$_]).ShortcutKey, $menu[$_] # name, shortcut, menu  
        }
    $sorted.GetEnumerator()   | 
        Sort-Object Key | 
        ForEach-Object {
            $itemname, $ShortcutKey, $value = $_.Value
            switch ($value) {
                { $_ -is [Hashtable] } {
                    if ($showEmptyMenu -or ($value.keys.count -gt 0)) {
                        $subMenu = $iseMenu.SubMenus.Add($itemName, $null, $null)
                        Add-IseMenu $itemName $value -root $iseMenu -Module $module -passThru:$passThru -showEmptyMenu:$showEmptyMenu
                    }
                }
                { $ShortcutKey } {
                    if ($module)
                    {
                        $text = "`$m = gmo $module; & `$m " + $_ 
                    }
                    else
                    {
                        $text = $_
                    }
                    $scriptBlock= [ScriptBlock]::Create($text)
                    try {
                        $m = $iseMenu.Submenus.Add($itemName, $scriptBlock, $_.ShortcutKey)
                        }
                    catch    
                        {
                        Write-Host "Shortcut $($_.ShortcutKey) already in use. Menu item created without shortcut"
                        $m = $iseMenu.Submenus.Add($itemName, $scriptBlock, $null)
                        }
                    if ($passThru) { $m }
                }
                default {
                    if ($module)
                    {
                        $text = "`$m = gmo $module; & `$m " + $_ 
                    }
                    else
                    {
                        $text = $_
                    }
                    #$module
                    #$context
                    #$text
                    $scriptBlock= [ScriptBlock]::Create($text)
                    $m= $iseMenu.Submenus.Add($itemName, $scriptBlock, $null)
                    if ($passThru) { $m }
                }                 
            }
        }
}

<#
Add-IseMenu -Name "Get"  @{
    "Process" = { Get-Process } 
    "Service" = { Get-Service } 
    "Hotfix" = {Get-Hotfix}
}

Add-IseMenu -Name "Get1" -module SQLIse @{
    "Process" = { Get-Process } 
    "Service" = { Get-Service } 
    "Hotfix" = {Get-Hotfix}
}

Add-IseMenu -Name "Get2" @{
    "Process" = { Get-Process } | Add-Member NoteProperty order  2 -PassThru
    "Service" = { Get-Service } | Add-Member NoteProperty order  1 -PassThru
    "Hotfix" = {Get-Hotfix}     | Add-Member NoteProperty order  3 -PassThru | Add-Member NoteProperty ShortcutKey "CTRL + ALT+B" -PassThru
}


Add-IseMenu -Name "Verb"  @{
    Get = @{
        Process = { Get-Process } | Add-Member NoteProperty order  2 -PassThru
        Service = { Get-Service } | Add-Member NoteProperty order  1 -PassThru
        Hotfix = { Get-Hotfix }   | Add-Member NoteProperty order  3 -PassThru | Add-Member NoteProperty ShortcutKey "CTRL + ALT+B" -PassThru
    } | Add-Member NoteProperty order  2 -PassThru
    Import = @{
        Module = { Import-Module } 
    } | Add-Member NoteProperty order  1 -PassThru
}

Add-IseMenu -Name "Verb2"  @{
    Get = @{
        Process = @{} | Add-Member NoteProperty order  2 -PassThru
        Service = { Get-Service } | Add-Member NoteProperty order  1 -PassThru
        Hotfix = { Get-Hotfix }   | Add-Member NoteProperty order  3 -PassThru | Add-Member NoteProperty ShortcutKey "CTRL + ALT+B" -PassThru
    } | Add-Member NoteProperty order  2 -PassThru
    Import = @{
        Module = { Import-Module } 
    } | Add-Member NoteProperty order  1 -PassThru
}
#>


