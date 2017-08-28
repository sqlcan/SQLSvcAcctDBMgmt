USE master
GO

CREATE DATABASE SvcAcctMgmt
GO

USE SvcAcctMgmt
GO

CREATE TABLE dbo.ComputerInstance (
   ID INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
   ComputerName VARCHAR(255) NOT NULL,
   ServiceAccountName VARCHAR(255) NOT NULL,
   ServiceAccountOldPassword VARBINARY(256) NOT NULL,
   ServiceAccountNewPassword VARBINARY(256) NOT NULL)
GO

CREATE UNIQUE NONCLUSTERED INDEX idx_u_ComputerInstance ON dbo.ComputerInstance(ComputerName,ServiceAccountName)
GO

CREATE PROC dbo.GetComputerInstance
   @ComputerName VARCHAR(255) = NULL,
   @ServiceAccountName VARCHAR(255) = NULL,
   @Passphrase NVARCHAR(128)
AS
BEGIN


	SELECT   ComputerName
	       , ServiceAccountName
		   , CAST(DECRYPTBYPASSPHRASE(@Passphrase, ServiceAccountOldPassword) AS VARCHAR(255)) AS ServiceAccountOldPassword
		   , CAST(DECRYPTBYPASSPHRASE(@Passphrase, ServiceAccountNewPassword) AS VARCHAR(255)) AS ServiceAccountNewPassword
	  FROM dbo.ComputerInstance
	 WHERE ((ComputerName = @ComputerName) OR (@ComputerName IS NULL))
	   AND ((ServiceAccountName = @ServiceAccountName) OR (@ServiceAccountName IS NULL))

END
GO

CREATE PROC dbo.AddComputerInstance
   @ComputerName VARCHAR(255),
   @ServiceAccountName VARCHAR(255),
   @ServiceAccountOldPassword VARCHAR(255),
   @ServiceAccountNewPassword VARCHAR(255),
   @Passphrase NVARCHAR(128)
AS
BEGIN

	IF EXISTS (SELECT * FROM dbo.ComputerInstance WHERE ComputerName = @ComputerName AND ServiceAccountName = @ServiceAccountName)
	BEGIN
		UPDATE dbo.ComputerInstance
		   SET ServiceAccountOldPassword = ENCRYPTBYPASSPHRASE(@Passphrase,@ServiceAccountOldPassword),
		       ServiceAccountNewPassword = ENCRYPTBYPASSPHRASE(@Passphrase,@ServiceAccountNewPassword)
         WHERE ComputerName = @ComputerName
		   AND ServiceAccountName = @ServiceAccountName
	END
	ELSE
	BEGIN
		INSERT
		  INTO dbo.ComputerInstance (ComputerName, ServiceAccountName, ServiceAccountOldPassword, ServiceAccountNewPassword)
		VALUES (  @ComputerName
				, @ServiceAccountName
				, ENCRYPTBYPASSPHRASE(@Passphrase,@ServiceAccountOldPassword)
				, ENCRYPTBYPASSPHRASE(@Passphrase,@ServiceAccountNewPassword))
	END

END
GO