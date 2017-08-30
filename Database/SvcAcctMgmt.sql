USE master
GO

CREATE DATABASE SvcAcctMgmt
GO

USE SvcAcctMgmt
GO

CREATE TABLE dbo.ComputerInstance (
   ID INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
   ComputerName VARCHAR(255) NOT NULL,
   ServiceTypeID INT NOT NULL DEFAULT (1),
   ServiceAccountName VARCHAR(255) NOT NULL,
   NewServiceAccountName VARCHAR(255) NULL,
   ServiceAccountOldPassword VARBINARY(256) NULL,
   ServiceAccountNewPassword VARBINARY(256) NOT NULL)
GO

CREATE UNIQUE NONCLUSTERED INDEX idx_u_ComputerInstance ON dbo.ComputerInstance(ComputerName,ServiceType,ServiceAccountName)
GO

CREATE TABLE dbo.ServiceType (
   ID INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
   ServiceType VARCHAR(25) NOT NULL)
GO

CREATE UNIQUE NONCLUSTERED INDEX idx_u_ServiceType ON dbo.ServiceType(ServiceType)
GO

-- Add additional service types that needs to be managed via this automation.
-- https://msdn.microsoft.com/en-us/library/microsoft.sqlserver.management.smo.wmi.managedservicetype.aspx
INSERT INTO dbo.ServiceType (ServiceType)
VALUES ('All'), ('SqlServer'),('SqlAgent'),('AnalysisServer')
GO

