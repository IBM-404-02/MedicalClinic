USE master;
GO

IF DB_ID(N'MedicalClinicDB') IS NOT NULL
BEGIN
    ALTER DATABASE MedicalClinicDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE MedicalClinicDB;
END
GO

CREATE DATABASE MedicalClinicDB;
GO

USE MedicalClinicDB;
GO

CREATE TABLE Roles (
    RoleID   INT IDENTITY(1,1) CONSTRAINT PK_Roles PRIMARY KEY,
    Name     NVARCHAR(50) NOT NULL CONSTRAINT UQ_Roles_Name UNIQUE
);

CREATE TABLE Specializations (
    SpecializationID INT IDENTITY(1,1) CONSTRAINT PK_Specializations PRIMARY KEY,
    Name             NVARCHAR(100) NOT NULL CONSTRAINT UQ_Specializations_Name UNIQUE
);

CREATE TABLE AppointmentStatuses (
    StatusID INT IDENTITY(1,1) CONSTRAINT PK_AppointmentStatuses PRIMARY KEY,
    Name     NVARCHAR(50) NOT NULL CONSTRAINT UQ_AppointmentStatuses_Name UNIQUE
);

CREATE TABLE Users (
    UserID       INT IDENTITY(1,1) CONSTRAINT PK_Users PRIMARY KEY,
    Login        NVARCHAR(50)  NOT NULL CONSTRAINT UQ_Users_Login UNIQUE,
    PasswordHash NVARCHAR(64)  NOT NULL,
    FullName     NVARCHAR(150) NOT NULL,
    RoleID       INT           NOT NULL,
    IsActive     BIT           NOT NULL CONSTRAINT DF_Users_IsActive DEFAULT 1,

    CONSTRAINT CK_Users_Login CHECK (LEN(Login) >= 3),
    CONSTRAINT FK_Users_Roles FOREIGN KEY (RoleID) REFERENCES Roles(RoleID)
);

CREATE TABLE Doctors (
    DoctorID         INT IDENTITY(1,1) CONSTRAINT PK_Doctors PRIMARY KEY,
    UserID           INT          NOT NULL CONSTRAINT UQ_Doctors_UserID UNIQUE,
    SpecializationID INT          NOT NULL,
    Cabinet          NVARCHAR(10) NOT NULL,

    CONSTRAINT FK_Doctors_Users FOREIGN KEY (UserID) REFERENCES Users(UserID),
    CONSTRAINT FK_Doctors_Specializations FOREIGN KEY (SpecializationID) REFERENCES Specializations(SpecializationID)
);

CREATE TABLE Patients (
    PatientID        INT IDENTITY(1,1) CONSTRAINT PK_Patients PRIMARY KEY,
    LastName         NVARCHAR(50)  NOT NULL,
    FirstName        NVARCHAR(50)  NOT NULL,
    MiddleName       NVARCHAR(50)  NULL,
    BirthDate        DATE          NOT NULL,
    Gender           NCHAR(1)      NOT NULL,
    Phone            NVARCHAR(20)  NOT NULL CONSTRAINT UQ_Patients_Phone UNIQUE,
    PolicyNumber     NVARCHAR(16)  NULL,
    Address          NVARCHAR(200) NULL,
    RegistrationDate DATE          NOT NULL CONSTRAINT DF_Patients_RegDate DEFAULT CAST(GETDATE() AS DATE),

    CONSTRAINT CK_Patients_BirthDate CHECK (BirthDate > '1900-01-01' AND BirthDate <= CAST(GETDATE() AS DATE)),
    CONSTRAINT CK_Patients_Gender    CHECK (Gender IN (N'М', N'Ж')),
    CONSTRAINT CK_Patients_Phone     CHECK (LEN(Phone) >= 10)
);

CREATE TABLE Services (
    ServiceID        INT IDENTITY(1,1) CONSTRAINT PK_Services PRIMARY KEY,
    Name             NVARCHAR(150)  NOT NULL,
    SpecializationID INT            NOT NULL,
    Price            DECIMAL(10,2)  NOT NULL,
    IsActive         BIT            NOT NULL CONSTRAINT DF_Services_IsActive DEFAULT 1,

    CONSTRAINT CK_Services_Price CHECK (Price > 0),
    CONSTRAINT FK_Services_Specializations FOREIGN KEY (SpecializationID) REFERENCES Specializations(SpecializationID)
);

