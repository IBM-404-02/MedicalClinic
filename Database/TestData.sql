USE MedicalClinicDB;
GO

IF EXISTS (SELECT 1 FROM Patients)
    THROW 50000, N'Тестовые данные уже загружены. Сначала заново запусти MedicalClinicDB.sql', 1;
GO

INSERT INTO Specializations (Name) VALUES
    (N'Терапевт'),
    (N'Хирург'),
    (N'Кардиолог'),
    (N'Офтальмолог');

INSERT INTO Users (Login, PasswordHash, FullName, RoleID) VALUES
    (N'registr1', CONVERT(NVARCHAR(64), HASHBYTES('SHA2_256', 'reg123'), 2), N'Соколова Анна Викторовна',     2),
    (N'registr2', CONVERT(NVARCHAR(64), HASHBYTES('SHA2_256', 'reg123'), 2), N'Лебедева Ольга Игоревна',      2),
    (N'doc1',     CONVERT(NVARCHAR(64), HASHBYTES('SHA2_256', 'doc123'), 2), N'Иванов Сергей Петрович',       3),
    (N'doc2',     CONVERT(NVARCHAR(64), HASHBYTES('SHA2_256', 'doc123'), 2), N'Кузнецова Мария Андреевна',    3),
    (N'doc3',     CONVERT(NVARCHAR(64), HASHBYTES('SHA2_256', 'doc123'), 2), N'Морозов Алексей Дмитриевич',   3),
    (N'doc4',     CONVERT(NVARCHAR(64), HASHBYTES('SHA2_256', 'doc123'), 2), N'Васильева Елена Сергеевна',    3);

INSERT INTO Doctors (UserID, SpecializationID, Cabinet) VALUES
    (4, 1, N'101'),
    (5, 2, N'205'),
    (6, 3, N'310'),
    (7, 4, N'112');

INSERT INTO Services (Name, SpecializationID, Price) VALUES
    (N'Первичный приём терапевта',  1, 1500.00),
    (N'Повторный приём терапевта',  1, 1000.00),
    (N'Консультация хирурга',       2, 2000.00),
    (N'Перевязка',                  2,  800.00),
    (N'Консультация кардиолога',    3, 2500.00),
    (N'ЭКГ',                        3, 1200.00),
    (N'Проверка остроты зрения',    4, 1300.00),
    (N'Подбор очков',               4, 1800.00);

INSERT INTO Patients (LastName, FirstName, MiddleName, BirthDate, Gender, Phone, PolicyNumber, Address) VALUES
    (N'Петров',    N'Иван',      N'Алексеевич',   '1985-03-12', N'М', N'+79161234501', N'7701000000000001', N'г. Москва, ул. Ленина, д. 5, кв. 12'),
    (N'Смирнова',  N'Екатерина', N'Олеговна',     '1992-07-25', N'Ж', N'+79161234502', N'7701000000000002', N'г. Москва, ул. Садовая, д. 18, кв. 3'),
    (N'Ковалёв',   N'Дмитрий',   N'Сергеевич',    '1978-11-02', N'М', N'+79161234503', N'7701000000000003', N'г. Москва, пр. Мира, д. 40, кв. 77'),
    (N'Новикова',  N'Анна',      NULL,            '2001-01-30', N'Ж', N'+79161234504', NULL,               N'г. Москва, ул. Тверская, д. 9, кв. 4'),
    (N'Фёдоров',   N'Михаил',    N'Иванович',     '1960-05-14', N'М', N'+79161234505', N'7701000000000005', N'г. Москва, ул. Арбат, д. 22, кв. 8'),
    (N'Волкова',   N'Наталья',   N'Петровна',     '1995-09-09', N'Ж', N'+79161234506', N'7701000000000006', NULL),
    (N'Зайцев',    N'Артём',     N'Викторович',   '1988-12-19', N'М', N'+79161234507', NULL,               N'г. Москва, ул. Профсоюзная, д. 61, кв. 15'),
    (N'Павлова',   N'Ольга',     N'Дмитриевна',   '1970-04-03', N'Ж', N'+79161234508', N'7701000000000008', N'г. Москва, ул. Гагарина, д. 3, кв. 50'),
    (N'Семёнов',   N'Николай',   N'Андреевич',    '1955-08-21', N'М', N'+79161234509', N'7701000000000009', N'г. Москва, ул. Пушкина, д. 11, кв. 2'),
    (N'Голубева',  N'Мария',     N'Александровна','2005-06-17', N'Ж', N'+79161234510', NULL,               N'г. Москва, ул. Кирова, д. 7, кв. 31');

