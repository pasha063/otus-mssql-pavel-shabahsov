create database MerchReports
go

alter database MerchReports collate Cyrillic_General_CI_AS
go

use MerchReports
go

create schema kpi
go

create schema merch
go

create schema ref
go

CREATE TABLE [ref].[tbl_Date](
	[ID] [int] NOT NULL,
	[Date] [date] NOT NULL,
	[YearMonth] [int] NOT NULL,
	[YearWeek] [int] NOT NULL,
 CONSTRAINT [PK_ref_tbl_Date] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UK_tbl_Date_Date] UNIQUE NONCLUSTERED 
(
	[Date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [ref].[tbl_RetailChain](
	[SK_RetailChain_ID] [bigint] NOT NULL,
	[Name] [nvarchar](255) NULL,
 CONSTRAINT [PK_ref_tbl_RetailChain] PRIMARY KEY CLUSTERED 
(
	[SK_RetailChain_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [ref].[tbl_Outlets](
	[SK_Outlet_ID] [bigint] NOT NULL,
	[Code] [nvarchar](10) NOT NULL,
	[SK_RetailChain_ID] [bigint] NOT NULL,
	[OutletType] [nvarchar](5) NOT NULL,
	[AddressFull] [nvarchar](255) NOT NULL,
	[GeographyRegion] [nvarchar](255) NOT NULL,
	[GeographyTown] [nvarchar](255) NOT NULL,
	[Latitude] [decimal](6, 4) NOT NULL,
	[Longitude] [decimal](6, 4) NOT NULL,
 CONSTRAINT [PK_ref_tbl_Outlets] PRIMARY KEY CLUSTERED 
(
	[SK_Outlet_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UK_tbl_Outlets_Code] UNIQUE NONCLUSTERED 
(
	[Code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [ref].[tbl_Outlets]  WITH CHECK ADD  CONSTRAINT [FK_tbl_Outlets_SK_RetailChain_ID_tbl_RetailChain] FOREIGN KEY([SK_RetailChain_ID])
REFERENCES [ref].[tbl_RetailChain] ([SK_RetailChain_ID])
GO

ALTER TABLE [ref].[tbl_Outlets] CHECK CONSTRAINT [FK_tbl_Outlets_SK_RetailChain_ID_tbl_RetailChain]
GO

CREATE TABLE [ref].[tbl_Positions](
	[SK_Position_ID] [bigint] NOT NULL,
	[Code] [nvarchar](50) NOT NULL,
	[Manager] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_ref_tbl_Positions] PRIMARY KEY CLUSTERED 
(
	[SK_Position_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UK_tbl_Positions_Code] UNIQUE NONCLUSTERED 
(
	[Code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [ref].[tbl_DailyCalcConfig](
	[fldMonth] [int] NOT NULL,
	[StartDateCalc] [date] NOT NULL,
	[EndDateCalc] [date] NOT NULL,
	[StartDateMonth] [int] NOT NULL
) ON [PRIMARY]
GO


CREATE TABLE [ref].[tbl_MerchCalendar](
	[fldMonth] [int] NOT NULL,
	[MonthCoefficient] [decimal](10, 9) NOT NULL,
 CONSTRAINT [UK_tbl_MerchCalendar_fldMonth] UNIQUE NONCLUSTERED 
(
	[fldMonth] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [ref].[tbl_MerchKPI](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Code] [nvarchar](10) NOT NULL,
	[NameEn] [nvarchar](10) NOT NULL,
	[FlagActive] [bit] NOT NULL,
	[QuestionName] [nvarchar](255) NULL,
	[SP_DocumentName] [nvarchar](255) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UK_tbl_MerchKPI_Code] UNIQUE NONCLUSTERED 
(
	[Code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [ref].[tbl_MerchKPI] ADD  CONSTRAINT [tbl_MerchKPI_FlagActive]  DEFAULT ((1)) FOR [FlagActive]
GO

CREATE TABLE [ref].[tbl_MerchKPIGrades](
	[fldMonth] [int] NOT NULL,
	[KPI] [nvarchar](10) NOT NULL,
	[Grade] [int] NOT NULL,
	[Execution] [decimal](9, 6) NOT NULL,
 CONSTRAINT [UK_tbl_MerchKPIGrades_fldMonth_KPI_Grade] UNIQUE NONCLUSTERED 
(
	[fldMonth] ASC,
	[KPI] ASC,
	[Grade] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [ref].[tbl_MerchBaseCity](
	[OutletCode] [nvarchar](10) NOT NULL,
	[BaseCity] [nvarchar](255) NOT NULL,
	[isActive] [bit] NOT NULL,
	[CoverStatus] [bit] NOT NULL,
 CONSTRAINT [UK_tbl_MerchBaseCity_OutletCode] UNIQUE NONCLUSTERED 
(
	[OutletCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


ALTER TABLE [ref].[tbl_MerchBaseCity]  WITH CHECK ADD  CONSTRAINT [FK_tbl_MerchBaseCity_OutletCode_tbl_Outlets] FOREIGN KEY([OutletCode])
REFERENCES [ref].[tbl_Outlets] ([Code])
GO

ALTER TABLE [ref].[tbl_MerchBaseCity] CHECK CONSTRAINT [FK_tbl_MerchBaseCity_OutletCode_tbl_Outlets]
GO

ALTER TABLE [ref].[tbl_MerchBaseCity] ADD  CONSTRAINT [tbl_MerchBaseCity_isActive]  DEFAULT ((1)) FOR [isActive]
GO

ALTER TABLE [ref].[tbl_MerchBaseCity] ADD  CONSTRAINT [tbl_MerchBaseCity_CoverStatus]  DEFAULT ((1)) FOR [CoverStatus]
GO

CREATE TABLE [merch].[tbl_Visits](
	[SK_Visit_ID] [bigint] NOT NULL,
	[SK_Date_ID] [int] NOT NULL,
	[SK_Outlet_ID] [bigint] NOT NULL,
	[SK_Position_ID] [bigint] NOT NULL,
	[SK_Time_ID_Start] [int] NOT NULL,
	[SK_Time_ID_End] [int] NOT NULL,
	[VisitTimeSec] [int] NOT NULL,
	[PhotoFileName] [nvarchar](max) NULL,
 CONSTRAINT [PK_ref_tbl_RetailChain] PRIMARY KEY CLUSTERED 
(
	[SK_Visit_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [merch].[tbl_Visits]  WITH CHECK ADD  CONSTRAINT [FK_tbl_Visits_SK_Date_ID_tbl_Date] FOREIGN KEY([SK_Date_ID])
REFERENCES [ref].[tbl_Date] ([ID])
GO

ALTER TABLE [merch].[tbl_Visits] CHECK CONSTRAINT [FK_tbl_Visits_SK_Date_ID_tbl_Date]
GO

ALTER TABLE [merch].[tbl_Visits]  WITH CHECK ADD  CONSTRAINT [FK_tbl_Visits_SK_Outlet_ID_tbl_Outlets] FOREIGN KEY([SK_Outlet_ID])
REFERENCES [ref].[tbl_Outlets] ([SK_Outlet_ID])
GO

ALTER TABLE [merch].[tbl_Visits] CHECK CONSTRAINT [FK_tbl_Visits_SK_Outlet_ID_tbl_Outlets]
GO

ALTER TABLE [merch].[tbl_Visits]  WITH CHECK ADD  CONSTRAINT [FK_tbl_Visits_SK_Position_ID_tbl_Positions] FOREIGN KEY([SK_Position_ID])
REFERENCES [ref].[tbl_Positions] ([SK_Position_ID])
GO

ALTER TABLE [merch].[tbl_Visits] CHECK CONSTRAINT [FK_tbl_Visits_SK_Position_ID_tbl_Positions]
GO

CREATE TABLE [merch].[tbl_SurveyFact](
	[SK_Visit_ID] [bigint] NOT NULL,
	[SK_Date_ID] [int] NOT NULL,
	[SK_Outlet_ID] [bigint] NOT NULL,
	[SK_Position_ID] [bigint] NOT NULL,
	[ResponseValue] [nvarchar](255) NOT NULL,
	[QuestionName] [nvarchar](255) NOT NULL,
	[SurveyName] [nvarchar](255) NOT NULL,
	[PhotoFileName] [nvarchar](255) NULL
) ON [PRIMARY]
GO

ALTER TABLE [merch].[tbl_SurveyFact]  WITH CHECK ADD  CONSTRAINT [FK_tbl_SurveyFact_SK_Date_ID_tbl_Date] FOREIGN KEY([SK_Date_ID])
REFERENCES [ref].[tbl_Date] ([ID])
GO

ALTER TABLE [merch].[tbl_SurveyFact] CHECK CONSTRAINT [FK_tbl_SurveyFact_SK_Date_ID_tbl_Date]
GO

ALTER TABLE [merch].[tbl_SurveyFact]  WITH CHECK ADD  CONSTRAINT [FK_tbl_SurveyFact_SK_Outlet_ID_tbl_Outlets] FOREIGN KEY([SK_Outlet_ID])
REFERENCES [ref].[tbl_Outlets] ([SK_Outlet_ID])
GO

ALTER TABLE [merch].[tbl_SurveyFact] CHECK CONSTRAINT [FK_tbl_SurveyFact_SK_Outlet_ID_tbl_Outlets]
GO

ALTER TABLE [merch].[tbl_SurveyFact]  WITH CHECK ADD  CONSTRAINT [FK_tbl_SurveyFact_SK_Position_ID_tbl_Positions] FOREIGN KEY([SK_Position_ID])
REFERENCES [ref].[tbl_Positions] ([SK_Position_ID])
GO

ALTER TABLE [merch].[tbl_SurveyFact] CHECK CONSTRAINT [FK_tbl_SurveyFact_SK_Position_ID_tbl_Positions]
GO

ALTER TABLE [merch].[tbl_SurveyFact]  WITH CHECK ADD  CONSTRAINT [FK_tbl_SurveyFact_SK_Visit_ID_tbl_Visits] FOREIGN KEY([SK_Visit_ID])
REFERENCES [merch].[tbl_Visits] ([SK_Visit_ID])
GO

ALTER TABLE [merch].[tbl_SurveyFact] CHECK CONSTRAINT [FK_tbl_SurveyFact_SK_Visit_ID_tbl_Visits]
GO


CREATE TABLE [merch].[tbl_AgencyRates](
	[fldMonth] [int] NOT NULL,
	[Agency] [nvarchar](255) NOT NULL,
	[AgencyFee] [decimal](7, 6) NOT NULL,
	[Factoring] [decimal](7, 6) NOT NULL
) ON [PRIMARY]
GO

CREATE TABLE [merch].[tbl_AuditCoefficient](
	[fldMonth] [int] NOT NULL,
	[EmployeeCode] [nvarchar](255) NOT NULL,
	[Type] [nvarchar](255) NOT NULL,
	[Value] [decimal](18, 6) NOT NULL
) ON [PRIMARY]
GO

CREATE TABLE [merch].[tbl_CityRates](
	[fldMonth] [int] NOT NULL,
	[Agency] [nvarchar](255) NOT NULL,
	[City] [nvarchar](255) NOT NULL,
	[BaseRate] [decimal](18, 6) NOT NULL,
	[TerritorialCoeff] [decimal](7, 6) NOT NULL
) ON [PRIMARY]
GO

CREATE TABLE [merch].[tbl_DigitalAuditFact](
	[fldMonth] [int] NOT NULL,
	[SK_Visit_ID] [bigint] NOT NULL,
	[KPI] [nvarchar](10) NOT NULL,
	[Level] [smallint] NOT NULL,
	[Value] [decimal](9, 6) NOT NULL,
	[Comment] [nvarchar](255) NOT NULL
) ON [PRIMARY]
GO

ALTER TABLE [merch].[tbl_DigitalAuditFact]  WITH CHECK ADD  CONSTRAINT [FK_tbl_DigitalAuditFact_SK_Visit_ID_tbl_Visits] FOREIGN KEY([SK_Visit_ID])
REFERENCES [merch].[tbl_Visits] ([SK_Visit_ID])
GO

ALTER TABLE [merch].[tbl_DigitalAuditFact] CHECK CONSTRAINT [FK_tbl_DigitalAuditFact_SK_Visit_ID_tbl_Visits]
GO


CREATE TABLE [merch].[tbl_POSPlan](
	[fldMonth] [int] NOT NULL,
	[OutletCode] [nvarchar](10) NOT NULL,
	[KPI] [nvarchar](10) NOT NULL,
	[Type] [nvarchar](10) NOT NULL,
	[Value] [decimal](9, 6) NOT NULL,
	[Comment] [nvarchar](255) NOT NULL
) ON [PRIMARY]
GO

ALTER TABLE [merch].[tbl_POSPlan]  WITH CHECK ADD  CONSTRAINT [FK_tbl_POSPlan_OutletCode_tbl_Outlets] FOREIGN KEY([OutletCode])
REFERENCES [ref].[tbl_Outlets] ([Code])
GO

ALTER TABLE [merch].[tbl_POSPlan] CHECK CONSTRAINT [FK_tbl_POSPlan_OutletCode_tbl_Outlets]
GO

CREATE TABLE [merch].[tbl_VisitOrder](
	[fldMonth] [int] NOT NULL,
	[Agency] [nvarchar](255) NOT NULL,
	[OutletCode] [nvarchar](10) NOT NULL,
	[VisitTimeMinutesMin] [decimal](6, 2) NOT NULL,
	[VisitTimeMinutes] [decimal](6, 2) NOT NULL,
	[VisitPerWeek] [int] NOT NULL,
	[HoursStandart] [decimal](6, 2) NOT NULL
) ON [PRIMARY]
GO

ALTER TABLE [merch].[tbl_VisitOrder]  WITH CHECK ADD  CONSTRAINT [FK_tbl_VisitOrder_OutletCode_tbl_Outlets] FOREIGN KEY([OutletCode])
REFERENCES [ref].[tbl_Outlets] ([Code])
GO

ALTER TABLE [merch].[tbl_VisitOrder] CHECK CONSTRAINT [FK_tbl_VisitOrder_OutletCode_tbl_Outlets]
GO

CREATE TABLE [kpi].[tbl_OSA](
	[SK_Visit_ID] [bigint] NOT NULL,
	[SK_Date_ID] [int] NOT NULL,
	[SK_Outlet_ID] [bigint] NOT NULL,
	[SK_Position_ID] [bigint] NOT NULL,
	[OSA] [decimal](5, 4) NOT NULL
) ON [PRIMARY]
GO

ALTER TABLE [kpi].[tbl_OSA]  WITH CHECK ADD  CONSTRAINT [FK_tbl_OSA_SK_Date_ID_tbl_Date] FOREIGN KEY([SK_Date_ID])
REFERENCES [ref].[tbl_Date] ([ID])
GO

ALTER TABLE [kpi].[tbl_OSA] CHECK CONSTRAINT [FK_tbl_OSA_SK_Date_ID_tbl_Date]
GO

ALTER TABLE [kpi].[tbl_OSA]  WITH CHECK ADD  CONSTRAINT [FK_tbl_OSA_SK_Outlet_ID_tbl_Outlets] FOREIGN KEY([SK_Outlet_ID])
REFERENCES [ref].[tbl_Outlets] ([SK_Outlet_ID])
GO

ALTER TABLE [kpi].[tbl_OSA] CHECK CONSTRAINT [FK_tbl_OSA_SK_Outlet_ID_tbl_Outlets]
GO

ALTER TABLE [kpi].[tbl_OSA]  WITH CHECK ADD  CONSTRAINT [FK_tbl_OSA_SK_Position_ID_tbl_Positions] FOREIGN KEY([SK_Position_ID])
REFERENCES [ref].[tbl_Positions] ([SK_Position_ID])
GO

ALTER TABLE [kpi].[tbl_OSA] CHECK CONSTRAINT [FK_tbl_OSA_SK_Position_ID_tbl_Positions]
GO

ALTER TABLE [kpi].[tbl_OSA]  WITH CHECK ADD  CONSTRAINT [FK_tbl_OSA_SK_Visit_ID_tbl_Visits] FOREIGN KEY([SK_Visit_ID])
REFERENCES [merch].[tbl_Visits] ([SK_Visit_ID])
GO

ALTER TABLE [kpi].[tbl_OSA] CHECK CONSTRAINT [FK_tbl_OSA_SK_Visit_ID_tbl_Visits]
GO

CREATE TABLE [kpi].[tbl_SP](
	[SK_Visit_ID] [bigint] NOT NULL,
	[SK_Date_ID] [int] NOT NULL,
	[SK_Outlet_ID] [bigint] NOT NULL,
	[SK_Position_ID] [bigint] NOT NULL,
	[OutletType] [nvarchar](10) NOT NULL,
	[DocumentName] [nvarchar](255) NOT NULL,
	[SPCorrectedQty] [decimal](18, 6) NOT NULL,
	[AuditorValue] [decimal](18, 6) NULL,
	[AuditorComment] [nvarchar](255) NULL,
	[AppealValue] [decimal](18, 6) NULL,
	[AppealComment] [nvarchar](255) NULL,
	[JDEAuditorValue] [decimal](18, 6) NULL,
	[JDEAuditorComment] [nvarchar](255) NULL
) ON [PRIMARY]
GO

ALTER TABLE [kpi].[tbl_SP]  WITH CHECK ADD  CONSTRAINT [FK_tbl_SP_SK_Date_ID_tbl_Date] FOREIGN KEY([SK_Date_ID])
REFERENCES [ref].[tbl_Date] ([ID])
GO

ALTER TABLE [kpi].[tbl_SP] CHECK CONSTRAINT [FK_tbl_SP_SK_Date_ID_tbl_Date]
GO

ALTER TABLE [kpi].[tbl_SP]  WITH CHECK ADD  CONSTRAINT [FK_tbl_SP_SK_Outlet_ID_tbl_Outlets] FOREIGN KEY([SK_Outlet_ID])
REFERENCES [ref].[tbl_Outlets] ([SK_Outlet_ID])
GO

ALTER TABLE [kpi].[tbl_SP] CHECK CONSTRAINT [FK_tbl_SP_SK_Outlet_ID_tbl_Outlets]
GO

ALTER TABLE [kpi].[tbl_SP]  WITH CHECK ADD  CONSTRAINT [FK_tbl_SP_SK_Position_ID_tbl_Positions] FOREIGN KEY([SK_Position_ID])
REFERENCES [ref].[tbl_Positions] ([SK_Position_ID])
GO

ALTER TABLE [kpi].[tbl_SP] CHECK CONSTRAINT [FK_tbl_SP_SK_Position_ID_tbl_Positions]
GO

ALTER TABLE [kpi].[tbl_SP]  WITH CHECK ADD  CONSTRAINT [FK_tbl_SP_SK_Visit_ID_tbl_Visits] FOREIGN KEY([SK_Visit_ID])
REFERENCES [merch].[tbl_Visits] ([SK_Visit_ID])
GO

ALTER TABLE [kpi].[tbl_SP] CHECK CONSTRAINT [FK_tbl_SP_SK_Visit_ID_tbl_Visits]
GO

CREATE TABLE [kpi].[tbl_WorkingDaysReport](
	[SK_Position_ID] [bigint] NOT NULL,
	[FldMonth] [int] NOT NULL,
	[SK_Date_ID] [int] NOT NULL,
	[SK_Outlet_ID] [bigint] NOT NULL,
	[Manager] [nvarchar](255) NULL,
	[VisitTimeBegin] [time](7) NOT NULL,
	[VisitTimeEnd] [time](7) NOT NULL,
	[LongitudeBegin] [decimal](6, 4) NOT NULL,
	[LatitudeBegin] [decimal](6, 4) NOT NULL,
	[DistanceFromOutletBegin] [decimal](18, 10) NULL,
	[LongitudeEnd] [decimal](6, 4) NOT NULL,
	[LatitudeEnd] [decimal](6, 4) NOT NULL,
	[DistanceFromOutletEnd] [decimal](18, 10) NULL
) ON [PRIMARY]
GO

ALTER TABLE [kpi].[tbl_WorkingDaysReport]  WITH CHECK ADD  CONSTRAINT [FK_tbl_WorkingDaysReport_SK_Date_ID_tbl_Date] FOREIGN KEY([SK_Date_ID])
REFERENCES [ref].[tbl_Date] ([ID])
GO

ALTER TABLE [kpi].[tbl_WorkingDaysReport] CHECK CONSTRAINT [FK_tbl_WorkingDaysReport_SK_Date_ID_tbl_Date]
GO

ALTER TABLE [kpi].[tbl_WorkingDaysReport]  WITH CHECK ADD  CONSTRAINT [FK_tbl_WorkingDaysReport_SK_Outlet_ID_tbl_Outlets] FOREIGN KEY([SK_Outlet_ID])
REFERENCES [ref].[tbl_Outlets] ([SK_Outlet_ID])
GO

ALTER TABLE [kpi].[tbl_WorkingDaysReport] CHECK CONSTRAINT [FK_tbl_WorkingDaysReport_SK_Outlet_ID_tbl_Outlets]
GO

ALTER TABLE [kpi].[tbl_WorkingDaysReport]  WITH CHECK ADD  CONSTRAINT [FK_tbl_WorkingDaysReport_SK_Position_ID_tbl_Positions] FOREIGN KEY([SK_Position_ID])
REFERENCES [ref].[tbl_Positions] ([SK_Position_ID])
GO

ALTER TABLE [kpi].[tbl_WorkingDaysReport] CHECK CONSTRAINT [FK_tbl_WorkingDaysReport_SK_Position_ID_tbl_Positions]
GO

CREATE TABLE [merch].[tbl_VisitFactCost](
	[SK_Visit_ID] [bigint] NOT NULL,
	[Agency] [varchar](255) NULL,
	[SK_Date_ID] [int] NOT NULL,
	[YearWeek] [int] NOT NULL,
	[fldMonth] [int] NOT NULL,
	[OutletCode] [varchar](20) NOT NULL,
	[ChainName] [varchar](100) NULL,
	[OutletType] [varchar](100) NULL,
	[AddressFull] [varchar](1000) NULL,
	[isOutletBaseCityCovered] [bit] NULL,
	[RSM] [int] NULL,
	[ASM] [int] NULL,
	[Manager] [varchar](100) NULL,
	[EmployeeCode] [varchar](50) NOT NULL,
	[BaseCity] [varchar](100) NULL,
	[GeographyRegion] [varchar](100) NULL,
	[GeographyTown] [varchar](100) NULL,
	[Latitude] [decimal](16, 8) NULL,
	[Longitude] [decimal](16, 8) NULL,
	[VisitTimeMinutesMin] [decimal](16, 8) NULL,
	[VisitTimeMinutes] [decimal](16, 8) NULL,
	[VisitPerWeek] [int] NULL,
	[HoursStandart] [decimal](16, 8) NULL,
	[MonthCoefficient] [decimal](16, 8) NULL,
	[AgencyFee] [decimal](16, 8) NULL,
	[Factoring] [decimal](16, 8) NULL,
	[BaseRate] [decimal](16, 8) NULL,
	[TerritorialCoeff] [decimal](16, 8) NULL,
	[HourCost_Base_KPI_AK] [decimal](16, 8) NULL,
	[Position_Name] [varchar](100) NULL,
	[VisitTimeBegin] [time](7) NULL,
	[VisitTimeEnd] [time](7) NULL,
	[LongitudeBegin] [decimal](16, 8) NULL,
	[LatitudeBegin] [decimal](16, 8) NULL,
	[DistanceFromOutletBegin] [decimal](16, 8) NULL,
	[LongitudeEnd] [decimal](16, 8) NULL,
	[LatitudeEnd] [decimal](16, 8) NULL,
	[DistanceFromOutletEnd] [decimal](16, 8) NULL,
	[TimeSincePreviousVisit] [time](7) NULL,
	[TaskPass] [bit] NULL,
	[CoordinatesPass] [bit] NULL,
	[VisitsPerWeekPass] [bit] NULL,
	[MinimumTimeVisitPass] [bit] NULL,
	[DaysCountVisitPass] [bit] NULL,
	[CoordinatorVisitException] [decimal](16, 8) NULL,
	[AgencyComment] [varchar](1000) NULL,
	[InspectorVisitException] [decimal](16, 8) NULL,
	[InspectorComment] [varchar](1000) NULL,
	[JDEVisitException] [decimal](16, 8) NULL,
	[JDEComment] [varchar](1000) NULL,
	[TMDigitalAuditCoefficient] [decimal](16, 8) NULL,
	[TMFieldAuditCoefficient] [decimal](16, 8) NULL,
	[VisitCost_Base_KPI_AK] [decimal](16, 8) NULL,
	[VisitCost_Base_AK] [decimal](16, 8) NULL,
	[VisitCost_KPI_AK] [decimal](16, 8) NULL,
	[VisitPass] [int] NULL,
	[FinalVisitPass] [decimal](16, 8) NULL,
	[KPI] [varchar](20) NULL,
	[Plan] [decimal](16, 8) NULL,
	[Fact] [decimal](16, 8) NULL,
	[Fact / Plan] [decimal](16, 8) NULL,
	[Execution] [decimal](16, 8) NULL,
	[AuditorValue] [decimal](16, 8) NULL,
	[AuditorComment] [varchar](1000) NULL,
	[AppealValue] [decimal](16, 8) NULL,
	[AppealComment] [varchar](1000) NULL,
	[JDEAuditorValue] [decimal](16, 8) NULL,
	[JDEAuditorComment] [varchar](1000) NULL,
	[FinalExecution] [decimal](16, 8) NULL,
	[Weight] [decimal](16, 8) NULL,
	[Photo] [varchar](max) NULL,
	[PaymentCost] [decimal](16, 8) NULL,
	[FinalPaymentCost] [decimal](16, 8) NULL
) ON [PRIMARY] 
GO

CREATE TABLE [merch].[tbl_HourCost](
	[fldMonth] [int] NOT NULL,
	[OutletCode] [nvarchar](20) NOT NULL,
	[Agency] [nvarchar](255) NULL,
	[BaseCity] [nvarchar](255) NULL,
	[GeoCity] [nvarchar](255) NULL,
	[HourCost] [decimal](18, 6) NULL,
	[VisitCost] [decimal](18, 6) NULL,
	[VisitCostPerWeek] [decimal](18, 6) NULL,
 CONSTRAINT [PK_tblMerchHourCost] PRIMARY KEY CLUSTERED 
(
	[fldMonth] ASC,
	[OutletCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


CREATE view [merch].[vw_MerchVisitsPlan]
as
	with cte_POSPlan as (
		select
			fldMonth
			,OutletCode
			,KPI
			,Type
			,Value
			,row_number() over(
				partition by fldMonth, OutletCode, KPI, left(Type, 4)
				order by iif(right(Type, 3) = 'exc', 1, 2) -- если загружен exсeption, то берем его 
			) as rn
		from merch.tbl_POSPlan
	)
	select
		hc.Agency
		,hc.fldMonth as Period
		,hc.OutletCode
		,'Some chain' as [Сеть]
		,o.AddressFull
		,bc.BaseCity as [Базовый город]
		,o.GeographyRegion
		,hc.GeoCity				as [Geography Town]
		,o.Latitude
		,o.Longitude
		,mv.VisitTimeMinutesMin as [Time Minimum per visit, minutes]
		,mv.VisitTimeMinutes as [Time per visit, minutes]
		,mv.VisitPerWeek as [Visit per week]
		,mv.HoursStandart as [Стандарт часов в день FS/ST]
		,hc.HourCost as [Hour Cost]
		,hc.VisitCost as [Visit Cost]
		,hc.VisitCostPerWeek as [Visits cost per week]
		,kpi.KPI
		,kpi.[Type] as [KPI Type]
		,kpi.[Value] as [KPI Value]
	from merch.tbl_HourCost as hc
		inner join ref.tbl_Outlets as o on o.Code = hc.OutletCode
		left join merch.tbl_VisitOrder as mv on mv.fldMonth = hc.fldMonth
			and mv.OutletCode = hc.OutletCode
		left join cte_POSPlan as kpi on kpi.fldMonth = hc.fldMonth
			and kpi.OutletCode = hc.OutletCode
			and kpi.rn = 1
		left join ref.tbl_MerchBaseCity	as bc on bc.OutletCode = hc.OutletCode
go

;CREATE view [merch].[vw_VisitFactCost]
as
 
	select
		cast(SK_Visit_ID as varchar(30)) as Visit_ID
		,Agency
		,SK_Date_ID as [Date]
		,YearWeek as [Week]
		,fldMonth
		,OutletCode
		,ChainName as [Сеть]
		,OutletType as [Тип ТТ]
		,AddressFull as [Адрес]
		,iif(isOutletBaseCityCovered = 1, 'да', 'нет') as [Точка к покрытию]
		,RSM
		,ASM
		,Manager as [Territory TM]
		--,EmployeeCode
		,BaseCity as [Базовый город]
		,GeographyRegion as [Geography Reg]
		,GeographyTown as [Geography Town]
		,Latitude as [Широта]
		,Longitude as [Долгота]
		,VisitTimeMinutesMin as [Time Minimum per visit, minutes]
		,VisitTimeMinutes as [Time per visit, minutes]
		,VisitPerWeek as [Visit per week]
		,HoursStandart as [Стандарт часов в день FS/ST]
		,MonthCoefficient as [Коэфф произв календаря]
		,HourCost_Base_KPI_AK as [Hour cost (Base+KPI+AK)]
		,VisitCost_Base_KPI_AK as [Visit cost (Base+KPI+AK)]
		,VisitCost_Base_AK as [Visit cost (Base+AK)]
		,VisitCost_KPI_AK as [Visit cost (KPI 100% +AK)]
		,Position_Name as [Автор визита (FS ST)]
		,VisitTimeBegin as [Время начала визита]
		,VisitTimeEnd as [Время конца визита]
		,datediff(minute, VisitTimeBegin, VisitTimeEnd) as [Длительность визита в минутах]
		,LongitudeBegin as [коор факт входа долгота]
		,LatitudeBegin as [коор факт входа широта]
		,DistanceFromOutletBegin as [отклонение координат входа от эталонной точки, метров]
		,LongitudeEnd as [коор факт выхода долгота]
		,LatitudeEnd as [коор факт выхода широта]
		,DistanceFromOutletEnd as [отклонение координат выхода от эталонной точки, метров]
		,TimeSincePreviousVisit as [время с завершения предыдущего  визита]
		,iif(TaskPass = 1, 1, 0) as [зачет визита по соответствию наличия в задании (1/0)]
		,iif(CoordinatesPass = 1, 1, 0) as [зачет визита по координа там (1/0)]
		,iif(VisitsPerWeekPass = 1, 1, 0) as [зачет визита кол-ву в квлендарную неделю (1/0)]
		,iif(MinimumTimeVisitPass = 1, 1, 0) as [зачет по времени в день]
		,iif(DaysCountVisitPass = 1, 1, 0) as [зачет по самому длительному посещению в рамках одного visit_id]
		,iif(VisitPass = 1, 1, 0) as [ИТОГО зачет визита СИСТЕМОЙ]
		,CoordinatorVisitException as [Crd-Visit-Exc]
		,AgencyComment as [комментарий эксепшена от координатора агентства]
		,InspectorVisitException as [Insp-Visit-Exc]
		,InspectorComment as [комментарий эксепшена от инспектора]
		,JDEVisitException as [JDE-Visit-Exc]
		,JDEComment as [комментарий эксепшена от JDE]
		,FinalVisitPass as [ИТОГО зачет визита ФИНАЛЬНЫЙ]
		,KPI
		,[Plan]
		,Fact
		,[Fact / Plan]
		,Execution
		,AuditorValue as [Aud]
		,AuditorComment as [комментарий аудитора]
		,AppealValue as [Appeal]
		,AppealComment as [апелляция от агентсва]
		,JDEAuditorValue as [JDE-Aud]
		,JDEAuditorComment as [итоговое приняте апелляции от JDE]
		,FinalExecution as [Exec с учетом проверок]
		,[Weight] as [Вес]
		,PaymentCost as [Visit cost к выплате]
		,TMDigitalAuditCoefficient as [TM_digital-audit]
		,TMFieldAuditCoefficient as [TM_field-audit]
		,FinalPaymentCost as [Итого Visit cost к выплате]
		,Photo as [Фото]
	from merch.tbl_VisitFactCost

GO