Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Crear una ventana
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "Administrador de Usuarios | Ikkxeer"
$mainForm.Size = New-Object System.Drawing.Size(600, 400)

# Crear una lista de usuarios
$userList = New-Object System.Windows.Forms.ListBox
$userList.Location = New-Object System.Drawing.Point(20, 20)
$userList.Size = New-Object System.Drawing.Size(200, 300)
$mainForm.Controls.Add($userList)

# Obtener la lista de usuarios
$users = Get-LocalUser

foreach ($user in $users) {
    $userList.Items.Add($user.Name)
}

# Cuadro de texto para mostrar especificaciones
$specTextBox = New-Object System.Windows.Forms.TextBox
$specTextBox.Location = New-Object System.Drawing.Point(240, 20)
$specTextBox.Size = New-Object System.Drawing.Size(320, 100)
$specTextBox.Multiline = $true
$specTextBox.ReadOnly = $true
$mainForm.Controls.Add($specTextBox)

# Funcion para mostrar especificaciones
$userList_SelectedIndexChanged = {
    $selectedUser = $userList.SelectedItem
    if ($selectedUser) {
        try {
            $user = Get-LocalUser -Name $selectedUser -ErrorAction Stop

            $specTextBox.Text = @"
Nombre: $($user.Name)
Descripcion: $($user.Description)
Habilitado: $($user.Enabled)
Nivel de acceso: $($user.AccountType)
"@
        } catch {
            $specTextBox.Text = "Error al obtener detalles del usuario."
        }
    }
}

$userList.add_SelectedIndexChanged($userList_SelectedIndexChanged)

# Funcion para actualizar la lista de usuarios
function UpdateUserList {
    $userList.Items.Clear()
    $users = Get-LocalUser
    foreach ($user in $users) {
        $userList.Items.Add($user.Name)
    }
}

