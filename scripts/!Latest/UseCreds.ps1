#set up path and user variables
            $AESKeyFilePath = “aeskey.txt” # location of the AESKey                
            $SecurePwdFilePath = “credpassword.txt” # location of the file that hosts the encrypted password                
            $userUPN = "domain\userName" # User account login 

            #use key and password to create local secure password
            $AESKey = Get-Content -Path $AESKeyFilePath 
            $pwdTxt = Get-Content -Path $SecurePwdFilePath
            $securePass = $pwdTxt | ConvertTo-SecureString -Key $AESKey

            #crete a new psCredential object with required username and password
            $adminCreds = New-Object System.Management.Automation.PSCredential($userUPN, $securePass)

            #use the $adminCreds for some task
            some-Task-that-needs-credentials -Credential $adminCreds