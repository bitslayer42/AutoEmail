
ALTER PROC AutoEmailHTML(@ViewName NVARCHAR(50),@EmailTitle NVARCHAR(100),@ALL bit,@GRP NVARCHAR(50),@DLR NVARCHAR(50), 
							@AddressList NVARCHAR(MAX), @ListName NVARCHAR(50), @ResultsHTML NVARCHAR(MAX) OUTPUT)  AS
-- Builds HTML from view for the email - By Group or Dealership
BEGIN /*
DECLARE @ResultsHTML NVARCHAR(MAX),
		@RetVal BIT

EXEC @RetVal = AutoEmailHTML @ViewName = 'vEmailFloorPlansPaid',
					@EmailTitle = 'This is the title',
					@ALL = 1,
					@GRP = NULL,
					@DLR = NULL,
					@AddressList= 'jon.wilson@autostarusa.com',
					@ListName= 'email',
					@ResultsHTML = @ResultsHTML OUTPUT
SELECT @RetVal
SELECT @ResultsHTML 
*/ 
	DECLARE @FormatView NVARCHAR(100) = @ViewName + 'Format'

	DECLARE @AggregateSQL AS NVARCHAR(MAX) = ''
	DECLARE @HeaderRow NVARCHAR(MAX) = ''

	DECLARE @ColName AS NVARCHAR(255)
	DECLARE @Aggregate NVARCHAR(4)  
	DECLARE @tblCols TABLE (ColName NVARCHAR(255),Aggregate NVARCHAR(4))

	DECLARE @tblHTML TABLE (SEC NVARCHAR(50), GRP NVARCHAR(100), DLR NVARCHAR(100), RowsHTML NVARCHAR(MAX), IsTot AS IIF(SEC='Detail',0,1))
	DECLARE @RowsHTML NVARCHAR(MAX)

	DECLARE @OddEven BIT = 0    --background colors
	DECLARE @IsTot BIT = 0
	DECLARE @SQLWhere NVARCHAR(MAX) = ''

	DECLARE @HasGRPCol BIT = 0  --some reports don't have dealership group column
	DECLARE @HasDLRCol BIT = 0  --some reports don't have dealership column

	DECLARE @NoDlrTot BIT = 0   --reports without total rows
	DECLARE @NoGrpTot BIT = 0
	DECLARE @NoRptTot BIT = 0
	DECLARE @ReportHasTotals BIT = 0  --has at least one aggregate

	DECLARE @OrderByCols NVARCHAR(MAX) = ''

	DECLARE ColCURS CURSOR STATIC FOR 
	SELECT COLUMN_NAME 
	FROM INFORMATION_SCHEMA.COLUMNS 
	WHERE TABLE_NAME = @FormatView
	ORDER BY ORDINAL_POSITION 
	OPEN ColCURS
	FETCH NEXT FROM ColCURS INTO @ColName
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @ColName = 'GRP' SET @HasGRPCol = 1
		IF @ColName = 'DLR' SET @HasDLRCol = 1
		SET @AggregateSQL = @AggregateSQL + 'SELECT ''' + @ColName + ''', CONVERT(NVARCHAR(MAX),[' + @ColName + '])  FROM ' 
			+ @FormatView + ' UNION ALL ' 
		FETCH NEXT FROM ColCURS INTO @ColName
	END
	CLOSE ColCURS
	DEALLOCATE ColCURS 	
	
	IF @AggregateSQL = ''
	BEGIN --No Format File, just use main view for columns

		DECLARE ColCURS2 CURSOR FOR 
		SELECT COLUMN_NAME 
		FROM INFORMATION_SCHEMA.COLUMNS 
		WHERE TABLE_NAME = @ViewName
		ORDER BY ORDINAL_POSITION 	

		OPEN ColCURS2
		FETCH NEXT FROM ColCURS2 INTO @ColName
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF @ColName = 'GRP' SET @HasGRPCol = 1
			IF @ColName = 'DLR' SET @HasDLRCol = 1
			SET @AggregateSQL = @AggregateSQL + 'SELECT ''' + @ColName + ''', NULL UNION ALL ' 
			FETCH NEXT FROM ColCURS2 INTO @ColName
		END
		CLOSE ColCURS2
		DEALLOCATE ColCURS2 
	END

	SET @AggregateSQL = LEFT(@AggregateSQL, LEN(@AggregateSQL)-10)

	-- print(@AggregateSQL) return
	
	INSERT INTO @tblCols
	EXEC(@AggregateSQL) 
	-------@tblCols-------
	--ColName--Aggregate--
	-------------------------------------------------------------------
	DECLARE @DetailSQL AS NVARCHAR(MAX)    =       'SELECT ''Detail'' AS SEC,' + IIF(@HasGRPCol = 0,'1 AS GRP,',' GRP,')+ IIF(@HasDLRCol = 0,'1 AS DLR,',' DLR,') 
	DECLARE @SubDealerSQL AS NVARCHAR(MAX) = ' UNION SELECT ''SubDealer'' AS SEC,' + IIF(@HasGRPCol = 0,'1 AS GRP,',' GRP,')+ IIF(@HasDLRCol = 0,'1 AS DLR,',' DLR,')
	DECLARE @SubGroupSQL AS NVARCHAR(MAX)  = ' UNION SELECT ''SubGroup'' AS SEC,' + IIF(@HasGRPCol = 0,'1 AS GRP,',' GRP,')+ ' ''zzz'' AS DLR,'
	DECLARE @TotalSQL AS NVARCHAR(MAX)     = ' UNION SELECT ''Total'' AS SEC, ''zzz'' AS GRP, ''zzz'' AS DLR,'
	DECLARE @FinalSQL AS NVARCHAR(MAX)

	DECLARE ColCURS2 CURSOR FOR 
	SELECT * FROM @tblCols

	OPEN ColCURS2
	FETCH NEXT FROM ColCURS2 INTO @ColName,@Aggregate
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @HeaderRow = @HeaderRow + '<th>' + IIF(@ColName='DLR','Dealership',IIF(@ColName='GRP','Group',RTRIM(ISNULL(CAST (@ColName AS NVARCHAR(MAX)),'')))) + '</th>'
		SET @DetailSQL = @DetailSQL + '''<td>'' + RTRIM(ISNULL(CONVERT(NVARCHAR(MAX),[' + @ColName + '],0),'''')) + ''</td>'' + ' 
		IF @Aggregate = 'ASC'  --Order by
		BEGIN
			SET @OrderByCols = @OrderByCols + '[' + @ColName + ']' + ','
		END
		IF @Aggregate = 'DESC' --Order by desc
		BEGIN
			SET @OrderByCols = @OrderByCols + '[' + @ColName + ']' + ' DESC,'
		END
		IF @Aggregate = 'SUM'
		BEGIN
			SET @SubGroupSQL = @SubGroupSQL + '''<td>'' + ISNULL(CONVERT(NVARCHAR(10),SUM(CONVERT(INT,ROUND([' + @ColName + '],0)))),'''') + ''</td>'' + '
			SET @SubDealerSQL = @SubDealerSQL + '''<td>'' + ISNULL(CONVERT(NVARCHAR(10),SUM(CONVERT(INT,ROUND([' + @ColName + '],0)))),'''') + ''</td>'' + '
			SET @TotalSQL = @TotalSQL + '''<td>'' + ISNULL(CONVERT(NVARCHAR(10),SUM(CONVERT(INT,ROUND([' + @ColName + '],0)))),'''') + ''</td>'' + '
			SET @ReportHasTotals = 1
		END
		ELSE IF @Aggregate = 'AVG'
		BEGIN
			SET @SubGroupSQL = @SubGroupSQL + '''<td>'' + ISNULL(CONVERT(NVARCHAR(10),AVG(CONVERT(INT,ROUND([' + @ColName + '],0)))),'''') + ''</td>'' + '
			SET @SubDealerSQL = @SubDealerSQL + '''<td>'' + ISNULL(CONVERT(NVARCHAR(10),AVG(CONVERT(INT,ROUND([' + @ColName + '],0)))),'''') + ''</td>'' + '
			SET @TotalSQL = @TotalSQL + '''<td>'' + ISNULL(CONVERT(NVARCHAR(10),AVG(CONVERT(INT,ROUND([' + @ColName + '],0)))),'''') + ''</td>'' + '
			SET @ReportHasTotals = 1
		END
		ELSE IF @Aggregate = 'CNT'
		BEGIN
			SET @SubGroupSQL = @SubGroupSQL + '''<td>'' + ISNULL(CONVERT(NVARCHAR(10),COUNT(*)),'''') + ''</td>'' + '
			SET @SubDealerSQL = @SubDealerSQL + '''<td>'' + ISNULL(CONVERT(NVARCHAR(10),COUNT(*)),'''') + ''</td>'' + '
			SET @TotalSQL = @TotalSQL + '''<td>'' + ISNULL(CONVERT(NVARCHAR(10),COUNT(*)),'''') + ''</td>'' + '
			SET @ReportHasTotals = 1
		END
		ELSE IF @ColName = 'GRP' 
		BEGIN
			SET @SubGroupSQL = @SubGroupSQL + '''<td>'' + RTRIM(GRP) + '' Total'' + ''</td>'' + '
			SET @SubDealerSQL = @SubDealerSQL + '''<td>'' + ''</td>'' + '
			SET @TotalSQL = @TotalSQL + '''<td>'' + ''</td>'' + '
		END
		ELSE IF @ColName = 'DLR' 
		BEGIN
			SET @SubGroupSQL = @SubGroupSQL + '''<td>'' + ''</td>'' + '
			SET @SubDealerSQL = @SubDealerSQL + '''<td>'' + RTRIM(DLR) + '' Total'' + ''</td>'' + '
			SET @TotalSQL = @TotalSQL + '''<td>'' + ''Report Total'' + ''</td>'' + '
		END
		ELSE IF (@Aggregate IS NULL OR @Aggregate = 'ASC' OR @Aggregate = 'DESC') -- how would this work for ASC SUM?
		BEGIN
			SET @SubGroupSQL = @SubGroupSQL + '''<td>'' + ''</td>'' + '
			SET @SubDealerSQL = @SubDealerSQL + '''<td>'' + ''</td>'' + '	
			SET @TotalSQL = @TotalSQL + '''<td>'' + ''</td>'' + '	
		END

		FETCH NEXT FROM ColCURS2 INTO @ColName,@Aggregate
	END
	CLOSE ColCURS2
	DEALLOCATE ColCURS2

	-- Append optional filters on Group and Dealership
	IF @ALL <> 1 AND @GRP IS NOT NULL 
	BEGIN
		SET @SQLWhere = @SQLWhere + ' WHERE GRP = ''' + @GRP + '''' 
		SET @NoRptTot = 1
	END
	ELSE 
	IF @ALL <> 1 AND @DLR IS NOT NULL 
	BEGIN
		SET @SQLWhere = @SQLWhere + ' WHERE DLR = ''' + @DLR + ''''
		SET @NoGrpTot = 1
		SET @NoRptTot = 1
	END

	--Report doesn't need total rows
	IF @ReportHasTotals = 0
	BEGIN
		SET @NoDlrTot = 1
		SET @NoGrpTot = 1
		SET @NoRptTot = 1
	END

	SET @DetailSQL = LEFT(@DetailSQL, LEN(@DetailSQL)-1) + ' AS HTML FROM ' + @ViewName + @SQLWhere

	EXEC(@DetailSQL) --count detail rows
	IF @@ROWCOUNT = 0 RETURN 1 -- if no data return a 1 "don't send"

	SET @SubGroupSQL = LEFT(@SubGroupSQL, LEN(@SubGroupSQL)-1) + ' FROM ' + @ViewName + @SQLWhere + ' GROUP BY GRP'
	SET @SubDealerSQL = LEFT(@SubDealerSQL, LEN(@SubDealerSQL)-1) + ' FROM ' + @ViewName + @SQLWhere + ' GROUP BY GRP,DLR'
	SET @TotalSQL = LEFT(@TotalSQL, LEN(@TotalSQL)-1) + ' FROM ' + @ViewName + @SQLWhere

	SET @FinalSQL = @DetailSQL + IIF(@NoGrpTot = 1,'',@SubGroupSQL) + IIF(@NoDlrTot = 1,'',@SubDealerSQL) + IIF(@NoRptTot=1,'',@TotalSQL) 
		+ ' ORDER BY ' + @OrderByCols + 'GRP,DLR,SEC'

		--SELECT @FinalSQL return

	INSERT INTO @tblHTML(SEC,GRP,DLR,RowsHTML)
	EXEC(@FinalSQL)
	--select * from @tblHTML

	-------------------------------------------------------------------------------------------
	
	SET @ResultsHTML =  
	'<html>
	<body><h2>' + @EmailTitle + ' ' + CONVERT(NVARCHAR(10),GETDATE(),101) + '</h2>
	<table style="border:1px solid grey;font-size:14px;"><tr style="background-color: #5D7B9D; color: white;">'
	+ @HeaderRow + '</tr>'

	DECLARE ResultCurs CURSOR FOR
	SELECT RowsHTML,IsTot
	FROM @tblHTML

	OPEN ResultCurs

	FETCH NEXT FROM ResultCurs INTO @RowsHTML,@IsTot
	WHILE @@FETCH_STATUS = 0  
	BEGIN 
		IF @IsTot = 1
			SET @ResultsHTML = @ResultsHTML + '<tr style="background-color: #ccc;font-weight:bold;">' + REPLACE(@RowsHTML,'zzz','Total') + '</tr>'
		ELSE
		IF @OddEven = 0
			SET @ResultsHTML = @ResultsHTML + '<tr style="background-color: #f1f4f7;">' + @RowsHTML + '</tr>'
		ELSE
			SET @ResultsHTML = @ResultsHTML + '<tr style="background-color: #e6ebf0; ">' + @RowsHTML + '</tr>'
		SET @OddEven = ~ @OddEven

		FETCH NEXT FROM ResultCurs INTO @RowsHTML,@IsTot
	END
			
	CLOSE ResultCurs
	DEALLOCATE ResultCurs

	SET @ResultsHTML = @ResultsHTML
	+ '</table><p style="font-size:12px;color: #C5C9CC;">This is an automated email from AutoCrossPro.com. Please do not reply.</p>'
	+ IIF(@ALL=1,'Sent to','') + ISNULL(@GRP,'') + ISNULL(@DLR,'') + ':' + @AddressList
	+ '</body></html>'

	RETURN 0
END


