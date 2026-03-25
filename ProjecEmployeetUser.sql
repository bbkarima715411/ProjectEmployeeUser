
--Je crée mon projet
CREATE DATABASE ProjectEmployeeUser;
GO

--J'appelle mon projet pour travaillé dedans
USE ProjectEmployeeUser;
GO

--Je créé mes tables 
CREATE TABLE Users
(
    UserId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    Email VARCHAR(320) NOT NULL UNIQUE,
    PasswordHash VARBINARY(64) NOT NULL,
    Salt UNIQUEIDENTIFIER NOT NULL
);
GO

CREATE TABLE Employees
(
    EmployeeId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    Firstname VARCHAR(64) NOT NULL,
    Lastname VARCHAR(64) NOT NULL,
    Hiredate DATE NOT NULL,
    IsProjectManager BIT NOT NULL,
    UserId UNIQUEIDENTIFIER NULL UNIQUE,
    CONSTRAINT FK_Employees_Users
        FOREIGN KEY (UserId) REFERENCES Users(UserId)
);
GO

CREATE TABLE Projects
(
    ProjectId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    Name VARCHAR(256) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    CreationDate DATETIME NOT NULL,
    ManagerEmployeeId UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT FK_Projects_Manager
        FOREIGN KEY (ManagerEmployeeId) REFERENCES Employees(EmployeeId)
);
GO

CREATE TABLE Posts
(
    PostId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    Subject VARCHAR(256) NOT NULL,
    Content NVARCHAR(MAX) NOT NULL,
    SendDate DATETIME NOT NULL,
    EmployeeId UNIQUEIDENTIFIER NOT NULL,
    ProjectId UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT FK_Posts_Employees
        FOREIGN KEY (EmployeeId) REFERENCES Employees(EmployeeId),
    CONSTRAINT FK_Posts_Projects
        FOREIGN KEY (ProjectId) REFERENCES Projects(ProjectId)
);
GO

CREATE TABLE TakePart
(
    EmployeeId UNIQUEIDENTIFIER NOT NULL,
    ProjectId UNIQUEIDENTIFIER NOT NULL,
    StartDate DATETIME NOT NULL,
    EndDate DATETIME NULL,
    CONSTRAINT PK_TakePart PRIMARY KEY (EmployeeId, ProjectId, StartDate),
    CONSTRAINT FK_TakePart_Employees
        FOREIGN KEY (EmployeeId) REFERENCES Employees(EmployeeId),
    CONSTRAINT FK_TakePart_Projects
        FOREIGN KEY (ProjectId) REFERENCES Projects(ProjectId)
);
GO

--J'insere des données test

INSERT INTO Users (UserId, Email, PasswordHash, Salt)
VALUES
(NEWID(), 'alice@test.be', HASHBYTES('SHA2_256', 'demo'), NEWID()),
(NEWID(), 'karim@test.be', HASHBYTES('SHA2_256', 'demo'), NEWID());
GO

SELECT * FROM Users;
GO

--Je créé ma procedure enregistré un user
CREATE PROCEDURE sp_RegisterUser
    @Email VARCHAR(320),
    @Password NVARCHAR(255),
    @Firstname VARCHAR(64),
    @Lastname VARCHAR(64),
    @Hiredate DATE,
    @IsProjectManager BIT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UserId UNIQUEIDENTIFIER = NEWID();
    DECLARE @EmployeeId UNIQUEIDENTIFIER = NEWID();
    DECLARE @Salt UNIQUEIDENTIFIER = NEWID();

    DECLARE @PasswordHash VARBINARY(64);
    SET @PasswordHash = HASHBYTES('SHA2_256', CONVERT(NVARCHAR(255), @Salt) + @Password);

    INSERT INTO Users (UserId, Email, PasswordHash, Salt)
    VALUES (@UserId, @Email, @PasswordHash, @Salt);

    INSERT INTO Employees (EmployeeId, Firstname, Lastname, Hiredate, IsProjectManager, UserId)
    VALUES (@EmployeeId, @Firstname, @Lastname, @Hiredate, @IsProjectManager, @UserId);
END;
GO

--Créé une procedure pour savoir si un user est chef de projet
CREATE PROCEDURE sp_IsProjectManager
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT IsProjectManager
    FROM Employees
    WHERE UserId = @UserId;
END;
GO

--Créé une procedure pour créé un projet
CREATE PROCEDURE sp_CreateProject
    @Name VARCHAR(256),
    @Description NVARCHAR(MAX),
    @ManagerEmployeeId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1
        FROM Employees
        WHERE EmployeeId = @ManagerEmployeeId
          AND IsProjectManager = 1
    )
    BEGIN
        RAISERROR('Cet employé n''est pas chef de projet.', 16, 1);
        RETURN;
    END

    INSERT INTO Projects (ProjectId, Name, Description, CreationDate, ManagerEmployeeId)
    VALUES (NEWID(), @Name, @Description, GETDATE(), @ManagerEmployeeId);
END;
GO

--Créé une procedure liste des user diponible


