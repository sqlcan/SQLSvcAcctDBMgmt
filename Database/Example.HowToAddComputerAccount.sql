-- Few Notes about dbo.AddComputerInstance
--
-- ComputerName, ServiceAccountName, ServiceType are mandatory for lookup in PowerShell Script.
-- ServiceType defaults to 'All'; for list of supported services refere to dbo.ServiceType.
--   If you wish to add additional services support please update the table; however it has
--   not been tested with any other service.  
-- 
-- Must supply values in following combinations:
-- ComputerName, ServiceAccountName, ServiceType, ServiceAccountOldPassword, ServiceAccountNewPassword
-- ComputerName, ServiceAccountName, NewServiceAccountName, ServiceType, ServiceAccountNewPassword
--
-- If all values are supplied, then it is assumed service account change is required.

-- If computer and service account pair is not found, it creates new entry.
	-- Example 1: Update password on all SQL Services on Contoso.
	EXEC dbo.AddComputerInstance
			@ComputerName = 'Contoso',
			@ServiceAccountName = '.\SvcSQL',
			@ServiceAccountOldPassword = 'Password1',
			@ServiceAccountNewPassword = 'P@ssword123',
			@Passphrase = N'a54965a34d2407786456380953cedb89'

	-- Example 2: Update password for SQL Engine only on Contoso.
	EXEC dbo.AddComputerInstance
			@ComputerName = 'Contoso',
			@ServiceType = 'SqlServer',
			@ServiceAccountName = '.\SvcSQL',
			@ServiceAccountOldPassword = 'Password1',
			@ServiceAccountNewPassword = 'P@ssword123',
			@Passphrase = N'a54965a34d2407786456380953cedb89'

	-- Example 3: Change Service account for All Services.
	EXEC dbo.AddComputerInstance
			@ComputerName = 'Contoso',
			@ServiceAccountName = '.\SvcSQL',
			@NewServiceAccountName = '.\SvcSQL2',
			@ServiceAccountNewPassword = 'P@ssword123',
			@Passphrase = N'a54965a34d2407786456380953cedb89'

-- Updating existing; of ComputerName, ServiceAccount, ServiceType already exists then remaining
-- fields are updated with value supplied.
	EXEC dbo.AddComputerInstance
			@ComputerName = 'Contoso',
			@ServiceAccountName = '.\SvcSQL',
			@ServiceAccountOldPassword = 'Password1',
			@ServiceAccountNewPassword = 'P@ssword123',
			@Passphrase = N'a54965a34d2407786456380953cedb89'