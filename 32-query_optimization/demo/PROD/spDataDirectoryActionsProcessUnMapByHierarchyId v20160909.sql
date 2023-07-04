SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- =============================================
ALTER PROCEDURE [dbo].[spFolderActionsProcessUnMapByDirId] @DirId INT
	,@debug BIT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @deleteBatchSize INT = 4999
			,@rowCount INT
			,@selectBatchSize INT = 50000
			,@deleteRowCount INT;

	-- exit if HID is already processing
	IF EXISTS (
			SELECT 1
			FROM dbo.FolderAction
			WHERE [DirId] = @DirId
				AND StatusId = 2 /* In progress */
				AND ActionTypeId IN (
					3 /* Unmap directory */
					,5 /* Unmap directories (root directory)*/
					,6 /* Unmap inactive directories (root directory)*/
					)
				AND DateStartedUtc > DATEADD(SECOND, - 60, GETUTCDATE()) -- should be adjusted according with SP timeout
			)
		RETURN;

	CREATE TABLE #actions (
		[FolderActionId] [BIGINT] NOT NULL
		,[DirId] [int] NOT NULL			
		);
	
	CREATE CLUSTERED INDEX IX_Actions_DirId_DirId_ActionTypeId ON #actions (
		[DirId]
	);

	CREATE TABLE #DataFileMachineToDelete 
		(
		[DirId]	INT,
		MachineId		INT,
		DataFileId		INT
		);

	CREATE CLUSTERED INDEX IX_DataFileMachineToDelete ON #DataFileMachineToDelete (MachineId,[DirId],DataFileId);

	CREATE TABLE #FolderMachineToDelete
		(
		MachineId		INT,
		[DirId]	INT,
		DirId			INT,	
		);

	CREATE CLUSTERED INDEX IX_FolderMachine ON #FolderMachineToDelete	(MachineId,[DirId],DirId);

	UPDATE dbo.FolderAction
	SET StatusId = 2 /*In progress*/
		,DateStartedUtc = GETUTCDATE()
	OUTPUT INSERTED.FolderActionId
		,INSERTED.[DirId]				
	INTO #actions
	WHERE [DirId] = @DirId
		AND ActionTypeId IN (
			3 /* Unmap directory */
			,5 /* Unmap directories (root directory)*/
			,6 /* Unmap inactive directories (root directory)*/
			)
		AND StatusId IN (
			1 /*Pending*/
			,3 /*Error*/
			,2 /*In progress*/
			);

	SET @rowCount = @@ROWCOUNT;

	IF (@debug = 1)
		PRINT 'Number of actions to process: ' + CONVERT(VARCHAR(10), @rowCount);

	IF (@rowCount = 0)
		RETURN;

	BEGIN TRY
		CREATE TABLE #vfMachine (
			DataSourceId INT
			,[DirId] INT
			,MappingVersionId INT
			);

		CREATE TABLE #childDirectories (
			[DirId] INT		
			,DataSourceId INT
			,PRIMARY KEY (
				[DirId]
				,DirId
				,DataSourceId
				) WITH (IGNORE_DUP_KEY = ON)
			);

		-- fill child directories for action
		WITH CTE
		AS (
			SELECT DISTINCT R.[DirId]
				,R.DirId
				,A.DataSourceId
			FROM dbo.Folder R
			INNER JOIN #actions A ON A.[DirId] = R.[DirId]
				AND A.DirId = R.DirId
			WHERE A.ActionTypeId IN (
					5 /* Unmap directories (root directory) */
					,6 /* Unmap inactive directories (root directory) */
					)
			
			UNION ALL
			
			SELECT D.[DirId]
				,D.DirId
				,CTE.DataSourceId
			FROM dbo.Folder D
			INNER JOIN CTE ON CTE.[DirId] = D.[DirId]
				AND CTE.DirId = D.ParentDirId
			WHERE NOT EXISTS (
					SELECT 1
					FROM #actions A
					WHERE A.[DirId] = D.[DirId]
						AND A.DirId = D.DirId
						AND A.DataSourceId = CTE.DataSourceId
						AND A.ActionTypeId IN (
							5 /* Unmap directories (root directory) */
							,6 /* Unmap inactive directories (root directory) */
							)
					)
			)
		INSERT INTO #childDirectories (
			[DirId]		
			,DataSourceId
			)
		SELECT CTE.[DirId]
			,CTE.DataSourceId
		FROM CTE;

		-- append unmap single directory action
		INSERT INTO #childDirectories (
			[DirId]
			,DataSourceId
			)
		SELECT A.[DirId]
			,A.DataSourceId
		FROM #actions A
		INNER JOIN dbo.Folder DD ON (
				A.[DirId] = DD.[DirId]
				)
		WHERE A.ActionTypeId = 3 /* Unmap directory */;

		-- purge dbo.FolderMachine
		SET @rowCount = @selectBatchSize;

		WHILE @rowCount = @selectBatchSize
		BEGIN
			TRUNCATE TABLE #FolderMachineToDelete;

			INSERT INTO #FolderMachineToDelete
			(
				[DirId]
				,MachineId
			)
			SELECT TOP (@selectBatchSize) 
				DDM.[DirId]
				,DDM.MachineId
			FROM dbo.FolderMachine DDM
				INNER JOIN #childDirectories DD ON (
					DDM.[DirId] = DD.[DirId]
					AND DDM.MachineId = DD.DataSourceId
					)
			WHERE DDM.[DirId] = @DirId
				AND NOT EXISTS (
					SELECT 1
					FROM dbo.vwFolderMachine VDDM
					WHERE VDDM.[DirId] = DDM.[DirId]
						AND VDDM.MachineId = DDM.MachineId
					)
			OPTION (OPTIMIZE FOR (@DirId = 1));					
			SET @rowCount = @@ROWCOUNT;

			SET @deleteRowCount = @deleteBatchSize
			WHILE @deleteRowCount = @deleteBatchSize
			BEGIN
				DELETE TOP (@deleteBatchSize) FROM DDM
				FROM dbo.FolderMachine DDM
				WHERE EXISTS (SELECT 1 
					FROM #FolderMachineToDelete AS DDMD 
					WHERE DDM.[DirId] = DDMD.[DirId] 
						AND DDM.MachineId = DDMD.MachineId);

				SET @deleteRowCount = @@ROWCOUNT;
			END
			

			IF (@debug = 1)
				PRINT 'DELETE FROM dbo.FolderMachine : ' + CONVERT(VARCHAR(10), @rowCount);
		END


		UPDATE DDA
		SET StatusId = 4 /*Done*/
			,DateCompleted = GETUTCDATE()
		FROM dbo.FolderAction DDA
		INNER JOIN #actions A ON (A.FolderActionId = DDA.FolderActionId);
	END TRY

	BEGIN CATCH
		UPDATE DDA
		SET StatusId = 3 /*Error*/
			,DateCompleted = GETUTCDATE()
		FROM dbo.FolderAction DDA
		INNER JOIN #actions A ON (A.FolderActionId = DDA.FolderActionId);
	END CATCH
END
GO