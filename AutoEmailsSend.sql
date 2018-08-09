
ALTER PROC AutoEmailsSend(@ListName NVARCHAR(50)) AS
--  EXEC AutoEmailsSend 'Floor Plans Due'
BEGIN

	DECLARE	@EmailTitle NVARCHAR(100),
			@ALL NVARCHAR(7),
			@GRP NVARCHAR(50), --group
			@DLR NVARCHAR(50), --dealership
			@AddressList NVARCHAR(max),
			@ViewName NVARCHAR(50),
			@ResultsHTML NVARCHAR(MAX),
			@return_status BIT 

	SELECT @ViewName = ViewName, @EmailTitle = EmailTitle
	-- select *
	FROM NotificationListsTitles
	WHERE ListName = @ListName
	IF @@ROWCOUNT = 0 BEGIN PRINT 'Not found in NotificationListsTitles' RETURN 1 END

	DECLARE rowCurs CURSOR FOR 
	SELECT [ALL], GRP, DLR, AddressList FROM dbo.AutoEmailAddresses(@ListName) -- table valued function
	-- SELECT [ALL], GRP, DLR, AddressList FROM dbo.AutoEmailAddresses('Ally Not Floored')
	OPEN rowCurs

	FETCH NEXT FROM rowCurs INTO @ALL, @GRP, @DLR, @AddressList
	WHILE @@FETCH_STATUS = 0  
	BEGIN 	
		-- Get HTML for this email
		     -- print @ViewName print @ALL print @GRP print @DLR print @AddressList print @ListName
		EXECUTE @return_status = AutoEmailHTML @ViewName, @EmailTitle, @ALL, @GRP, @DLR, @AddressList, @ListName, @ResultsHTML OUTPUT
		IF @return_status = 0 --we have data, send email
		BEGIN
			--print @ResultsHTML
			
			SET @AddressList = @AddressList + ';jon.wilson@moo.com'; 
			SET @AddressList = 'jon.wilson@moo.com'; --testing ------<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
		 
			EXEC msdb.dbo.sp_send_dbmail  
				@profile_name = 'sendgrid',  
				--@blind_copy_recipients = @AddressList,
				@recipients = @AddressList,
				@subject = @ListName,
				@body = @ResultsHTML, 
				@body_format = 'HTML';
			
		END
		FETCH NEXT FROM rowCurs INTO @ALL, @GRP, @DLR, @AddressList
	END

	CLOSE rowCurs
	DEALLOCATE rowCurs		
END
go
