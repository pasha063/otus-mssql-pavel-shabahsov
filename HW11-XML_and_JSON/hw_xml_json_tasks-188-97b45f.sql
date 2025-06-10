/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 

Сделать два варианта: с помощью OPENXML и через XQuery.
*/
drop table if exists #XMLSource

declare @xmlDocument xml
	,@docHandle int
	,@MaxStockItemID int = (select max(StockItemID) from Warehouse.StockItems)
	,@StockItemName nvarchar(100)

select @xmlDocument = BulkColumn
from openrowset(bulk 'D:\courses\OTUS\lesson 11 - XML and JSON\StockItems-188-1fb5df.xml', single_clob) as t

exec sp_xml_preparedocument @docHandle output, @xmlDocument

create table #XMLSource (
	StockItemID int null,
	[StockItemName] [nvarchar](100) NOT NULL,
	[SupplierID] [int] NOT NULL,
	[UnitPackageID] [int] NOT NULL,
	[OuterPackageID] [int] NOT NULL,
	[QuantityPerOuter] [int] NOT NULL,
	[TypicalWeightPerUnit] [decimal](18, 3) NOT NULL,
	[LeadTimeDays] [int] NOT NULL,
	[IsChillerStock] [bit] NOT NULL,
	[TaxRate] [decimal](18, 3) NOT NULL,
	[UnitPrice] [decimal](18, 2) NOT NULL,
)

-- OPENXML
insert into #XMLSource(
	StockItemName
	,SupplierID
	,UnitPackageID
	,OuterPackageID
	,QuantityPerOuter
	,TypicalWeightPerUnit
	,LeadTimeDays
	,IsChillerStock
	,TaxRate
	,UnitPrice
)
select
	StockItemName
	,SupplierID
	,UnitPackageID
	,OuterPackageID
	,QuantityPerOuter
	,TypicalWeightPerUnit
	,LeadTimeDays
	,IsChillerStock
	,TaxRate
	,UnitPrice
from openxml(@docHandle, N'/StockItems/Item')
with ( 
	StockItemName nvarchar(100) '@Name'
	,SupplierID int 'SupplierID'
	,UnitPackageID int 'Package/UnitPackageID'
	,OuterPackageID int 'Package/OuterPackageID'
	,QuantityPerOuter int 'Package/QuantityPerOuter'
	,TypicalWeightPerUnit decimal(18, 3) 'Package/TypicalWeightPerUnit'
	,LeadTimeDays int 'LeadTimeDays'
	,IsChillerStock bit 'IsChillerStock'
	,TaxRate decimal(18, 3) 'TaxRate'
	,UnitPrice decimal(18, 2) 'UnitPrice'
)

exec sp_xml_removedocument @docHandle;

-- XQuery
delete from #XMLSource

insert into #XMLSource(
	StockItemName
	,SupplierID
	,UnitPackageID
	,OuterPackageID
	,QuantityPerOuter
	,TypicalWeightPerUnit
	,LeadTimeDays
	,IsChillerStock
	,TaxRate
	,UnitPrice
)
select 
	Item.value('@Name', 'nvarchar(100)') as StockItemName,
	Item.value('SupplierID[1]', 'int') as SupplierID,
	Item.value('(Package/UnitPackageID)[1]', 'int') as UnitPackageID, 
	Item.value('(Package/OuterPackageID)[1]', 'int') as OuterPackageID, 
	Item.value('(Package/QuantityPerOuter)[1]', 'int') as QuantityPerOuter,
	Item.value('(Package/TypicalWeightPerUnit)[1]', 'decimal(18, 3)') as TypicalWeightPerUnit,
	Item.value('LeadTimeDays[1]', 'int') as LeadTimeDays,
	Item.value('IsChillerStock[1]', 'bit') as IsChillerStock,
	Item.value('TaxRate[1]', 'decimal(18, 3)') as TaxRate,
	Item.value('UnitPrice[1]', 'decimal(18, 2)') as UnitPrice