CREATE TABLE Appointments (
    AppointmentID       INT IDENTITY(1,1) CONSTRAINT PK_Appointments PRIMARY KEY,
    PatientID           INT           NOT NULL,
    DoctorID            INT           NOT NULL,
    ServiceID           INT           NOT NULL,
    AppointmentDateTime DATETIME2(0)  NOT NULL,
    StatusID            INT           NOT NULL CONSTRAINT DF_Appointments_Status DEFAULT 1,
    Price               DECIMAL(10,2) NOT NULL,
    IsPaid              BIT           NOT NULL CONSTRAINT DF_Appointments_IsPaid DEFAULT 0,
    CreatedByUserID     INT           NOT NULL,
    CreatedAt           DATETIME2(0)  NOT NULL CONSTRAINT DF_Appointments_CreatedAt DEFAULT SYSDATETIME(),

    CONSTRAINT CK_Appointments_Price CHECK (Price >= 0),
    CONSTRAINT FK_Appointments_Patients FOREIGN KEY (PatientID)       REFERENCES Patients(PatientID),
    CONSTRAINT FK_Appointments_Doctors  FOREIGN KEY (DoctorID)        REFERENCES Doctors(DoctorID),
    CONSTRAINT FK_Appointments_Services FOREIGN KEY (ServiceID)       REFERENCES Services(ServiceID),
    CONSTRAINT FK_Appointments_Statuses FOREIGN KEY (StatusID)        REFERENCES AppointmentStatuses(StatusID),
    CONSTRAINT FK_Appointments_Users    FOREIGN KEY (CreatedByUserID) REFERENCES Users(UserID)
);

CREATE TABLE Visits (
    VisitID         INT IDENTITY(1,1) CONSTRAINT PK_Visits PRIMARY KEY,
    AppointmentID   INT            NOT NULL CONSTRAINT UQ_Visits_AppointmentID UNIQUE,
    Complaints      NVARCHAR(1000) NULL,
    Diagnosis       NVARCHAR(300)  NOT NULL,
    Recommendations NVARCHAR(1000) NULL,
    VisitDateTime   DATETIME2(0)   NOT NULL CONSTRAINT DF_Visits_DateTime DEFAULT SYSDATETIME(),

    CONSTRAINT FK_Visits_Appointments FOREIGN KEY (AppointmentID) REFERENCES Appointments(AppointmentID)
);
GO

CREATE UNIQUE INDEX UX_Appointments_Doctor_Time
    ON Appointments (DoctorID, AppointmentDateTime)
    WHERE StatusID <> 3;

CREATE UNIQUE INDEX UX_Patients_Policy
    ON Patients (PolicyNumber)
    WHERE PolicyNumber IS NOT NULL;

CREATE INDEX IX_Patients_LastName         ON Patients (LastName);
CREATE INDEX IX_Appointments_DateTime     ON Appointments (AppointmentDateTime);
CREATE INDEX IX_Appointments_PatientID    ON Appointments (PatientID);
GO

CREATE VIEW vw_AppointmentsFull AS
SELECT
    a.AppointmentID,
    a.AppointmentDateTime,
    p.LastName + N' ' + p.FirstName + ISNULL(N' ' + p.MiddleName, N'') AS PatientName,
    u.FullName       AS DoctorName,
    sp.Name          AS Specialization,
    d.Cabinet,
    s.Name           AS ServiceName,
    st.Name          AS StatusName,
    a.Price,
    a.IsPaid
FROM Appointments a
JOIN Patients            p  ON p.PatientID        = a.PatientID
JOIN Doctors             d  ON d.DoctorID         = a.DoctorID
JOIN Users               u  ON u.UserID           = d.UserID
JOIN Specializations     sp ON sp.SpecializationID = d.SpecializationID
JOIN Services            s  ON s.ServiceID        = a.ServiceID
JOIN AppointmentStatuses st ON st.StatusID        = a.StatusID;
GO

INSERT INTO Roles (Name) VALUES
    (N'Администратор'),
    (N'Регистратор'),
    (N'Врач');

INSERT INTO AppointmentStatuses (Name) VALUES
    (N'Запланирована'),
    (N'Завершена'),
    (N'Отменена'),
    (N'Неявка');

INSERT INTO Users (Login, PasswordHash, FullName, RoleID) VALUES
    (N'admin', CONVERT(NVARCHAR(64), HASHBYTES('SHA2_256', 'admin123'), 2), N'Администратор системы', 1);
GO