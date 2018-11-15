<# This form was created using POSHGUI.com  a free online gui designer for PowerShell
.NAME
    PLANNER
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

#region begin GUI{ 

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '993,713'
$Form.text                       = "Form"
$Form.TopMost                    = $false

#TempDB Page
$TabControl = New-object System.Windows.Forms.TabControl
$WavesPage = New-Object System.Windows.Forms.TabPage
$UsersPage = New-Object System.Windows.Forms.TabPage
$UsersWavesPage = New-Object System.Windows.Forms.TabPage

#Tab Control 
$tabControl.Name = "tabControl"
$tabControl.location = New-Object System.Drawing.point(17,102)
$tabControl.Height = 421
$tabControl.Width = 958
$form.Controls.Add($tabControl)

#Waves Page
$WavesPage.DataBindings.DefaultDataSourceUpdateMode = 0
$WavesPage.UseVisualStyleBackColor = $True
$WavesPage.Name = "WavesPage"
$WavesPage.text = "Waves"
$WavesPage.Font  = 'Microsoft Sans Serif,12'
$tabControl.Controls.Add($WavesPage)

#Users Page
$UsersPage.DataBindings.DefaultDataSourceUpdateMode = 0
$UsersPage.UseVisualStyleBackColor = $True
$UsersPage.Name = "UsersPage"
$UsersPage.text = "Users"
$UsersPage.Font  = 'Microsoft Sans Serif,12'
$tabControl.Controls.Add($UsersPage)

#Users Waves Page
$UsersWavesPage.DataBindings.DefaultDataSourceUpdateMode = 0
$UsersWavesPage.UseVisualStyleBackColor = $True
$UsersWavesPage.Name = "WavesPage"
$UsersWavesPage.text = "Users Waves"
$UsersWavesPage.Font  = 'Microsoft Sans Serif,20'
$tabControl.Controls.Add($UsersWavesPage)
















$ListView2                       = New-Object system.Windows.Forms.ListView
$ListView2.text                  = "listView"
$ListView2.width                 = 958
$ListView2.height                = 169
$ListView2.location              = New-Object System.Drawing.Point(17,532)

$Label1                          = New-Object system.Windows.Forms.Label
$Label1.text                     = "SQL Server Name"
$Label1.AutoSize                 = $true
$Label1.width                    = 25
$Label1.height                   = 10
$Label1.location                 = New-Object System.Drawing.Point(60,22)
$Label1.Font                     = 'Microsoft Sans Serif,10'

$Label2                          = New-Object system.Windows.Forms.Label
$Label2.text                     = "Database"
$Label2.AutoSize                 = $true
$Label2.width                    = 25
$Label2.height                   = 10
$Label2.location                 = New-Object System.Drawing.Point(60,59)
$Label2.Font                     = 'Microsoft Sans Serif,10'

$TextBox1                        = New-Object system.Windows.Forms.TextBox
$TextBox1.multiline              = $false
$TextBox1.width                  = 232
$TextBox1.height                 = 20
$TextBox1.location               = New-Object System.Drawing.Point(130,56)
$TextBox1.Font                   = 'Microsoft Sans Serif,10'

$TextBox2                        = New-Object system.Windows.Forms.TextBox
$TextBox2.multiline              = $false
$TextBox2.width                  = 232
$TextBox2.height                 = 20
$TextBox2.location               = New-Object System.Drawing.Point(177,20)
$TextBox2.Font                   = 'Microsoft Sans Serif,10'

$Button1                         = New-Object system.Windows.Forms.Button
$Button1.text                    = "Enter Credentials"
$Button1.width                   = 226
$Button1.height                  = 30
$Button1.location                = New-Object System.Drawing.Point(476,36)
$Button1.Font                    = 'Microsoft Sans Serif,10'

$Label3                          = New-Object system.Windows.Forms.Label
$Label3.text                     = "Remove this wave (Name of the wave) :"
$Label3.AutoSize                 = $true
$Label3.width                    = 25
$Label3.height                   = 10
$Label3.location                 = New-Object System.Drawing.Point(60,22)
$Label3.Font                     = 'Microsoft Sans Serif,10'
$WavesPage.Controls.Add($Label3)

$TextBox3                        = New-Object system.Windows.Forms.TextBox
$TextBox3.multiline              = $false
$TextBox3.width                  = 298
$TextBox3.height                 = 20
$TextBox3.location               = New-Object System.Drawing.Point(130,56)
$TextBox3.Font                   = 'Microsoft Sans Serif,10'
$WavesPage.Controls.Add($TextBox3)

$Form.controls.AddRange(@($ListView2,$Label1,$Label2,$TextBox1,$TextBox2,$Button1))

#region gui events {
$Button1.Add_Click({  })
#endregion events }

#endregion GUI }


#Write your logic code here

[void]$Form.ShowDialog()
