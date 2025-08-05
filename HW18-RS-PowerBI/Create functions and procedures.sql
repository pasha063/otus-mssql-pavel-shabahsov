USE [MerchReports]
GO

create function [dbo].[fn_fulldate_to_int]
(
	@iddate as date
)

returns integer
AS

begin
	declare @convdate as integer

	set @convdate = datepart(year, @iddate) * 10000 + datepart(month, @iddate) * 100 + datepart(day, @iddate)
	return @convdate

end
GO



CREATE procedure [merch].[usp_HourCost_Visit_Calc]
	@fldMonth int = null
as

begin try
	-- exec [merch].[HourCost_Visit_Calc] 202506
	drop table if exists #HourCost
	drop table if exists #Calc

	if @fldMonth is null
		begin
			set @fldMonth = (select fldmonth from ref.tbl_DailyCalcConfig where cast(getdate() as date) between StartDateCalc and EndDateCalc)
		end

	-- Расчет часовой ставки
	select
		 mv.fldMonth
		,mv.Agency
		,mv.OutletCode
		,bc.BaseCity
		,o.GeographyTown as GeoCity
		,mv.VisitTimeMinutes
		,mv.VisitPerWeek
		,round(mc.MonthCoefficient, 6)
			* ar.Factoring
			* ar.AgencyFee
			* cr.BaseRate
			* cr.TerritorialCoeff
			/ 21 
			/ mv.HoursStandart
		as HourCost
	into #HourCost
	from merch.tbl_VisitOrder as mv
		left join ref.tbl_MerchBaseCity as bc on bc.OutletCode = mv.OutletCode
		left join ref.tbl_Outlets as o on o.Code = mv.OutletCode
		left join ref.tbl_MerchCalendar	as mc on mc.fldMonth = mv.fldMonth
		left join merch.tbl_AgencyRates	as ar on ar.fldMonth = mv.fldMonth
			and ar.Agency = mv.Agency 
		left join merch.tbl_CityRates as cr on cr.fldMonth = mv.fldMonth
			and cr.Agency = mv.Agency
			and cr.City = bc.BaseCity
	where mv.fldMonth = @fldMonth

	select
		fldMonth
		,OutletCode
		,Agency
		,BaseCity
		,GeoCity
		,HourCost
		,HourCost / 60 * VisitTimeMinutes as VisitCost
		,HourCost / 60 * VisitTimeMinutes * VisitPerWeek as VisitCostPerWeek
	into #Calc
	from #HourCost

	begin tran
		delete from merch.tbl_HourCost
		where fldMonth = @fldMonth

		insert into merch.tbl_HourCost (fldMonth, OutletCode, Agency, BaseCity, GeoCity, HourCost, VisitCost, VisitCostPerWeek)
		select
			 fldMonth
			,OutletCode
			,Agency
			,BaseCity
			,GeoCity
			,HourCost
			,VisitCost
			,VisitCostPerWeek
		from #Calc
	commit tran

end try
begin catch
	if @@trancount > 0 
		begin rollback tran end

	declare @ErrorMessage as varchar(max) = error_message()
	;throw 51000, @ErrorMessage, 1

end catch
GO

CREATE procedure [merch].[usp_Visit_Fact_Cost_Calc]
	@DateBegin as int = null
	,@DateEnd as int = null
as