from @xmlDocument.nodes('/StockItems/Item') as Item(Item)

-- Заполняем StockItemID во временной таблице с помощью курсора, для тех StockItemName, которые отсутствуют в Warehouse.StockItems
declare StockItemID_cursor cursor for
	select xs.StockItemName 
	from #XMLSource as xs
		left join Warehouse.StockItems as si on si.StockItemName = xs.StockItemName collate Latin1_General_100_CI_AS
	where si.StockItemID is null

open StockItemID_cursor
fetch next from StockItemID_cursor into @StockItemName
while @@FETCH_STATUS = 0 
	begin
		set @MaxStockItemID = @MaxStockItemID + 1
		update #XMLSource set StockItemID = @MaxStockItemID where StockItemName = @StockItemName

		fetch next from StockItemID_cursor into @StockItemName
	end

close StockItemID_cursor
deallocate StockItemID_cursor

merge Warehouse.StockItems as t
using #XMLSource as s on s.StockItemName collate Latin1_General_100_CI_AS = t.StockItemName
when matched 
	then update
		set SupplierID = s.SupplierID
			,UnitPackageID = s.UnitPackageID
			,OuterPackageID = s.OuterPackageID
			,QuantityPerOuter = s.QuantityPerOuter
			,TypicalWeightPerUnit = s.TypicalWeightPerUnit
			,LeadTimeDays = s.LeadTimeDays
			,IsChillerStock = s.IsChillerStock
			,TaxRate = s.TaxRate
			,UnitPrice =s.UnitPrice
when not matched
	then insert (	
		StockItemID
		,StockItemName
		,SupplierID
		,UnitPackageID
		,OuterPackageID
		,QuantityPerOuter
		,TypicalWeightPerUnit
		,LeadTimeDays
		,IsChillerStock
		,TaxRate
		,UnitPrice
		,LastEditedBy
	)
	values(
		s.StockItemID
		,s.StockItemName
		,s.SupplierID
		,s.UnitPackageID
		,s.OuterPackageID
		,s.QuantityPerOuter
		,s.TypicalWeightPerUnit
		,s.LeadTimeDays
		,s.IsChillerStock
		,s.TaxRate
		,s.UnitPrice
		,1
	);
		

/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/
drop table if exists ##export 

create table ##export (xml_out nvarchar(max))
insert into ##export (xml_out)
select cast(
	(
		select
			StockItemName AS [@Name],
			SupplierID,
			UnitPackageID AS [Package/UnitPackageID],
			OuterPackageID AS [Package/OuterPackageID],
			QuantityPerOuter AS [Package/QuantityPerOuter],
			TypicalWeightPerUnit AS [Package/TypicalWeightPerUnit],
			LeadTimeDays,
			IsChillerStock,
			TaxRate,
			UnitPrice
		from Warehouse.StockItems
		for xml path('Item'), root('StockItems')
	)
as nvarchar(max))

declare @out varchar(255);
set @out = 'bcp "select xml_out from ##export" queryout "D:\courses\OTUS\lesson 11 - XML and JSON\demo.xml" -T -c -S ' + @@SERVERNAME

exec master..xp_cmdshell @out



/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

select
	si.StockItemID
	,si.StockItemName
	,j.CountryOfManufacture
	,j.FirstTag
from Warehouse.StockItems as si
	outer apply openjson(CustomFields) with (
		CountryOfManufacture nvarchar(20) '$.CountryOfManufacture'
		,FirstTag nvarchar(20) '$.Tags[0]'
	) as j

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/

select
	si.StockItemID
	,si.StockItemName
	,t.tags
from Warehouse.StockItems as si
	cross apply openjson(CustomFields, '$.Tags') as j
	left join (
		select
			sti.StockItemID
			,string_agg(js.value, ', ') as tags
		from Warehouse.StockItems as sti
			cross apply openjson(CustomFields, '$.Tags') as js
		group by sti.StockItemID
	) as t on t.StockItemID = si.StockItemID
where j.value = 'Vintage'



