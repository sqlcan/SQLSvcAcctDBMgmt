-- Get all the computers, service accounts, and their respective passwords.
EXEC dbo.GetComputerInstance
		@Passphrase = N'a54965a34d2407786456380953cedb89'

-- Get the computer MOGUPTA-PC01, service accounts, and their respective passwords.
EXEC dbo.GetComputerInstance
		@ComputerName = 'MOGUPTA-PC01',
		@Passphrase = N'a54965a34d2407786456380953cedb89'

-- Get all the computer that use the service accounts, 'Domain\SQLSvc', and their respective passwords.
EXEC dbo.GetComputerInstance
		@ServiceAccountName = 'Domain\SQLSvc',
		@Passphrase = N'a54965a34d2407786456380953cedb89'