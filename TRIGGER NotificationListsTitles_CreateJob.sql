
GO
ALTER TRIGGER NotificationListsTitles_CreateJob --version by ViewName
ON NotificationListsTitles
-- Create Jobs based on table (only if IsDaily type)
AFTER INSERT,UPDATE,DELETE AS
BEGIN
	DECLARE
	@ListName VARCHAR(50),
	@ViewName VARCHAR(50),
	@DayCode TINYINT,
	@SchedTime NVARCHAR(6),
	@IsDaily BIT,
	@DelIsDaily BIT,
	@DelViewName VARCHAR(50),

	@Today NVARCHAR(8) = CONVERT(VARCHAR(8),GETDATE(),112),
	@Job_Name VARCHAR(60),
	@DelJob_Name VARCHAR(60),
	@Command VARCHAR(100),
	@database_name NVARCHAR(MAX) = DB_NAME()

	SELECT 
	@ListName = INSERTED.ListName,
	@ViewName = INSERTED.ViewName,
	@DayCode = INSERTED.DayCode,
	@SchedTime = REPLACE(CONVERT(VARCHAR, INSERTED.SchedTime,108),':',''),
	@IsDaily = INSERTED.IsDaily
	FROM INSERTED

	SELECT 
	@DelViewName = DELETED.ViewName,
	@DelIsDaily = DELETED.IsDaily
	FROM DELETED

	SET @Job_Name = 'Email Job: ' + @ViewName
	SET @DelJob_Name = 'Email Job: ' + @DelViewName
	SET @Command = 'EXEC AutoEmailsSend ''' + @ListName + ''''
	IF (@DelIsDaily = 1)
	BEGIN
		-- delete job if exists
		IF EXISTS (SELECT name FROM msdb.dbo.sysjobs_view WHERE name = @DelJob_Name)
			EXEC msdb.dbo.sp_delete_job
				@job_name = @DelJob_Name, 
				@delete_unused_schedule=1;
	END
	IF (@IsDaily = 1 AND @SchedTime IS NOT NULL AND @ViewName IS NOT NULL AND @DayCode > 0)
	BEGIN
		--Add job
		EXEC msdb.dbo.sp_add_job
			@job_name = @Job_Name,
			@description = 'Automated Scheduled Email' ;
		--Add a job step named process step. This step runs the stored procedure
		EXEC msdb.dbo.sp_add_jobstep
			@job_name = @Job_Name,
			@step_name = @ViewName,
			@command = @Command,
			@database_name = @database_name
		--Schedule the job at a specified date and time
		exec msdb.dbo.sp_add_jobschedule 
			@job_name = @Job_Name,
			@name = @SchedTime,
			@freq_type=8,   -- frequency type once 1, daily 4, and weekly 8
			@freq_interval=@DayCode,
			@freq_recurrence_factor=1,
			@active_start_date = @Today,
			@active_start_time = @SchedTime
		-- Add the job to the SQL Server Server
		EXEC msdb.dbo.sp_add_jobserver
			@job_name =  @Job_Name,
			@server_name = @@Servername
		-- Add email when fail
		EXEC msdb.dbo.sp_update_job 
			@job_name =  @Job_Name,
			@notify_level_email=2, 
			@notify_email_operator_name=N'Jon Wilson'
	END
END
