--�������� ������
USE master
ALTER DATABASE WideWorldImporters
SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE; 

--�� ������ ��������������� �� ����� ����������� ������!!!
ALTER AUTHORIZATION    
   ON DATABASE::WideWorldImporters TO [sa];

ALTER DATABASE WideWorldImporters SET TRUSTWORTHY ON;

--������� ���� ���������
USE WideWorldImporters

drop table if exists Sales.OrdersByClientReport
drop procedure if exists Sales.send_report_inquiry_orderByClients 
drop procedure if exists Sales.get_report_orderByClients
drop procedure if exists Sales.confirm_report_orderByClients

CREATE MESSAGE TYPE
[//WWI/SB/RequestMessage]
VALIDATION=WELL_FORMED_XML;

CREATE MESSAGE TYPE
[//WWI/SB/ReplyMessage]
VALIDATION=WELL_FORMED_XML;

CREATE CONTRACT [//WWI/SB/Contract]
      ([//WWI/SB/RequestMessage]
         SENT BY INITIATOR,
       [//WWI/SB/ReplyMessage]
         SENT BY TARGET
      );

--������� ������� �������(������� ����� �.�. ����� ALTER ����� �� ������ ���
CREATE QUEUE TargetQueueWWI;
--� ������ �������
CREATE SERVICE [//WWI/SB/TargetService]
       ON QUEUE TargetQueueWWI
       ([//WWI/SB/Contract]);

--�� �� ��� ����������
CREATE QUEUE InitiatorQueueWWI;

CREATE SERVICE [//WWI/SB/InitiatorService]
       ON QUEUE InitiatorQueueWWI
       ([//WWI/SB/Contract]);
go

-- ������� ������� ��� ������ ������
create table Sales.OrdersByClientReport (
	InquiryID varchar(50)
	,CustomerID int not null
	,LastYearOrdersQuantity int not null
	,DateInsert datetime not null default getdate()
)
go

-- ������� ��������� ��� �������� ������
create procedure sales.send_report_inquiry_orderByClients 
as
begin
	SET NOCOUNT ON;

    --Sending a Request Message to the Target	
	DECLARE @InitDlgHandle UNIQUEIDENTIFIER;
	DECLARE @InquiryID UNIQUEIDENTIFIER = newID();
	DECLARE @RequestMessage NVARCHAR(4000);
	
	BEGIN TRAN --�� ������ ������ � ����������, �.�. ��� ��� �� ��������� � ���������� �������� ���������

		--��������� XML � ������ RequestMessage ��� ��������� ����� �������(� �������� ��������� ����� ���� �����)
		SELECT @RequestMessage = N'<RequestMessage> ' + cast(@InquiryID as nvarchar(100)) + ' </RequestMessage>'

		--������� ������
		BEGIN DIALOG @InitDlgHandle
		FROM SERVICE
		[//WWI/SB/InitiatorService] --�� ����� �������(��� ������ ������� ��, ������� �� �� ������)
		TO SERVICE
		'//WWI/SB/TargetService'    --� ����� �������(��� ������ ������� ����� ���� ���-��, ������� ������)
		ON CONTRACT
		[//WWI/SB/Contract]         --� ������ ����� ���������
		WITH ENCRYPTION=OFF;        --�� �����������

		--���������� ���� ���� �������������� ���������, �� ����� ��������� � ����� ���������, ������� ����� �������������� ������ ���������������)
		SEND ON CONVERSATION @InitDlgHandle 
		MESSAGE TYPE
		[//WWI/SB/RequestMessage]
		(@RequestMessage);
	COMMIT TRAN 
end
go

-- ������� ������������� ��������� ��������� ������
create procedure Sales.get_report_orderByClients --����� �������� ��������� �� �������
AS
BEGIN

	DECLARE @TargetDlgHandle UNIQUEIDENTIFIER,
			@Message NVARCHAR(4000),
			@MessageType Sysname,
			@ReplyMessage NVARCHAR(4000),
			@ReplyMessageName Sysname,
			@InquiryID varchar(50),
			@xml XML; 
	
	BEGIN TRAN; 
		--�������� ��������� �� ���������� ������� ��������� � �������
		RECEIVE TOP(1) --������ ���� ���������, �� ����� ������
			@TargetDlgHandle = Conversation_Handle, --�� �������
			@Message = Message_Body, --���� ���������
			@MessageType = Message_Type_Name --��� ���������( � ����������� �� ���� ����� �� ������� ������������) ������ ��� - ������ � �����
		FROM dbo.TargetQueueWWI; --��� ������� ������� �� ����� ���������

		SET @xml = CAST(@Message AS XML);
		--������� InquiryID
		SELECT @InquiryID = @xml.value('(/RequestMessage)[1]', 'varchar(50)') 

		if @InquiryID is not null
			begin
				insert into Sales.OrdersByClientReport(InquiryID, CustomerID, LastYearOrdersQuantity)
				select
					@InquiryID
					,CustomerID
					,count(OrderID) as OrderCount
				from Sales.Invoices
				where year(InvoiceDate) = (select max(year(InvoiceDate)) from Sales.Invoices)
				group by CustomerID
			end
	
		-- Confirm and Send a reply
		IF @MessageType=N'//WWI/SB/RequestMessage' --���� ��� ��� ���������
		BEGIN
			SET @ReplyMessage =N'<ReplyMessage> Message received</ReplyMessage>'; --�����
			--���������� ��������� ���� �����������, ��� ��� ������ ������
			SEND ON CONVERSATION @TargetDlgHandle
			MESSAGE TYPE
			[//WWI/SB/ReplyMessage]
			(@ReplyMessage);
			END CONVERSATION @TargetDlgHandle; --� ��� � ���������� �������!!! - ��� �������������(����-����) ��� ������ ����
											   --������ ��������� ������ �� �������� ������� ���������
		END 
	COMMIT TRAN;
END
go

-- ������� ������������� ��������� �������� �������
create procedure Sales.confirm_report_orderByClients
AS
BEGIN
	--Receiving Reply Message from the Target.	
	DECLARE @InitiatorReplyDlgHandle UNIQUEIDENTIFIER,
			@ReplyReceivedMessage NVARCHAR(1000) 
	
	BEGIN TRAN; 

	    --�������� ��������� �� ������� ������� ��������� � ����������
		RECEIVE TOP(1)
			@InitiatorReplyDlgHandle=Conversation_Handle
			,@ReplyReceivedMessage=Message_Body
		FROM dbo.InitiatorQueueWWI; 
		
		END CONVERSATION @InitiatorReplyDlgHandle; --��� ������ ����
		
	COMMIT TRAN; 
END

ALTER QUEUE [dbo].[InitiatorQueueWWI] WITH STATUS = ON --OFF=������� �� ��������(������ ���� ���������� ��������)
                                          ,RETENTION = OFF --ON=��� ����������� ��������� �������� � ������� �� ��������� �������
										  ,POISON_MESSAGE_HANDLING (STATUS = OFF) --ON=����� 5 ������ ������� ����� ���������
	                                      ,ACTIVATION (STATUS = ON --OFF=������� �� ���������� ��(� PROCEDURE_NAME)(������ �� ����� ����������� ��, �� � ������� ���������)  
										              ,PROCEDURE_NAME = Sales.confirm_report_orderByClients
													  ,MAX_QUEUE_READERS = 1 --���������� �������(�� ������������ ���������) ��� ��������� ���������(0-32767)
													                         --(0=���� �� ��������� ���������)(������ �� ����� ����������� ��, ��� ������ ���������) 
													  ,EXECUTE AS OWNER --������ �� ����� ������� ���������� ��
													  ) 

GO
ALTER QUEUE [dbo].[TargetQueueWWI] WITH STATUS = ON 
                                       ,RETENTION = OFF 
									   ,POISON_MESSAGE_HANDLING (STATUS = OFF)
									   ,ACTIVATION (STATUS = ON 
									               ,PROCEDURE_NAME = Sales.get_report_orderByClients
												   ,MAX_QUEUE_READERS = 1
												   ,EXECUTE AS OWNER 
												   ) 

GO

-- ���������
/*
	exec sales.send_report_inquiry_orderByClients 
	select distinct InquiryID from Sales.OrdersByClientReport
	select count(*) from Sales.OrdersByClientReport
*/