DECLARE @today DATETIME2(0) = CAST(CAST(GETDATE() AS DATE) AS DATETIME2(0));

INSERT INTO Appointments (PatientID, DoctorID, ServiceID, AppointmentDateTime, StatusID, Price, IsPaid, CreatedByUserID)
SELECT v.PatientID, v.DoctorID, v.ServiceID,
       DATEADD(MINUTE, v.Minutes, DATEADD(DAY, v.DayOffset, @today)),
       v.StatusID, v.Price, v.IsPaid, v.CreatedBy
FROM (VALUES

    ( 1, 1, 1, -10, 540, 2, 1500.00, 1, 2),
    ( 2, 1, 1, -10, 570, 2, 1500.00, 1, 2),
    ( 3, 2, 3,  -9, 600, 2, 2000.00, 1, 3),
    ( 4, 3, 5,  -8, 660, 2, 2500.00, 1, 2),
    ( 5, 3, 6,  -8, 690, 2, 1200.00, 1, 2),
    ( 1, 1, 2,  -5, 540, 2, 1000.00, 1, 3),
    ( 6, 4, 7,  -4, 600, 2, 1300.00, 1, 2),
    ( 7, 2, 4,  -3, 720, 2,  800.00, 1, 3),
    ( 8, 1, 1,  -3, 540, 4, 1500.00, 0, 2),
    ( 9, 3, 5,  -2, 600, 3, 2500.00, 0, 2),
    ( 4, 1, 1,   0, 600, 1, 1500.00, 0, 2),
    ( 2, 1, 2,   1, 540, 1, 1000.00, 0, 2),
    (10, 2, 3,   1, 600, 1, 2000.00, 0, 3),
    ( 3, 3, 5,   2, 660, 1, 2500.00, 0, 2),
    ( 9, 3, 5,   2, 690, 1, 2500.00, 0, 3),
    ( 5, 4, 8,   3, 540, 1, 1800.00, 0, 2)
) AS v(PatientID, DoctorID, ServiceID, DayOffset, Minutes, StatusID, Price, IsPaid, CreatedBy);

INSERT INTO Visits (AppointmentID, Complaints, Diagnosis, Recommendations, VisitDateTime)
SELECT v.AppointmentID, v.Complaints, v.Diagnosis, v.Recommendations, a.AppointmentDateTime
FROM (VALUES
    (1, N'Кашель, температура 37,5',        N'ОРВИ',                              N'Обильное питьё, постельный режим 5 дней'),
    (2, N'Головная боль, слабость',         N'Вегетососудистая дистония',         N'Режим сна, контроль давления'),
    (3, N'Боль в правом боку',              N'Подозрение на аппендицит исключено', N'УЗИ брюшной полости'),
    (4, N'Боль в груди при нагрузке',       N'Стенокардия напряжения',            N'ЭКГ, консультация через 2 недели'),
    (5, NULL,                               N'ЭКГ без патологий',                 NULL),
    (6, N'Кашель остаточный',               N'ОРВИ, выздоровление',               N'Закрыть больничный'),
    (7, N'Ухудшение зрения вдаль',          N'Миопия слабой степени',             N'Подбор очков'),
    (8, N'Рана на ладони',                  N'Резаная рана, заживление',          N'Перевязка через 3 дня')
) AS v(AppointmentID, Complaints, Diagnosis, Recommendations)
JOIN Appointments a ON a.AppointmentID = v.AppointmentID;
GO

SELECT * FROM vw_AppointmentsFull ORDER BY AppointmentDateTime;
GO