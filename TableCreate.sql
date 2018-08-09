
CREATE TABLE [dbo].[NotificationListEmailGroups](
	[ID] [int] IDENTITY(101,1) NOT NULL,
	[ListName] [varchar](50) NOT NULL,
	[JobTitle] [varchar](255) NOT NULL,
 CONSTRAINT [PK_NotificationListEmailGroups] PRIMARY KEY NONCLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[NotificationListsTitles](
	[ID] [int] IDENTITY(101,1) NOT NULL,
	[ListName] [varchar](50) NOT NULL,
	[EmailTitle] [varchar](100) NULL,
	[ViewName] [varchar](50) NULL,
	[StoredProcedure] [varchar](50) NULL,
	[ScheduleDescription] [varchar](1000) NULL,
	[IsDaily] [bit] NULL,
	[Sunday] [bit] NULL,
	[Monday] [bit] NULL,
	[Tuesday] [bit] NULL,
	[Wednesday] [bit] NULL,
	[Thursday] [bit] NULL,
	[Friday] [bit] NULL,
	[Saturday] [bit] NULL,
	[DayCode]  AS (((((([Sunday]*(1)+[Monday]*(2))+[Tuesday]*(4))+[Wednesday]*(8))+[Thursday]*(16))+[Friday]*(32))+[Saturday]*(64)),
	[SchedTime] [time](0) NULL,
 CONSTRAINT [PK_NotificationListsTitles] PRIMARY KEY NONCLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[NotificationListsTitles] ADD  CONSTRAINT [DF_NotificationListsTitles_Sunday]  DEFAULT ((0)) FOR [Sunday]
GO

ALTER TABLE [dbo].[NotificationListsTitles] ADD  CONSTRAINT [DF_NotificationListsTitles_Monday]  DEFAULT ((0)) FOR [Monday]
GO

ALTER TABLE [dbo].[NotificationListsTitles] ADD  CONSTRAINT [DF_NotificationListsTitles_Tuesday]  DEFAULT ((0)) FOR [Tuesday]
GO

ALTER TABLE [dbo].[NotificationListsTitles] ADD  CONSTRAINT [DF_NotificationListsTitles_Wednesday]  DEFAULT ((0)) FOR [Wednesday]
GO

ALTER TABLE [dbo].[NotificationListsTitles] ADD  CONSTRAINT [DF_NotificationListsTitles_Thursday]  DEFAULT ((0)) FOR [Thursday]
GO

ALTER TABLE [dbo].[NotificationListsTitles] ADD  CONSTRAINT [DF_NotificationListsTitles_Friday]  DEFAULT ((0)) FOR [Friday]
GO

ALTER TABLE [dbo].[NotificationListsTitles] ADD  CONSTRAINT [DF_NotificationListsTitles_Saturday]  DEFAULT ((0)) FOR [Saturday]
GO


