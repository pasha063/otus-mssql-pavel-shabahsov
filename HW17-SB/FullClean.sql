
DROP SERVICE [//WWI/SB/TargetService]
GO

DROP SERVICE [//WWI/SB/InitiatorService]
GO

DROP QUEUE [dbo].[TargetQueueWWI]
GO 

DROP QUEUE [dbo].[InitiatorQueueWWI]
GO

DROP CONTRACT [//WWI/SB/Contract]
GO

DROP MESSAGE TYPE [//WWI/SB/RequestMessage]
GO

DROP MESSAGE TYPE [//WWI/SB/ReplyMessage]
GO

USE WideWorldImporters
drop table if exists Sales.OrdersByClientReport
drop procedure if exists Sales.send_report_inquiry_orderByClients 
drop procedure if exists Sales.get_report_orderByClients
drop procedure if exists Sales.confirm_report_orderByClients
