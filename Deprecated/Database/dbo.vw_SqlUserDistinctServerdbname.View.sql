/****** Object:  View [dbo].[vw_SqlUserDistinctServerdbname]    Script Date: 07/09/2008 12:08:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_SqlUserDistinctServerdbname]'))
EXEC dbo.sp_executesql @statement = N'CREATE VIEW [dbo].[vw_SqlUserDistinctServerdbname]
AS
SELECT DISTINCT member, Server + ''.'' + dbname AS Serverdbname
FROM dbo.vw_SqlUserMember'
GO
