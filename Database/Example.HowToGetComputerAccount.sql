-- Get all the computers, service accounts, services and their respective updates.
EXEC dbo.GetComputerInstance
		@Passphrase = N'a54965a34d2407786456380953cedb89'

-- Get the computer Contoso, service accounts, and their respective updates.
EXEC dbo.GetComputerInstance
		@ComputerName = 'Contoso',
		@Passphrase = N'a54965a34d2407786456380953cedb89'

-- Get all the computer that use the service accounts, 'Domain\SQLSvc', and their respective updates.
EXEC dbo.GetComputerInstance
		@ServiceAccountName = 'Domain\SQLSvc',
		@Passphrase = N'a54965a34d2407786456380953cedb89'

-- Get all the computers, service accounts, services and their respective updates.
EXEC dbo.GetComputerInstance
		@ServiceType = 'SQLServer',
		@Passphrase = N'a54965a34d2407786456380953cedb89'