--Включить брокер
USE master
ALTER DATABASE WideWorldImporters
SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE; 

--БД должна функционировать от имени технической учетки!!!
ALTER AUTHORIZATION    
   ON DATABASE::WideWorldImporters TO [sa];

ALTER DATABASE WideWorldImporters SET TRUSTWORTHY ON;

--Создаем типы сообщений
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

--Создаем ОЧЕРЕДЬ таргета(настрим позже т.к. через ALTER можно ею рулить еще
CREATE QUEUE TargetQueueWWI;
--и сервис таргета
CREATE SERVICE [//WWI/SB/TargetService]
       ON QUEUE TargetQueueWWI
       ([//WWI/SB/Contract]);

--то же для ИНИЦИАТОРА
CREATE QUEUE InitiatorQueueWWI;

CREATE SERVICE [//WWI/SB/InitiatorService]
       ON QUEUE InitiatorQueueWWI
       ([//WWI/SB/Contract]);
go

-- Создаем таблицу для нового отчета
create table Sales.OrdersByClientReport (
	InquiryID varchar(50)
	,CustomerID int not null
	,LastYearOrdersQuantity int not null
	,DateInsert datetime not null default getdate()
)
go

-- Создаем процедуру для создания отчета
create procedure sales.send_report_inquiry_orderByClients 
as
begin
	SET NOCOUNT ON;

    --Sending a Request Message to the Target	
	DECLARE @InitDlgHandle UNIQUEIDENTIFIER;
	DECLARE @InquiryID UNIQUEIDENTIFIER = newID();
	DECLARE @RequestMessage NVARCHAR(4000);
	
	BEGIN TRAN --на всякий случай в транзакции, т.к. это еще не относится к транзакции ПЕРЕДАЧИ сообщения

		--Формируем XML с корнем RequestMessage где передадим номер инвойса(в принципе сообщение может быть любым)
		SELECT @RequestMessage = N'<RequestMessage> ' + cast(@InquiryID as nvarchar(100)) + ' </RequestMessage>'

		--Создаем диалог
		BEGIN DIALOG @InitDlgHandle
		FROM SERVICE
		[//WWI/SB/InitiatorService] --от этого сервиса(это сервис текущей БД, поэтому он НЕ строка)
		TO SERVICE
		'//WWI/SB/TargetService'    --к этому сервису(это сервис который может быть где-то, поэтому строка)
		ON CONTRACT
		[//WWI/SB/Contract]         --в рамках этого контракта
		WITH ENCRYPTION=OFF;        --не шифрованный

		--отправляем одно наше подготовленное сообщение, но можно отправить и много сообщений, которые будут обрабатываться строго последовательно)
		SEND ON CONVERSATION @InitDlgHandle 
		MESSAGE TYPE
		[//WWI/SB/RequestMessage]
		(@RequestMessage);
	COMMIT TRAN 
end
go

-- Создаем активационную процедуру обработки заявки
create procedure Sales.get_report_orderByClients --будет получать сообщение на таргете
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
		--Получаем сообщение от инициатора которое находится у таргета
		RECEIVE TOP(1) --обычно одно сообщение, но можно пачкой
			@TargetDlgHandle = Conversation_Handle, --ИД диалога
			@Message = Message_Body, --само сообщение
			@MessageType = Message_Type_Name --тип сообщения( в зависимости от типа можно по разному обрабатывать) обычно два - запрос и ответ
		FROM dbo.TargetQueueWWI; --имя очереди которую мы ранее создавали

		SET @xml = CAST(@Message AS XML);
		--достаем InquiryID
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
		IF @MessageType=N'//WWI/SB/RequestMessage' --если наш тип сообщения
		BEGIN
			SET @ReplyMessage =N'<ReplyMessage> Message received</ReplyMessage>'; --ответ
			--отправляем сообщение нами придуманное, что все прошло хорошо
			SEND ON CONVERSATION @TargetDlgHandle
			MESSAGE TYPE
			[//WWI/SB/ReplyMessage]
			(@ReplyMessage);
			END CONVERSATION @TargetDlgHandle; --А вот и завершение диалога!!! - оно двухстороннее(пока-пока) ЭТО первый ПОКА
											   --НЕЛЬЗЯ ЗАВЕРШАТЬ ДИАЛОГ ДО ОТПРАВКИ ПЕРВОГО СООБЩЕНИЯ
		END 
	COMMIT TRAN;
END
go

-- Создаем активационную процедуру закрытия диалога
create procedure Sales.confirm_report_orderByClients
AS
BEGIN
	--Receiving Reply Message from the Target.	
	DECLARE @InitiatorReplyDlgHandle UNIQUEIDENTIFIER,
			@ReplyReceivedMessage NVARCHAR(1000) 
	
	BEGIN TRAN; 

	    --Получаем сообщение от таргета которое находится у инициатора
		RECEIVE TOP(1)
			@InitiatorReplyDlgHandle=Conversation_Handle
			,@ReplyReceivedMessage=Message_Body
		FROM dbo.InitiatorQueueWWI; 
		
		END CONVERSATION @InitiatorReplyDlgHandle; --ЭТО второй ПОКА
		
	COMMIT TRAN; 
END

ALTER QUEUE [dbo].[InitiatorQueueWWI] WITH STATUS = ON --OFF=очередь НЕ доступна(ставим если глобальные проблемы)
                                          ,RETENTION = OFF --ON=все завершенные сообщения хранятся в очереди до окончания диалога
										  ,POISON_MESSAGE_HANDLING (STATUS = OFF) --ON=после 5 ошибок очередь будет отключена
	                                      ,ACTIVATION (STATUS = ON --OFF=очередь не активирует ХП(в PROCEDURE_NAME)(ставим на время исправления ХП, но с потерей сообщений)  
										              ,PROCEDURE_NAME = Sales.confirm_report_orderByClients
													  ,MAX_QUEUE_READERS = 1 --количество потоков(ХП одновременно вызванных) при обработке сообщений(0-32767)
													                         --(0=тоже не позовется процедура)(ставим на время исправления ХП, без потери сообщений) 
													  ,EXECUTE AS OWNER --учетка от имени которой запустится ХП
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

-- тестируем
/*
	exec sales.send_report_inquiry_orderByClients 
	select distinct InquiryID from Sales.OrdersByClientReport
	select count(*) from Sales.OrdersByClientReport
*/