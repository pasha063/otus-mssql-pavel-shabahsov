/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "12 - Хранимые процедуры, функции, триггеры, курсоры".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

USE WideWorldImporters
go
/*
Во всех заданиях написать хранимую процедуру / функцию и продемонстрировать ее использование.
*/

/*
1) Написать функцию возвращающую Клиента с наибольшей суммой покупки.
*/
drop function if exists Sales.udf_get_Customer_with_maxTotalPurchaseAmount
go

create function Sales.udf_get_Customer_with_maxTotalPurchaseAmount()
returns nvarchar(200)
	as 
	begin
		declare @CustomerName as nvarchar(200) = (
			select top 1
				c.CustomerName as Customer
			from Sales.Invoices as i
				inner join Sales.Customers as c on c.CustomerID = i.CustomerID
				inner join Sales.InvoiceLines as il on il.InvoiceID = i.InvoiceID
			group by
				c.CustomerID
				,c.CustomerName
			order by sum(il.StockItemID * il.UnitPrice) desc
		)

		return @CustomerName
	end
go
  
/*
2) Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/
drop procedure if exists Sales.usp_get_Customer_TotalPurchaseAmount
go

create procedure Sales.usp_get_Customer_TotalPurchaseAmount(
	@CustomerID as int
)
as 
	SET TRANSACTION ISOLATION LEVEL READ Committed; -- можно было не задавать, так как по умолчанию. Выбран данный уровень из логики того, что пользователю нужно получить информацию на данный момент времени(запуска процедуры)
	begin tran
		select sum(il.StockItemID * il.UnitPrice) as TotalPurchaseAmount
		from Sales.Invoices as i
			inner join Sales.Customers as c on c.CustomerID = i.CustomerID
			inner join Sales.InvoiceLines as il on il.InvoiceID = i.InvoiceID
		where c.CustomerID = @CustomerID
		group by
			c.CustomerID
	commit tran
go

/*
3) Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
*/

--функция, которая возврашает тот же результат, что и процедура в задании 2
drop function if exists Sales.udf_get_Customer_TotalPurchaseAmount
go

create function Sales.udf_get_Customer_TotalPurchaseAmount(@CustomerID int)
returns decimal (18, 2)
	as 
	begin
		declare @TotalPurchaseAmount as decimal (18, 2) = (
			select sum(il.StockItemID * il.UnitPrice) as TotalPurchaseAmount
			from Sales.Invoices as i
				inner join Sales.Customers as c on c.CustomerID = i.CustomerID
				inner join Sales.InvoiceLines as il on il.InvoiceID = i.InvoiceID
			where c.CustomerID = @CustomerID
			group by
				c.CustomerID
		)

		return @TotalPurchaseAmount
	end
go

exec Sales.usp_get_Customer_TotalPurchaseAmount 14
select Sales.udf_get_Customer_TotalPurchaseAmount(14)
/*
	данный пример наверно не показательный, так как оба варианта возвращают результат мгновенно
	Но если смотреть на план выполнения, то видно, что функция справляется с этой задачей в 100 раз быстрее и план запроса значительно меньше.
	Очевидно, что для простых запросов с необходимостью возврата результата лучше использовать функцию, где это возможно. В остальных случаях - процедуру.
*/

/*
4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла. 
*/

drop function if exists [Application].udf_get_EmailDomain
go

create function [Application].udf_get_EmailDomain()
returns table
as
return
(
    select 
        PersonID
        ,substring(EmailAddress, charindex('@', EmailAddress) + 1, len(EmailAddress)) AS Domain
    from [Application].People
);
go

	select
		o.OrderID
		,p.Domain as SalesPersonDomain
	from Sales.Orders as o
		cross apply [Application].udf_get_EmailDomain() as p
	where o.OrderDate = (select max(OrderDate) from Sales.Orders)
		and o.SalespersonPersonID = p.PersonID
/*
5) Опционально. Во всех процедурах укажите какой уровень изоляции транзакций вы бы использовали и почему. 
*/