begin try
	
	drop table if exists #VisitsFactStep1
	drop table if exists #VisitsOnWeekCounter
	drop table if exists #LastVisitEndTime
	drop table if exists #VisitsFact
	drop table if exists #WorkingDays
	drop table if exists #Outlets
	drop table if exists #Positions
	drop table if exists #KPI_Plans
	drop table if exists #auditFactValue
	drop table if exists #auditFactComment
	drop table if exists #auditFact
	drop table if exists #KPI_fact
	drop table if exists #MaxExecution
	drop table if exists #KPIStep1
	drop table if exists #KPI
	drop table if exists #ReportStep1
	drop table if exists #ReportStep2
	drop table if exists #ReportStep3

	-- exec [merch].[usp_Visit_Fact_Cost_Calc] 20250601, 20250630
	-- Отчет пересчитывается каждый день службой. Отчетный месяц берется из конфигурационного файла ref.tbl_DailyCalcConfig
	declare @today as date = (select cast(getdate() as date))
	declare @fldMonth as int = (select fldMonth from ref.tbl_DailyCalcConfig where @today between [StartDateCalc] AND [EndDateCalc])

	if @DateBegin is null
		begin
			set @DateBegin = (select StartDateMonth from ref.tbl_DailyCalcConfig where fldMonth = @fldMonth)
		end

	if @DateEnd is null
		begin
			set @DateEnd = (select dbo.fn_fulldate_to_int(dateadd(dd, -1, @today)))
		end

	-- Соберем факты по визитам в отчетном периоде
	select
		SK_Visit_ID
		,SK_Date_ID
		,SK_Outlet_ID
		,SK_Position_ID
		,timefromparts([SK_Time_ID_Start] / 10000, ([SK_Time_ID_Start] / 100) % 100, [SK_Time_ID_Start] % 100, 0, 0) as SK_Time_Start
		,timefromparts([SK_Time_ID_End] / 10000, ([SK_Time_ID_End] / 100) % 100, [SK_Time_ID_End] % 100, 0, 0) as SK_Time_End
		,row_number() over (partition by SK_Date_ID, SK_Outlet_ID, SK_Position_ID order by VisitTimeSec desc) as DaysLongestVisit
		,PhotoFileName
	into #VisitsFactStep1
	from merch.tbl_Visits
	where SK_Date_ID between @DateBegin and @DateEnd

	-- Посчитаем количество визитов торговых точек за неделю для каждой должностной позиции
	select
		f.SK_Visit_ID
		,row_number() over (partition by f.SK_Outlet_ID, f.SK_Position_ID, YearWeek order by SK_Date_ID) as VisitsOnWeekCounter
	into #VisitsOnWeekCounter
	from #VisitsFactStep1 as f
		left join ref.tbl_Date as d on d.ID = f.SK_Date_ID
	where f.DaysLongestVisit = 1 -- для отчета берем только один визит в день (выбираемый по длительности визита).

	-- Посчитаем время окончания последнего визита для каждой позиции в разрезе дня
	select
		SK_Date_ID
		,SK_Position_ID
		,max(SK_Time_End) as LastVisitEndTime
	into #LastVisitEndTime
	from #VisitsFactStep1
	group by
		SK_Date_ID
		,SK_Position_ID

	-- Соберем все необходимые данные по визитам
	select
		c.SK_Visit_ID
		,c.SK_Date_ID
		,c.SK_Outlet_ID
		,c.SK_Position_ID
		,c.SK_Time_Start
		,c.SK_Time_End
		,c.DaysLongestVisit
		,c.PhotoFileName
		,v.VisitsOnWeekCounter
		,lv.LastVisitEndTime
	into #VisitsFact
	from #VisitsFactStep1 as c
		left join #VisitsOnWeekCounter as v on v.SK_Visit_ID = c.SK_Visit_ID
		left join #LastVisitEndTime as lv on lv.SK_Date_ID = c.SK_Date_ID
			and lv.SK_Position_ID = c.SK_Position_ID

	/* 
		Получим предрассчитанные данные из отчета WorkingDays
		Избавляемся от дублей, так как нас не итересуют сплиты по SurveyName 
	*/
	select distinct
		SK_Position_ID
		,FldMonth
		,SK_Date_ID
		,SK_Outlet_ID
		,Manager as Position_Name
		,VisitTimeBegin
		,VisitTimeEnd
		,LongitudeBegin
		,LatitudeBegin
		,DistanceFromOutletBegin
		,LongitudeEnd
		,LatitudeEnd
		,DistanceFromOutletEnd
	into #WorkingDays 
	from kpi.tbl_WorkingDaysReport
	where SK_Date_ID between @DateBegin and @DateEnd

	-- Справочник торговых точек
	select
		o.SK_Outlet_ID
		,o.Code as OutletCode
		,r.[Name] as ChainName
		,o.OutletType
		,o.AddressFull
		,bc.CoverStatus as isOutletBaseCityCovered
		,'Some Territory' as TerritoryTM
		,bc.BaseCity as BaseCity
		,o.GeographyRegion
		,o.GeographyTown
		,o.Latitude
		,o.Longitude
	into #Outlets
	from ref.tbl_Outlets as o
		left join ref.tbl_MerchBaseCity as bc on bc.OutletCode = o.Code
		left join ref.tbl_RetailChain as r on r.SK_RetailChain_ID = o.SK_RetailChain_ID
	where o.SK_Outlet_ID in (select distinct SK_Outlet_ID from #VisitsFact)

	-- Справочник должностных позиций
	select
		SK_Position_ID
		,Code as EmployeeCode
		,Manager
	into #Positions
	from ref.tbl_Positions
	where SK_Position_ID in (select distinct SK_Position_ID from #VisitsFact)

	-- Плановые KPI
	select
		fldMonth
		,OutletCode
		,KPI
		,[Plan]
		,[Weight]
		,[Plan-exc]
		,[Weight-exc]
	into #KPI_Plans
	from (
		select
			fldMonth
			,OutletCode
			,KPI
			,[Type]
			,[Value]
		from merch.tbl_POSPlan
		where fldMonth between @DateBegin / 100 and @DateEnd / 100
		) as unpvt
	pivot (max([Value]) for [Type] in ([Plan], [Weight], [Plan-exc], [Weight-exc])) as pvt

	-- Результаты аудитов
	select
		fldMonth
		,SK_Visit_ID
		,KPI
		,[1] as Lvl1_Value
		,[2] as Lvl2_Value
		,[3] as Lvl3_Value
	into #auditFactValue
	from (
		select
			fldMonth
			,SK_Visit_ID
			,KPI
			,[Level]
			,[Value]
		from merch.tbl_DigitalAuditFact
		where fldMonth between @DateBegin / 100 and @DateEnd / 100
		) as unpvt
	pivot (max([Value]) for [Level] in ([1], [2], [3])) as pvt

	select
		fldMonth
		,SK_Visit_ID
		,KPI
		,[1] as Lvl1_Comment
		,[2] as Lvl2_Comment
		,[3] as Lvl3_Comment
	into #auditFactComment
	from (
		select
			fldMonth
			,SK_Visit_ID
			,KPI
			,[Level]
			,[Comment]
		from merch.tbl_DigitalAuditFact
		where fldMonth between @DateBegin / 100 and @DateEnd / 100
		) as unpvt
	pivot (max([Comment]) for [Level] in ([1], [2], [3])) as pvt

	select 
		v.fldMonth
		,v.SK_Visit_ID
		,v.KPI
		,v.Lvl1_Value
		,v.Lvl2_Value
		,v.Lvl3_Value
		,c.Lvl1_Comment
		,c.Lvl2_Comment
		,c.Lvl3_Comment
	into #auditFact
	from #auditFactValue as v
		inner join #auditFactComment as c on c.fldMonth = v.fldMonth
			and c.SK_Visit_ID = v.SK_Visit_ID
			and c.KPI = v.KPI

	--Фактические показатели выполнения KPI
	--SP
	select
		SK_Visit_ID
		,SK_Date_ID
		,SK_Outlet_ID
		,SK_Position_ID
		,cast('SP' as varchar(255)) as KPI
		,sum(isnull(SPCorrectedQty, 0)) as Fact
		,min(AuditorValue) as AuditorValue
		,string_agg(AuditorComment, '; ') as AuditorComment
		,min(AppealValue) as AppealValue
		,string_agg(AppealComment, '; ') as AppealComment
		,min(JDEAuditorValue) as JDEAuditorValue
		,string_agg(JDEAuditorComment, '; ') as JDEAuditorComment
		,cast('' as varchar(max)) as Photo
	into #KPI_fact
	from kpi.tbl_SP
	where SK_Date_ID between @DateBegin and @DateEnd
		and	(OutletType in ('HM', 'CC') or DocumentName like 'ДМП_%') 
	group by
		SK_Visit_ID
		,SK_Date_ID
		,SK_Outlet_ID
		,SK_Position_ID

	union all

	-- SS and Impulse
	select
		f.SK_Visit_ID
		,f.SK_Date_ID
		,f.SK_Outlet_ID
		,f.SK_Position_ID
		,k.Code as KPI
		,try_cast(max(f.ResponseValue) as decimal(10, 6)) as Fact
		,null as AuditorValue
		,null as AuditorComment
		,null as AppealValue
		,null as AppealComment
		,null as JDEAuditorValue
		,null as JDEAuditorComment
		,string_agg(PhotoFileName, '; ') as Photo
	from merch.tbl_SurveyFact as f
		inner join ref.tbl_MerchKPI as k on k.QuestionName = f.QuestionName
	where f.SK_Date_ID between @DateBegin and @DateEnd
		and f.SurveyName in ('Perfect Store Coffee', 'Доля полки МТ')
		and k.FlagActive = 1
		and k.QuestionName is not null
		and try_cast(f.ResponseValue as decimal(10, 6)) is not null
	group by
		f.SK_Visit_ID
		,f.SK_Date_ID
		,f.SK_Outlet_ID
		,f.SK_Position_ID
		,k.Code

	union all

	-- OSA
	select
		cf.SK_Visit_ID
		,a.SK_Date_ID
		,a.SK_Outlet_ID
		,a.SK_Position_ID
		,'OSA' as KPI
		,OSA as Fact
		,null as AuditorValue
		,null as AuditorComment
		,null as AppealValue
		,null as AppealComment
		,null as JDEAuditorValue
		,null as JDEAuditorComment
		,null as Photo
	from kpi.tbl_OSA as a
		inner join #VisitsFact as cf on cf.SK_Visit_ID = a.SK_Visit_ID
			and cf.SK_Position_ID = a.SK_Position_ID
	where a.SK_Date_ID between @DateBegin and @DateEnd

	-- Определим максимальное значение для каждого KPI
	select
		a.fldMonth
		,a.KPI
		,a.Grade
		,a.Execution
	into #MaxExecution
	from ref.tbl_MerchKPIGrades as a
	where a.fldMonth between @DateBegin / 100 and @DateEnd / 100
		and a.Grade = (
			select
				max(Grade) as Grade
			from ref.tbl_MerchKPIGrades as b
			where b.fldMonth = a.fldMonth
				and b.KPI = a.KPI
		)


	-- Собираем информацию по выполнению KPI
	select
		cf.SK_Visit_ID
		,cf.SK_Date_ID
		,cf.SK_Outlet_ID
		,cf.SK_Position_ID
		,isnull(p.KPI, f.KPI) as KPI
		,isnull(p.[Plan-exc], p.[Plan]) as [Plan]
		,isnull(f.Fact, 0) as Fact
		,case
			when coalesce(p.[Plan-exc], p.[Plan], 0) = 0
				then 0
			when isnull(p.KPI, f.KPI) = 'Imp'
				and (isnull(f.Fact, 0) / isnull(p.[Plan-exc], p.[Plan])) <= 1
				then (isnull(f.Fact, 0) / isnull(p.[Plan-exc], p.[Plan]))
			when isnull(p.KPI, f.KPI) = 'Imp'
				and (isnull(f.Fact, 0) / isnull(p.[Plan-exc], p.[Plan])) > 1
				then (1 + (isnull(f.Fact, 0) - isnull(p.[Plan-exc], p.[Plan])) * 0.01)
			else (isnull(f.Fact, 0) / isnull(p.[Plan-exc], p.[Plan])) 
		end as [Fact / Plan]
		,case
			when gr.[Execution] is not null
				then gr.[Execution] / 100
			when coalesce(p.[Plan-exc], p.[Plan], 0) = 0
				then 0
			when isnull(p.KPI, f.KPI) = 'Imp'
				and (isnull(f.Fact, 0) / isnull(p.[Plan-exc], p.[Plan])) > 1
				then iif(
					(1 + (isnull(f.Fact, 0) - isnull(p.[Plan-exc], p.[Plan])) * 0.01) < 1.2
					,(1 + (isnull(f.Fact, 0) - isnull(p.[Plan-exc], p.[Plan])) * 0.01)
					,1.2
				)
			when (isnull(f.Fact, 0) / isnull(p.[Plan-exc], p.[Plan])) > me.Grade / 100
				then me.Execution / 100
			else 0
		end as [Execution]
		,isnull(f.AuditorValue, af.Lvl1_Value) as AuditorValue
		,isnull(f.AuditorComment, af.Lvl1_Comment) as AuditorComment
		,isnull(f.AppealValue, af.Lvl2_Value) as AppealValue
		,isnull(f.AppealComment, af.Lvl2_Comment) as AppealComment
		,isnull(f.JDEAuditorValue, af.Lvl3_Value) as JDEAuditorValue
		,isnull(f.JDEAuditorComment, af.Lvl3_Comment) as JDEAuditorComment
		,isnull(p.[Weight-exc], p.[Weight]) as [Weight]
		,f.Photo
	into #KPIStep1
	from #VisitsFact as cf
		inner join #Outlets as o on o.SK_Outlet_ID = cf.SK_Outlet_ID
		inner join ref.tbl_Date as d on d.ID = cf.SK_Date_ID
		left join #KPI_Plans as p on p.fldMonth = d.YearMonth
			and p.OutletCode = o.OutletCode
		left join #KPI_fact as f on f.SK_Visit_ID = cf.SK_Visit_ID
			and f.KPI = isnull(p.KPI, f.KPI)
		left join #auditFact as af on af.SK_Visit_ID = cf.SK_Visit_ID
			and af.fldMonth = d.YearMonth
			and af.KPI = isnull(p.KPI, f.KPI)
		left join ref.tbl_MerchKPIGrades as gr on gr.fldMonth = d.YearMonth
			and gr.KPI = isnull(p.KPI, f.KPI)
			and gr.Grade = case
				when coalesce(p.[Plan-exc], p.[Plan], 0) = 0
					then 0
				when isnull(p.KPI, f.KPI) = 'Imp'
					and (isnull(f.Fact, 0) / isnull(p.[Plan-exc], p.[Plan])) > 1
					then iif(
						(1 + (isnull(f.Fact, 0) - isnull(p.[Plan-exc], p.[Plan])) * 0.01) < 1.2
						,(1 + (isnull(f.Fact, 0) - isnull(p.[Plan-exc], p.[Plan])) * 0.01) * 100
						,1.2 * 100
				)
				else round((f.Fact / isnull(p.[Plan-exc], p.[Plan]) * 100), 0)
			end
		left join #MaxExecution as me on me.fldMonth = d.YearMonth
			and me.KPI = isnull(p.KPI, f.KPI)

	select
		SK_Visit_ID
		,SK_Date_ID
		,SK_Outlet_ID
		,SK_Position_ID
		,KPI
		,[Plan]
		,Fact
		,[Fact / Plan]
		,[Execution]
		,AuditorValue
		,AuditorComment
		,AppealValue
		,AppealComment
		,JDEAuditorValue
		,JDEAuditorComment
		,[Weight]
		,case
			when JDEAuditorValue is not null
				then JDEAuditorValue  * [Execution]
			when AuditorValue < [Execution]
				then AuditorValue * [Execution]
			else [Execution]
		end as FinalExecution				
		,Photo
	into #KPI
	from #KPIStep1

	union all

	-- добавляем строки для оплаты визитов
	select
		SK_Visit_ID
		,null
		,null
		,null
		,'Visit'
		,null
		,null
		,null
		,null
		,null
		,null
		,null
		,null
		,null
		,null
		,null
		,null
		,PhotoFileName
	from #VisitsFact

	--Собираем отчет
	select
		f.SK_Visit_ID
		,mvo.Agency
		,f.SK_Date_ID
		,d.YearWeek
		,d.YearMonth as fldMonth
		,o.OutletCode
		,o.ChainName
		,o.OutletType
		,o.AddressFull -- в учебных целях Адреса не заданы
		,o.isOutletBaseCityCovered
		,null as RSM -- заглушка
		,null as ASM -- заглушка
		,p.Manager  -- в учебных целях Manager не указан
		,p.EmployeeCode
		,o.BaseCity
		,o.GeographyRegion -- в учебных целях Адреса не заданы
		,o.GeographyTown
		,o.Latitude  -- в учебных целях координаты торговых точек не заданы
		,o.Longitude  -- в учебных целях координаты торговых точек не заданы
		,mvo.VisitTimeMinutesMin
		,mvo.VisitTimeMinutes
		,mvo.VisitPerWeek
		,mvo.HoursStandart
		,mc.MonthCoefficient
		,ar.AgencyFee -- в учебных целях AgencyFee задан не реальным
		,ar.Factoring
		,cr.BaseRate
		,cr.TerritorialCoeff
		,(mc.MonthCoefficient * ar.AgencyFee * ar.Factoring * cr.BaseRate * cr.TerritorialCoeff / 21 / mvo.HoursStandart) as HourCost_Base_KPI_AK -- в учебных целях AgencyFee задан не реальным
		,wd.Position_Name  -- в учебных целях Manager не указан
		,wd.VisitTimeBegin
		,wd.VisitTimeEnd
		,wd.LongitudeBegin
		,wd.LatitudeBegin
		,wd.DistanceFromOutletBegin
		,wd.LongitudeEnd
		,wd.LatitudeEnd
		,wd.DistanceFromOutletEnd
		,f.LastVisitEndTime as TimeSincePreviousVisit
		,iif(mvo.fldMonth is not null, 1 , 0) as TaskPass -- зачет посещения торговой точки
		,iif(wd.DistanceFromOutletBegin < 500 and wd.DistanceFromOutletEnd < 500, 1, 0) as CoordinatesPass -- в учебных целях координаты не заданы, поэтому везде зачет по координатам
		,iif(f.VisitsOnWeekCounter > mvo.VisitPerWeek, 0, 1) as VisitsPerWeekPass -- задание по посещениям
		,iif(datediff(minute, wd.VisitTimeBegin, wd.VisitTimeEnd) > mvo.VisitTimeMinutesMin, 1, 0) as MinimumTimeVisitPass  -- задание по минимальному времени нахождения в торговой точке
		,iif(f.DaysLongestVisit = 1, 1, 0) as DaysCountVisitPass -- в зачет только самый длительный визит в день для одной торговой точки
		,af.Lvl1_Value as CoordinatorVisitException
		,af.Lvl1_Comment as AgencyComment
		,af.Lvl2_Value as InspectorVisitException
		,af.Lvl2_Comment as InspectorComment
		,af.Lvl3_Value as JDEVisitException
		,af.Lvl3_Comment as JDEComment
		,isnull(macdig.[Value], 1) as TMDigitalAuditCoefficient
		,isnull(macfld.[Value], 1) as TMFieldAuditCoefficient
	into #ReportStep1
	from #VisitsFact as f 
		left join #Outlets as o on o.SK_Outlet_ID = f.SK_Outlet_ID
		left join ref.tbl_Date as d on d.ID = f.SK_Date_ID
		left join #Positions as p on p.SK_Position_ID = f.SK_Position_ID
		left join merch.tbl_VisitOrder as mvo on mvo.OutletCode = o.OutletCode
			and mvo.fldMonth = d.YearMonth
		left join ref.tbl_MerchCalendar as mc on mc.fldMonth = d.YearMonth
		left join merch.tbl_AgencyRates as ar on ar.Agency = mvo.Agency
			and ar.fldMonth = d.YearMonth
		left join merch.tbl_CityRates as cr on cr.Agency = mvo.Agency
			and cr.fldMonth = d.YearMonth
			and cr.City = o.BaseCity	
		left join #WorkingDays as wd on wd.SK_Position_ID = f.SK_Position_ID
			and wd.SK_Date_ID = f.SK_Date_ID
			and wd.SK_Outlet_ID = f.SK_Outlet_ID
			and wd.VisitTimeBegin = f.SK_Time_Start
			and wd.VisitTimeEnd = f.SK_Time_End
		left join #auditFact as af on af.SK_Visit_ID = f.SK_Visit_ID
			and af.fldMonth = d.YearMonth
			and af.KPI = 'Visit'
		left join merch.tbl_AuditCoefficient as macdig on macdig.fldMonth = d.YearMonth
			and macdig.EmployeeCode = p.EmployeeCode
			and macdig.[Type] = 'TM_digital-audit'
		left join merch.tbl_AuditCoefficient as macfld on macfld.fldMonth = d.YearMonth
			and macfld.EmployeeCode = p.EmployeeCode
			and macfld.[Type] = 'TM_field-audit'

	select
		*
		,(HourCost_Base_KPI_AK / 60 * VisitTimeMinutes) as VisitCost_Base_KPI_AK
		,(HourCost_Base_KPI_AK / 60 * VisitTimeMinutes) * 0.6 as VisitCost_Base_AK
		,(HourCost_Base_KPI_AK / 60 * VisitTimeMinutes) * 0.4 as VisitCost_KPI_AK
		,TaskPass * CoordinatesPass * VisitsPerWeekPass * MinimumTimeVisitPass * DaysCountVisitPass as VisitPass --зачет визита
		,case
			when JDEVisitException is not null
				then JDEVisitException
			when CoordinatorVisitException < (TaskPass * CoordinatesPass * VisitsPerWeekPass * MinimumTimeVisitPass * DaysCountVisitPass)
				then CoordinatorVisitException * (TaskPass * CoordinatesPass * VisitsPerWeekPass * MinimumTimeVisitPass * DaysCountVisitPass)
			else (TaskPass * CoordinatesPass * VisitsPerWeekPass * MinimumTimeVisitPass * DaysCountVisitPass)
		end as FinalVisitPass --финальный зачет визита с учетом аудиторских проверок
	into #ReportStep2
	from #ReportStep1

	select
		a.*
		,k.KPI
		,k.[Plan]
		,k.Fact
		,k.[Fact / Plan]
		,k.Execution
		,k.AuditorValue
		,k.AuditorComment
		,k.AppealValue
		,k.AppealComment
		,k.JDEAuditorValue
		,k.JDEAuditorComment
		,case
			when k.KPI = 'Visit'
				then a.FinalVisitPass
			else k.FinalExecution
		end as FinalExecution
		,k.[Weight]
		,k.[Photo]
		,case
			when k.KPI = 'Visit'
				then a.FinalVisitPass * a.VisitCost_Base_AK
			when k.Photo is null and k.KPI <> 'OSA'
				then 0
			when a.FinalVisitPass = 0
				then 0
			else a.VisitCost_KPI_AK * k.FinalExecution * k.[Weight]
		end as PaymentCost
		,case
			when k.KPI = 'Visit'
				then a.FinalVisitPass * a.VisitCost_Base_AK
			when k.Photo is null and k.KPI <> 'OSA'
				then 0
			when a.FinalVisitPass = 0
				then 0
			else a.VisitCost_KPI_AK * k.FinalExecution * k.[Weight] * a.TMDigitalAuditCoefficient * a.TMFieldAuditCoefficient
		end as FinalPaymentCost
	into #ReportStep3 
	from #ReportStep2 as a
		left join #KPI as k on k.SK_Visit_ID = a.SK_Visit_ID

	begin tran
		delete from merch.tbl_VisitFactCost where SK_Date_ID between @DateBegin and @DateEnd

		insert into merch.tbl_VisitFactCost (
			SK_Visit_ID
			,Agency
			,SK_Date_ID
			,YearWeek
			,fldMonth
			,OutletCode
			,ChainName
			,OutletType
			,AddressFull
			,isOutletBaseCityCovered
			,RSM
			,ASM
			,Manager
			,EmployeeCode
			,BaseCity
			,GeographyRegion
			,GeographyTown
			,Latitude
			,Longitude
			,VisitTimeMinutesMin
			,VisitTimeMinutes
			,VisitPerWeek
			,HoursStandart
			,MonthCoefficient
			,AgencyFee
			,Factoring
			,BaseRate
			,TerritorialCoeff
			,HourCost_Base_KPI_AK
			,Position_Name
			,VisitTimeBegin
			,VisitTimeEnd
			,LongitudeBegin
			,LatitudeBegin
			,DistanceFromOutletBegin
			,LongitudeEnd
			,LatitudeEnd
			,DistanceFromOutletEnd
			,TimeSincePreviousVisit
			,TaskPass
			,CoordinatesPass
			,VisitsPerWeekPass
			,MinimumTimeVisitPass
			,DaysCountVisitPass
			,CoordinatorVisitException
			,AgencyComment
			,InspectorVisitException
			,InspectorComment
			,JDEVisitException
			,JDEComment
			,TMDigitalAuditCoefficient
			,TMFieldAuditCoefficient
			,VisitCost_Base_KPI_AK
			,VisitCost_Base_AK
			,VisitCost_KPI_AK
			,VisitPass
			,FinalVisitPass
			,KPI
			,[Plan]
			,Fact
			,[Fact / Plan]
			,Execution
			,AuditorValue
			,AuditorComment
			,AppealValue
			,AppealComment
			,JDEAuditorValue
			,JDEAuditorComment
			,FinalExecution
			,[Weight]
			,Photo
			,PaymentCost
			,FinalPaymentCost
		)
		select
			SK_Visit_ID
			,Agency
			,SK_Date_ID
			,YearWeek
			,fldMonth
			,OutletCode
			,ChainName
			,OutletType
			,AddressFull
			,isOutletBaseCityCovered
			,RSM
			,ASM
			,Manager
			,EmployeeCode
			,BaseCity
			,GeographyRegion
			,GeographyTown
			,Latitude
			,Longitude
			,VisitTimeMinutesMin
			,VisitTimeMinutes
			,VisitPerWeek
			,HoursStandart
			,MonthCoefficient
			,AgencyFee
			,Factoring
			,BaseRate
			,TerritorialCoeff
			,HourCost_Base_KPI_AK
			,Position_Name
			,VisitTimeBegin
			,VisitTimeEnd
			,LongitudeBegin
			,LatitudeBegin
			,DistanceFromOutletBegin
			,LongitudeEnd
			,LatitudeEnd
			,DistanceFromOutletEnd
			,TimeSincePreviousVisit
			,TaskPass
			,CoordinatesPass
			,VisitsPerWeekPass
			,MinimumTimeVisitPass
			,DaysCountVisitPass
			,CoordinatorVisitException
			,AgencyComment
			,InspectorVisitException
			,InspectorComment
			,JDEVisitException
			,JDEComment
			,TMDigitalAuditCoefficient
			,TMFieldAuditCoefficient
			,VisitCost_Base_KPI_AK
			,VisitCost_Base_AK
			,VisitCost_KPI_AK
			,VisitPass
			,FinalVisitPass
			,KPI
			,[Plan]
			,Fact
			,[Fact / Plan]
			,Execution
			,AuditorValue
			,AuditorComment
			,AppealValue
			,AppealComment
			,JDEAuditorValue
			,JDEAuditorComment
			,FinalExecution
			,[Weight]
			,trim(Photo)
			,PaymentCost
			,FinalPaymentCost
		from #ReportStep3
	commit tran

end try
begin catch
	if @@trancount > 0 
		begin rollback tran end

	declare @ErrorMessage as varchar(max) = error_message()
	;throw 51000, @ErrorMessage, 1

end catch

GO


