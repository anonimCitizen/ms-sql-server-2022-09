
--DBBCC commands
DBCC CHECKDB ('WideWorldImporters') ;
DBCC CHECKFILEGROUP ;
DBCC CHECKTABLE('Application.People');
DBCC CHECKALLOC ;
DBCC CHECKCATALOG;

-- Built-in Functions 
SELECT @@CPU_BUSY * CAST(@@TIMETICKS AS float) AS 'CPU microseconds',   
   GETDATE() AS 'As of' ;  

SELECT GETDATE() AS 'Today''s Date and Time',   
@@CONNECTIONS AS 'Login Attempts';  

SELECT @@IO_BUSY*@@TIMETICKS AS 'IO microseconds',   
   GETDATE() AS 'as of';

SELECT @@TOTAL_READ AS 'Reads', @@TOTAL_WRITE AS 'Writes', GETDATE() AS 'As of';  

-- Database Engine Tuning Advisor
use WideWorldImporters;

-- генерируем активность для мониторинга workload.sql


--Extended Events
  CREATE EVENT SESSION [tutorial_session]
    ON SERVER 
    ADD EVENT sqlserver.sql_statement_completed -- событие которое будем мониторить
    (
        ACTION(sqlserver.sql_text)
        WHERE
        ( [sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text], N'%SELECT%HAVING%')
        )
    )
    ADD TARGET package0.event_file -- куда будут сохраняться результаты
    (SET
        filename = N'C:\D\tutorial_session.xel',
        max_file_size = (2),
        max_rollover_files = (2)
    )
    WITH ( -- опции для анализа
        MAX_MEMORY = 2048 KB,
        EVENT_RETENTION_MODE = ALLOW_MULTIPLE_EVENT_LOSS,
        MAX_DISPATCH_LATENCY = 3 SECONDS,
        MAX_EVENT_SIZE = 0 KB,
        MEMORY_PARTITION_MODE = NONE,
        TRACK_CAUSALITY = OFF,
        STARTUP_STATE = OFF
    );
GO

--управление EVENT SESSION
ALTER EVENT SESSION [tutorial_session]
      ON SERVER
    STATE = START;   

-- extended events запускаем запрос sql для последующего анализа
SELECT
        c.name,
        Count(*)  AS [Count-Per-Column-Repeated-Name]
    FROM
             sys.syscolumns  AS c
        JOIN sys.sysobjects  AS o
    
            ON o.id = c.id
    WHERE
        o.type = 'V'
        AND
        c.name like '%event%'
    GROUP BY
        c.name
    HAVING
        Count(*) >= 3   --2     -- Try both values during session.
    ORDER BY
        c.name;
 
--получение результатов
SELECT
        object_name,
        file_name,
        file_offset,
        event_data,
        'CLICK_NEXT_CELL_TO_BROWSE_XML RESULTS!'
                AS [CLICK_NEXT_CELL_TO_BROWSE_XML_RESULTS],
    
        CAST(event_data AS XML) AS [event_data_XML]
        
    FROM
        sys.fn_xe_file_target_read_file(
            'C:\D\ExtendedEvents\workload_0_133002242406090000.xel', --C:\D\ .xel 
            null, null, null
        );



--extended events drop
IF EXISTS (SELECT *
      FROM sys.server_event_sessions    -- If Microsoft SQL Server.
      WHERE name = 'tutorial_session')
BEGIN
    DROP EVENT SESSION YourSession
          ON SERVER;    -- If Microsoft SQL Server.
END
go



--DMV
--sys.dm_exec_sessions
--поиск пользователей, подключенных к серверу

SELECT login_name ,COUNT(session_id) AS session_count   
FROM sys.dm_exec_sessions   
GROUP BY login_name; 

--курсоры, которые были открыты более определенного периода времени
USE master;  
GO  
SELECT creation_time ,cursor_id   
    ,name ,c.session_id ,login_name   
FROM sys.dm_exec_cursors(0) AS c   
JOIN sys.dm_exec_sessions AS s   
   ON c.session_id = s.session_id   
WHERE DATEDIFF(mi, c.creation_time, GETDATE()) > 5

--поиск сеансов с открытыми транзакциями и бездействием
SELECT s.*   
FROM sys.dm_exec_sessions AS s  
WHERE EXISTS   
    (  
    SELECT *   
    FROM sys.dm_tran_session_transactions AS t  
    WHERE t.session_id = s.session_id  
    )  
    AND NOT EXISTS   
    (  
    SELECT *   
    FROM sys.dm_exec_requests AS r  
    WHERE r.session_id = s.session_id  
    );

--сбора информации о запросах собственного соединения
 SELECT   
    c.session_id, c.net_transport, c.encrypt_option,   
    c.auth_scheme, s.host_name, s.program_name,   
    s.client_interface_name, s.login_name, s.nt_domain,   
    s.nt_user_name, s.original_login_name, c.connect_time,   
    s.login_time   
FROM sys.dm_exec_connections AS c  
JOIN sys.dm_exec_sessions AS s  
    ON c.session_id = s.session_id  
WHERE c.session_id = @@SPID;  

--live query stats
use WideWorldImporters;

select * from Application.People;

--Query Store.enable
ALTER DATABASE WideWorldImporters SET QUERY_STORE (OPERATION_MODE = READ_WRITE); 

--информация о запросах и планах в хранилище запросов
SELECT Txt.query_text_id, Txt.query_sql_text, Pl.plan_id, Qry.*  
FROM sys.query_store_plan AS Pl  
INNER JOIN sys.query_store_query AS Qry  
    ON Pl.query_id = Qry.query_id  
INNER JOIN sys.query_store_query_text AS Txt  
    ON Qry.query_text_id = Txt.query_text_id ; 

-- QuieryStore.sql




--UNION vs Union ALL тест кейс из реальной оптимизации

select 1 as 'col1',2 as 'col2',3 as 'col3'
union all
select 1 as 'col1',2 as 'col2', 3 as 'col3'

use [AdventureWorks2012];


SELECT * FROM HumanResources.Employee
UNION ALL
SELECT * FROM HumanResources.Employee
UNION ALL
SELECT * FROM HumanResources.Employee


SELECT * FROM HumanResources.Employee
UNION
SELECT * FROM HumanResources.Employee
UNION
SELECT * FROM HumanResources.Employee


