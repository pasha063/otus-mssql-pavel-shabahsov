/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "13 - CLR".
*/

/*
	Варианты ДЗ (сделать любой один):

	1) Взять готовую dll, подключить ее и продемонстрировать использование. 
	Например, https://sqlsharp.com

	2) Взять готовые исходники из какой-нибудь статьи, скомпилировать, подключить dll, продемонстрировать использование.
	Например, 
	https://www.sqlservercentral.com/articles/xlsexport-a-clr-procedure-to-export-proc-results-to-excel

	https://www.mssqltips.com/sqlservertip/1344/clr-string-sort-function-in-sql-server/

	https://habr.com/ru/post/88396/

	3) Написать полностью свое (что-то одно):
	* Тип: JSON с валидацией, IP / MAC - адреса, ...
	* Функция: работа с JSON, ...
	* Агрегат: аналог STRING_AGG, ...
	* (любой ваш вариант)

	Результат ДЗ:
	* исходники (если они есть), желательно проект Visual Studio
	* откомпилированная сборка dll
	* скрипт подключения dll
	* демонстрация использования

*/

-- Взял статью https://www.mssqltips.com/sqlservertip/1344/clr-string-sort-function-in-sql-server/
exec sp_configure 'show advanced options', 1;
GO
reconfigure;
GO

exec sp_configure 'clr enabled', 1;
exec sp_configure 'clr strict security', 0 
GO

reconfigure;
GO

ALTER DATABASE WideWorldImporters SET TRUSTWORTHY ON; 

drop function if exists dbo.SortString
drop assembly if exists CLRFunctions
drop table if exists testSort

CREATE ASSEMBLY CLRFunctions FROM 'D:\Repo\otus-mssql-pavel-shabahsov\HW16-CLR\SQLServerCLRSortString.dll'
GO 

CREATE FUNCTION dbo.SortString    
(    
 @name AS NVARCHAR(255)    
)     
RETURNS NVARCHAR(255)    
AS EXTERNAL NAME CLRFunctions.CLRFunctions.SortString 
GO 

--testing
CREATE TABLE testSort (data NVARCHAR(255)) 
GO

INSERT INTO testSort VALUES('apple,pear,orange,banana,grape,kiwi') 
INSERT INTO testSort VALUES('pineapple,grape,banana,apple') 
INSERT INTO testSort VALUES(N'черника,клубника,калина,голубика') 
INSERT INTO testSort VALUES(N'вишня, виноград, арбуз, лимон') 

SELECT [data], dbo.sortString([data]) as sorted FROM testSort

drop function if exists dbo.SortString
drop assembly if exists CLRFunctions
drop table if exists testSort
