CREATE TABLE [dbo].[Products] (
    [ID]       INT           IDENTITY (1, 1) NOT NULL,
    [Title]    NVARCHAR (50) NOT NULL,
    [Price]    MONEY         NULL,
    [SourceID] NCHAR (1)     NULL,
    CONSTRAINT [PK_Products] PRIMARY KEY CLUSTERED ([ID] ASC)
);

