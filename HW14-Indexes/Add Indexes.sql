

CREATE INDEX IX_tbl_Visits_SK_Visit_ID_SK_Date_ID
ON [merch].[tbl_Visits](SK_Visit_ID, SK_Date_ID);

CREATE CLUSTERED INDEX [IX_tbl_WorkingDaysReport_SK_Date_ID] 
ON kpi.tbl_WorkingDaysReport ([SK_Date_ID] ASC);

CREATE CLUSTERED INDEX [IX_tbl_POSPlan_fldMonth] 
ON merch.tbl_POSPlan (fldMonth ASC);

CREATE CLUSTERED INDEX [IX_tbl_DigitalAuditFact_fldMonth] 
ON merch.tbl_DigitalAuditFact (fldMonth ASC);

CREATE CLUSTERED INDEX [IX_tbl_SP_SK_Date_ID] 
ON kpi.tbl_SP ([SK_Date_ID] ASC);

CREATE CLUSTERED INDEX [IX_tbl_SP_SK_Date_ID] 
ON kpi.tbl_OSA ([SK_Date_ID] ASC);

CREATE CLUSTERED INDEX [IX_tbl_SurveyFact_SK_Date_ID] 
ON [merch].[tbl_SurveyFact] ([SK_Date_ID] ASC);

CREATE CLUSTERED INDEX [IX_tbl_MerchKPIGrades_fldMonth] 
ON ref.tbl_MerchKPIGrades (fldMonth ASC);

CREATE CLUSTERED INDEX [IX_tbl_VisitOrder_fldMonth] 
ON merch.tbl_VisitOrder (fldMonth ASC);

CREATE CLUSTERED INDEX [IX_tbl_AgencyRates_fldMonth] 
ON merch.tbl_AgencyRates (fldMonth ASC);

CREATE CLUSTERED INDEX [IX_tbl_CityRates_fldMonth] 
ON merch.tbl_CityRates (fldMonth ASC);

CREATE CLUSTERED INDEX [IX_tbl_AuditCoefficient_fldMonth] 
ON merch.tbl_AuditCoefficient (fldMonth ASC);