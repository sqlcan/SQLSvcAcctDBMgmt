-- If computer and service account pair is not found, it creates new entry.
EXEC dbo.AddComputerInstance
		@ComputerName = 'MOGUPTA-PC01',
		@ServiceAccountName = '.\SvcSQL',
		@ServiceAccountOldPassword = 'Password1',
		@ServiceAccountNewPassword = 'P@ssword123',
		@Passphrase = N'a54965a34d2407786456380953cedb89'

-- Updating existing; if existing account exists, script will only update the old and new password.
EXEC dbo.AddComputerInstance
		@ComputerName = 'MOGUPTA-PC01',
		@ServiceAccountName = '.\SvcSQL',
		@ServiceAccountOldPassword = 'Password1',
		@ServiceAccountNewPassword = 'P@ssword123',
		@Passphrase = N'a54965a34d2407786456380953cedb89'