# Boton para modificar parametros
$modifyButton = New-Object System.Windows.Forms.Button
$modifyButton.Location = New-Object System.Drawing.Point(240, 140)
$modifyButton.Size = New-Object System.Drawing.Size(100, 30)
$modifyButton.Text = "Modificar"
$modifyButton.Add_Click({
    $selectedUser = $userList.SelectedItem
    if ($selectedUser) {
        try {
            $user = Get-LocalUser -Name $selectedUser -ErrorAction Stop

            # Crear una ventana de dialogo para modificar usuario
            $modifyUserForm = New-Object System.Windows.Forms.Form
            $modifyUserForm.Text = "Modificar Usuario: $selectedUser"
            $modifyUserForm.Size = New-Object System.Drawing.Size(400, 300)

            $newUserNameLabel = New-Object System.Windows.Forms.Label
            $newUserNameLabel.Text = "Nuevo Nombre de Usuario:"
            $newUserNameLabel.Location = New-Object System.Drawing.Point(10, 20)
            $modifyUserForm.Controls.Add($newUserNameLabel)

            $newUserNameTextBox = New-Object System.Windows.Forms.TextBox
            $newUserNameTextBox.Text = $user.Name
            $newUserNameTextBox.Location = New-Object System.Drawing.Point(200, 20)
            $modifyUserForm.Controls.Add($newUserNameTextBox)

            $newUserDescLabel = New-Object System.Windows.Forms.Label
            $newUserDescLabel.Text = "Nueva Descripcion:"
            $newUserDescLabel.Location = New-Object System.Drawing.Point(10, 60)
            $modifyUserForm.Controls.Add($newUserDescLabel)

            $newUserDescTextBox = New-Object System.Windows.Forms.TextBox
            $newUserDescTextBox.Text = $user.Description
            $newUserDescTextBox.Location = New-Object System.Drawing.Point(200, 60)
            $modifyUserForm.Controls.Add($newUserDescTextBox)

            $newUserPassLabel = New-Object System.Windows.Forms.Label
            $newUserPassLabel.Text = "Nueva Contraseña:"
            $newUserPassLabel.Location = New-Object System.Drawing.Point(10, 100)
            $modifyUserForm.Controls.Add($newUserPassLabel)

            $newUserPassTextBox = New-Object System.Windows.Forms.TextBox
            $newUserPassTextBox.Location = New-Object System.Drawing.Point(200, 100)
            $modifyUserForm.Controls.Add($newUserPassTextBox)

            $groupLabel = New-Object System.Windows.Forms.Label
            $groupLabel.Text = "Grupo:"
            $groupLabel.Location = New-Object System.Drawing.Point(10, 140)
            $modifyUserForm.Controls.Add($groupLabel)

            $groupComboBox = New-Object System.Windows.Forms.ComboBox
            $groupComboBox.Location = New-Object System.Drawing.Point(200, 140)

            # Obtener la lista de grupos y agregarlos al ComboBox
            $groups = Get-LocalGroup
            foreach ($group in $groups) {
                $groupComboBox.Items.Add($group.Name)
            }

            $modifyUserForm.Controls.Add($groupComboBox)

            $modifyButton = New-Object System.Windows.Forms.Button
            $modifyButton.Text = "Guardar Cambios"
            $modifyButton.Location = New-Object System.Drawing.Point(150, 200)
            $modifyButton.Add_Click({
                $newUserName = $newUserNameTextBox.Text
                $newUserDescription = $newUserDescTextBox.Text
                $newUserPassword = $newUserPassTextBox.Text
                $selectedGroup = $groupComboBox.SelectedItem

                if ($newUserName) {
                    try {
                        # Cambiar el nombre de usuario
                        Rename-LocalUser -Name $selectedUser -NewName $newUserName -ErrorAction Stop
                    } catch {
                        [System.Windows.Forms.MessageBox]::Show("Error al cambiar el nombre de usuario: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                    }
                }

                if ($newUserDescription) {
                    try {
                        # Cambiar la descripcion
                        Set-LocalUser -Name $newUserName -Description $newUserDescription -ErrorAction Stop
                    } catch {
                        [System.Windows.Forms.MessageBox]::Show("Error al cambiar la descripcion del usuario: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                    }
                }

                if ($newUserPassword) {
                    try {
                        # Cambiar la contraseña
                        Set-LocalUser -Name $newUserName -Password (ConvertTo-SecureString -String $newUserPassword -AsPlainText -Force) -ErrorAction Stop
                    } catch {
                        [System.Windows.Forms.MessageBox]::Show("Error al cambiar la contraseña del usuario: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                    }
                }

                if ($selectedGroup) {
                    try {
                        # Cambiar el grupo
                        $group = Get-LocalGroup -Name $selectedGroup -ErrorAction Stop
                        $user = Get-LocalUser -Name $newUserName -ErrorAction Stop
                        Remove-LocalGroupMember -Group $user.PrimaryGroup -Member $user.Name -ErrorAction Stop
                        Add-LocalGroupMember -Group $group -Member $user.Name -ErrorAction Stop
                    } catch {
                        [System.Windows.Forms.MessageBox]::Show("Error al cambiar el grupo del usuario: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                    }
                }

                UpdateUserList | Out-Null
                $modifyUserForm.Close()
            })
            $modifyUserForm.Controls.Add($modifyButton)

            $modifyUserForm.ShowDialog() | Out-Null
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Error al obtener detalles del usuario: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Por favor, selecciona un usuario de la lista antes de modificar.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    }
})
$mainForm.Controls.Add($modifyButton)

# Boton para eliminar usuario
$deleteButton = New-Object System.Windows.Forms.Button
$deleteButton.Location = New-Object System.Drawing.Point(360, 140)
$deleteButton.Size = New-Object System.Drawing.Size(100, 30)
$deleteButton.Text = "Eliminar"
$deleteButton.Add_Click({
    $selectedUser = $userList.SelectedItem
    $confirmation = [System.Windows.Forms.MessageBox]::Show("¿Estas seguro de que deseas eliminar al usuario?", "Confirmar Eliminacion", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)

    if ($confirmation -eq [System.Windows.Forms.DialogResult]::Yes) {
        Remove-LocalUser -Name $selectedUser -Confirm:$false -ErrorAction Stop
        UpdateUserList | Out-Null
        $specTextBox.Text = ""
    }
})
$mainForm.Controls.Add($deleteButton)

# Boton para crear nuevo usuario
$createButton = New-Object System.Windows.Forms.Button
$createButton.Location = New-Object System.Drawing.Point(480, 140)
$createButton.Size = New-Object System.Drawing.Size(80, 30)
$createButton.Text = "Crear"
$createButton.Add_Click({
    $newUserForm = New-Object System.Windows.Forms.Form
    $newUserForm.Text = "Crear Nuevo Usuario"
    $newUserForm.Size = New-Object System.Drawing.Size(300, 300)
    
    $userNameLabel = New-Object System.Windows.Forms.Label
    $userNameLabel.Text = "Nombre de Usuario:"
    $userNameLabel.Location = New-Object System.Drawing.Point(10, 20)
    $newUserForm.Controls.Add($userNameLabel)
    
    $userNameTextBox = New-Object System.Windows.Forms.TextBox
    $userNameTextBox.Location = New-Object System.Drawing.Point(120, 20)
    $newUserForm.Controls.Add($userNameTextBox)
    
    $userDescLabel = New-Object System.Windows.Forms.Label
    $userDescLabel.Text = "Descripcion:"
    $userDescLabel.Location = New-Object System.Drawing.Point(10, 60)
    $newUserForm.Controls.Add($userDescLabel)
    
    $userDescTextBox = New-Object System.Windows.Forms.TextBox
    $userDescTextBox.Location = New-Object System.Drawing.Point(120, 60)
    $newUserForm.Controls.Add($userDescTextBox)
    
    $userPassLabel = New-Object System.Windows.Forms.Label
    $userPassLabel.Text = "Contraseña:"
    $userPassLabel.Location = New-Object System.Drawing.Point(10, 100)
    $newUserForm.Controls.Add($userPassLabel)
    
    $userPassTextBox = New-Object System.Windows.Forms.TextBox
    $userPassTextBox.Location = New-Object System.Drawing.Point(120, 100)
    $newUserForm.Controls.Add($userPassTextBox)
    
    $groupLabel = New-Object System.Windows.Forms.Label
    $groupLabel.Text = "Grupo:"
    $groupLabel.Location = New-Object System.Drawing.Point(10, 140)
    $newUserForm.Controls.Add($groupLabel)

    $groupComboBox = New-Object System.Windows.Forms.ComboBox
    $groupComboBox.Location = New-Object System.Drawing.Point(120, 140)
    
    # Obtener la lista de grupos y agregarlos al ComboBox
    $groups = Get-LocalGroup
    foreach ($group in $groups) {
        $groupComboBox.Items.Add($group.Name)
    }
    
    $newUserForm.Controls.Add($groupComboBox)
    
    $createUserButton = New-Object System.Windows.Forms.Button
    $createUserButton.Text = "Crear"
    $createUserButton.Location = New-Object System.Drawing.Point(120, 180)
    $createUserButton.Add_Click({
        $newUserName = $userNameTextBox.Text
        $newUserDescription = $userDescTextBox.Text
        $newUserPassword = $userPassTextBox.Text
        $selectedGroup = $groupComboBox.SelectedItem
        
        if ([string]::IsNullOrEmpty($newUserName) -or [string]::IsNullOrEmpty($newUserPassword) -or [string]::IsNullOrEmpty($selectedGroup)) {
            [System.Windows.Forms.MessageBox]::Show("Debe completar todos los campos.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
            return
        }

        # Crear el usuario y agregarlo al grupo seleccionado
        New-LocalUser -Name $newUserName -Description $newUserDescription -Password (ConvertTo-SecureString -String $newUserPassword -AsPlainText -Force) | Out-Null
        Add-LocalGroupMember -Group $selectedGroup -Member $newUserName | Out-Null

        UpdateUserList | Out-Null
        $newUserForm.Close()
    })
    $newUserForm.Controls.Add($createUserButton)
    
    $newUserForm.ShowDialog() | Out-Null
})
$mainForm.Controls.Add($createButton)

# Mostrar la ventana
$mainForm.ShowDialog() | Out-Null