ALTER TABLE dbo.ComputerInstance ADD CONSTRAINT
	FK_ComputerInstance_ServiceType FOREIGN KEY
	(
	ServiceTypeID
	) REFERENCES dbo.ServiceType
	(
	ID
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO

CREATE PROC dbo.GetComputerInstance
   @ComputerName VARCHAR(255) = NULL,
   @ServiceAccountName VARCHAR(255) = NULL,
   @ServiceType VARCHAR(25) = 'All',
   @Passphrase NVARCHAR(128)
AS
BEGIN

	DECLARE @ServiceID    INT
	
	SELECT @ServiceID = ID	  FROM dbo.ServiceType WHERE ServiceType = @ServiceType

	IF (@ServiceID IS NULL)
	BEGIN
		RAISERROR('Service type [%s] does not exist in dbo.ServiceType.',16,1,@ServiceType)
		RETURN
    END

	IF (@ServiceType <> 'All')
	BEGIN
		-- Get all services of a specific type; also grab all servers where service type is set to all.
		-- However, override value for SerivceType to value supplied.  So even with servers of ALL,
		-- only the service requested is updated.
		SELECT   ComputerName
			   , ServiceAccountName
			   , NewServiceAccountName
			   , @ServiceType AS ServiceType
			   , CAST(DECRYPTBYPASSPHRASE(@Passphrase, ServiceAccountOldPassword) AS VARCHAR(255)) AS ServiceAccountOldPassword
			   , CAST(DECRYPTBYPASSPHRASE(@Passphrase, ServiceAccountNewPassword) AS VARCHAR(255)) AS ServiceAccountNewPassword
		  FROM dbo.ComputerInstance CI
		  JOIN dbo.ServiceType ST
			ON CI.ServiceTypeID = ST.ID
		 WHERE ((ComputerName = @ComputerName) OR (@ComputerName IS NULL))
		   AND ((ServiceAccountName = @ServiceAccountName) OR (@ServiceAccountName IS NULL))
		   AND ((ServiceType = @ServiceType) OR (ServiceType = 'All'))
	END
	ELSE
	BEGIN
		-- If all services are required, then no filter is required on service type.
		SELECT   ComputerName
			   , ServiceAccountName
			   , NewServiceAccountName
			   , ST.ServiceType
			   , CAST(DECRYPTBYPASSPHRASE(@Passphrase, ServiceAccountOldPassword) AS VARCHAR(255)) AS ServiceAccountOldPassword
			   , CAST(DECRYPTBYPASSPHRASE(@Passphrase, ServiceAccountNewPassword) AS VARCHAR(255)) AS ServiceAccountNewPassword
		  FROM dbo.ComputerInstance CI
		  JOIN dbo.ServiceType ST
			ON CI.ServiceTypeID = ST.ID
		 WHERE ((ComputerName = @ComputerName) OR (@ComputerName IS NULL))
		   AND ((ServiceAccountName = @ServiceAccountName) OR (@ServiceAccountName IS NULL))
    END

END
GO

CREATE PROC dbo.AddComputerInstance
   @ComputerName VARCHAR(255),
   @ServiceType VARCHAR(25) = 'All',
   @ServiceAccountName VARCHAR(255),
   @NewServiceAccountName VARCHAR(255) = NULL,
   @ServiceAccountOldPassword VARCHAR(255) = NULL,
   @ServiceAccountNewPassword VARCHAR(255),
   @Passphrase NVARCHAR(128)
AS
BEGIN

	DECLARE @AllServiceID INT
	DECLARE @ServiceID    INT
	
	SELECT @AllServiceID = ID FROM dbo.ServiceType WHERE ServiceType = 'All'
	SELECT @ServiceID = ID	  FROM dbo.ServiceType WHERE ServiceType = @ServiceType

	IF (@ServiceID IS NULL)
	BEGIN
		RAISERROR('Service type [%s] does not exist in dbo.ServiceType.',16,1,@ServiceType)
		RETURN
    END

	-- Internal logic checks:
	-- A computer/service account can have mapping to individual service types (Engine, SSAS, Agent)
	-- Or All; but cannot have both.

	IF (@ServiceType <> 'All')
	BEGIN
		IF (SELECT COUNT(*) FROM dbo.ComputerInstance WHERE ComputerName = @ComputerName AND ServiceAccountName = @ServiceAccountName AND ServiceTypeID = @AllServiceID) > 0
		BEGIN
			RAISERROR('Cannot add or update entry for computer name [%s] and service acount [%s] for service [%s]; as it already mapped to All services.',16,1,@ComputerName,@ServiceAccountName,@ServiceType)
			RETURN	
		END
	END
	ELSE
	BEGIN
		IF (SELECT COUNT(*) FROM dbo.ComputerInstance WHERE ComputerName = @ComputerName AND ServiceAccountName = @ServiceAccountName AND ServiceTypeID <> @AllServiceID) > 0
		BEGIN
			RAISERROR('Cannot add or update entry for computer name [%s] and service acount [%s] for All services; as it already mapped to an individual service.',16,1,@ComputerName,@ServiceAccountName,@ServiceType)
			RETURN	
		END
    END

	IF EXISTS (SELECT * FROM dbo.ComputerInstance WHERE ComputerName = @ComputerName AND ServiceAccountName = @ServiceAccountName AND ServiceTypeID = @ServiceID)
	BEGIN
		UPDATE dbo.ComputerInstance
		   SET NewServiceAccountName = @NewServiceAccountName,
		       ServiceAccountOldPassword = ENCRYPTBYPASSPHRASE(@Passphrase,@ServiceAccountOldPassword),
		       ServiceAccountNewPassword = ENCRYPTBYPASSPHRASE(@Passphrase,@ServiceAccountNewPassword)
         WHERE ComputerName = @ComputerName
		   AND ServiceAccountName = @ServiceAccountName
		   AND ServiceTypeID = @ServiceID
	END
	ELSE
	BEGIN
		INSERT
		  INTO dbo.ComputerInstance (ComputerName, ServiceAccountName, ServiceTypeID, NewServiceAccountName, ServiceAccountOldPassword, ServiceAccountNewPassword)
		VALUES (  @ComputerName
				, @ServiceAccountName
				, @ServiceID
				, @NewServiceAccountName
				, ENCRYPTBYPASSPHRASE(@Passphrase,@ServiceAccountOldPassword)
				, ENCRYPTBYPASSPHRASE(@Passphrase,@ServiceAccountNewPassword))
	END

END
GO