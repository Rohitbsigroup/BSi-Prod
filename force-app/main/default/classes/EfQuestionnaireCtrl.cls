public with sharing class EfQuestionnaireCtrl {

	// Public properties
	public EfQuestionnaire__c Efq { get; set; }
	public Boolean IsNew { get; set; }
    public List<CheckOption> MySectors { get; set; }
    public List<CheckOption> MySizes { get; set; }
    public List<CheckOption> MySystemsOperational { get; set; }
    public List<CheckOption> MySystemsInformation { get; set; }
    public List<CheckOption> MySystemsOther { get; set; }
    public List<CheckOption> MyStandards { get; set; }
    public List<CheckOption> MyTraining { get; set; }
    public List<CheckOption> MyImprovement { get; set; }
    public List<CheckOption> MyCertification { get; set; }
    public List<CheckOption> MyOther { get; set; }
    public List<ChartPoint> Chart1 { get; set; }
    public EfSettings__c Settings { get; set; }

	public EfQuestionnaireCtrl(ApexPages.StandardController std) {

		// Get settings
		this.Settings = [
			SELECT	s.Id, s.Name, s.Improvement_Slides__c, s.Motivations_Dashboard__c, s.Playbook_Link__c
			FROM	EfSettings__c s
			LIMIT	1
		];
		if (this.Settings == null) this.Settings = new EfSettings__c();

		// Get schema details
		Schema.sObjectType sobject_type = EfQuestionnaire__c.getSObjectType();
		Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe();
		Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap();

		this.MySectors = new List<CheckOption>();
		List<Schema.PicklistEntry> pick_list_values = field_map.get('S1_Organization_Sectors__c').getDescribe().getPickListValues();
		for (Schema.PicklistEntry a : pick_list_values) {
			this.MySectors.add(new CheckOption(a.getValue(), a.getLabel(), new List<Boolean> { false, false }));
		}
		this.MySizes = new List<CheckOption>();
		pick_list_values = field_map.get('S1_Organization_Employees__c').getDescribe().getPickListValues();
		for (Schema.PicklistEntry a : pick_list_values) {
			this.MySizes.add(new CheckOption(a.getValue(), a.getLabel(), new List<Boolean> { false, false }));
		}
		this.MySystemsOperational = new List<CheckOption>();
		pick_list_values = field_map.get('S2_Systems_Operational_Implemented__c').getDescribe().getPickListValues();
		for (Schema.PicklistEntry a : pick_list_values) {
			this.MySystemsOperational.add(new CheckOption(a.getValue(), a.getLabel(), new List<Boolean> { false, false, false }));
		}
		this.MySystemsInformation = new List<CheckOption>();
		pick_list_values = field_map.get('S2_Systems_Information_Implemented__c').getDescribe().getPickListValues();
		for (Schema.PicklistEntry a : pick_list_values) {
			this.MySystemsInformation.add(new CheckOption(a.getValue(), a.getLabel(), new List<Boolean> { false, false, false }));
		}
		this.MySystemsOther = new List<CheckOption>();
		pick_list_values = field_map.get('S2_Systems_Other_Implemented__c').getDescribe().getPickListValues();
		for (Schema.PicklistEntry a : pick_list_values) {
			this.MySystemsOther.add(new CheckOption(a.getValue(), a.getLabel(), new List<Boolean> { false, false, false }));
		}
		this.MyStandards = new List<CheckOption>();
		pick_list_values = field_map.get('S5_Standards__c').getDescribe().getPickListValues();
		for (Schema.PicklistEntry a : pick_list_values) {
			this.MyStandards.add(new CheckOption(a.getValue(), a.getLabel(), new List<Boolean> { false }));
		}
		this.MyTraining = new List<CheckOption>();
		pick_list_values = field_map.get('S5_Training_Public__c').getDescribe().getPickListValues();
		for (Schema.PicklistEntry a : pick_list_values) {
			this.MyTraining.add(new CheckOption(a.getValue(), a.getLabel(), new List<Boolean> { false, false }));
		}
		this.MyImprovement = new List<CheckOption>();
		pick_list_values = field_map.get('S5_Improvement__c').getDescribe().getPickListValues();
		for (Schema.PicklistEntry a : pick_list_values) {
			this.MyImprovement.add(new CheckOption(a.getValue(), a.getLabel(), new List<Boolean> { false }));
		}
		this.MyCertification = new List<CheckOption>();
		pick_list_values = field_map.get('S5_Certification__c').getDescribe().getPickListValues();
		for (Schema.PicklistEntry a : pick_list_values) {
			this.MyCertification.add(new CheckOption(a.getValue(), a.getLabel(), new List<Boolean> { false }));
		}
		this.MyOther = new List<CheckOption>();
		pick_list_values = field_map.get('S5_Other__c').getDescribe().getPickListValues();
		for (Schema.PicklistEntry a : pick_list_values) {
			this.MyOther.add(new CheckOption(a.getValue(), a.getLabel(), new List<Boolean> { false }));
		}

		// Set the questionnaire fields
		if (String.isBlank(std.getId())) {
			
			// New record
			this.IsNew = true;
			this.Efq = new EfQuestionnaire__c();
			
			// See whether parameters have been passed
			Map<String, String> params = ApexPages.currentPage().getParameters();
			if (String.isNotBlank(params.get('acctId'))) this.Efq.S1_Related_Account__c = params.get('acctId');
			if (String.isNotBlank(params.get('contId'))) this.Efq.S1_Related_Contact__c = params.get('contId');
			if (String.isNotBlank(params.get('leadId'))) this.Efq.S1_Related_Lead__c = params.get('leadId');
			if (String.isNotBlank(params.get('opptId'))) this.Efq.S1_Related_Opportunity__c = params.get('opptId');
			
		} else {
			
			// Existing record
			this.IsNew = false;
			this.Efq = [
				SELECT	e.Id, e.Name,
						e.S1_Related_Lead__c, e.S1_Related_Opportunity__c, e.S1_Related_Account__c, e.S1_Related_Contact__c,
						e.S1_Individual_Name_Calc__c, e.S1_Organization_Name_Calc__c, e.S1_Individual_Title_Calc__c, e.S1_Individual_Email_Calc__c,
						e.S1_Sell_to_Sectors__c, e.S1_Project_Sites__c, e.S1_Project_Employees__c, e.S1_Organization_Sectors__c, e.S1_Other_Sectors__c, 
						e.S1_Organization_Employees__c, 
						e.S2_Strategic_Goals__c, e.S2_Risks__c, e.S2_Opportunities__c, e.S2_Motivation_Waste__c, e.S2_Motivation_Tender__c, e.S2_Motivation_Risk__c, e.S2_Motivation_Protect__c, e.S2_Motivation_Personal__c, e.S2_Motivation_Other__c, e.S2_Motivation_Other_Text__c, e.S2_Motivation_Mistakes__c, e.S2_Motivation_Improve__c, e.S2_Motivation_Compliance__c, e.S2_Motivation_Attract__c, e.S2_Internal_Factors__c, e.S2_External_Factors__c, e.S2_Confidence__c,
						e.S2_Systems_Operational_Implemented__c, e.S2_Systems_Operational_Certified__c, e.S2_Systems_Operational_Future__c, 
						e.S2_Systems_Information_Implemented__c, e.S2_Systems_Information_Certified__c, e.S2_Systems_Information_Future__c, 
						e.S2_Systems_Other_Implemented__c, e.S2_Systems_Other_Certified__c, e.S2_Systems_Other_Future__c, e.S2_Other_Systems__c, 
						e.S3_Stages__c, e.S3_Target__c,
						e.S4_Systems_Score__c, e.S4_Systems_Notes__c, e.S4_Suppliers_Score__c, e.S4_Suppliers_Notes__c, e.S4_Management_Score__c, e.S4_Management_Notes__c, e.S4_Events_Score__c, e.S4_Events_Notes__c, e.S4_Evaluation_Score__c, e.S4_Evaluation_Notes__c, e.S4_Documentation_Score__c, e.S4_Documentation_Notes__c, e.S4_Competencies_Score__c, e.S4_Competencies_Notes__c, e.S4_Change_Score__c, e.S4_Change_Notes__c, e.S4_Audits_Score__c, e.S4_Audits_Notes__c, e.S4_Alignment_Score__c, e.S4_Alignment_Notes__c, S4_Chart_Position__c, 
						e.S5_Training_Public__c, e.S5_Training_Notes__c, e.S5_Training_In_house__c, e.S5_Standards__c, e.S5_Standards_Notes__c, e.S5_Other__c, e.S5_Other_Notes__c, e.S5_Improvement__c, e.S5_Improvement_Notes__c, e.S5_Certification__c, e.S5_Certification_Notes__c
				FROM	EfQuestionnaire__c e
				WHERE	e.Id = :std.getId()
			];
			
			// Parse current values
			Set<String> s1;
			Set<String> s2;
			Set<String> s3;

			s1 = String.isBlank(this.Efq.S1_Organization_Sectors__c) ? new Set<String>() : new Set<String>(this.Efq.S1_Organization_Sectors__c.split(';'));
			s2 = String.isBlank(this.Efq.S1_Sell_to_Sectors__c) ? new Set<String>() : new Set<String>(this.Efq.S1_Sell_to_Sectors__c.split(';'));
			for (CheckOption co : this.MySectors) {
				co.Checked[0] = s1.contains(co.Value);
				co.Checked[1] = s2.contains(co.Value);
			}

			s1 = String.isBlank(this.Efq.S1_Organization_Employees__c) ? new Set<String>() : new Set<String> { this.Efq.S1_Organization_Employees__c };
			s2 = String.isBlank(this.Efq.S1_Project_Employees__c) ? new Set<String>() : new Set<String> { this.Efq.S1_Project_Employees__c };
			for (CheckOption co : this.MySizes) {
				co.Checked[0] = s1.contains(co.Value);
				co.Checked[1] = s2.contains(co.Value);
			}

			s1 = String.isBlank(this.Efq.S2_Systems_Operational_Implemented__c) ? new Set<String>() : new Set<String>(this.Efq.S2_Systems_Operational_Implemented__c.split(';'));
			s2 = String.isBlank(this.Efq.S2_Systems_Operational_Certified__c) ? new Set<String>() : new Set<String>(this.Efq.S2_Systems_Operational_Certified__c.split(';'));
			s3 = String.isBlank(this.Efq.S2_Systems_Operational_Future__c) ? new Set<String>() : new Set<String>(this.Efq.S2_Systems_Operational_Future__c.split(';'));
			for (CheckOption co : this.MySystemsOperational) {
				co.Checked[0] = s1.contains(co.Value);
				co.Checked[1] = s2.contains(co.Value);
				co.Checked[2] = s3.contains(co.Value);
			}

			s1 = String.isBlank(this.Efq.S2_Systems_Information_Implemented__c) ? new Set<String>() : new Set<String>(this.Efq.S2_Systems_Information_Implemented__c.split(';'));
			s2 = String.isBlank(this.Efq.S2_Systems_Information_Certified__c) ? new Set<String>() : new Set<String>(this.Efq.S2_Systems_Information_Certified__c.split(';'));
			s3 = String.isBlank(this.Efq.S2_Systems_Information_Future__c) ? new Set<String>() : new Set<String>(this.Efq.S2_Systems_Information_Future__c.split(';'));
			for (CheckOption co : this.MySystemsInformation) {
				co.Checked[0] = s1.contains(co.Value);
				co.Checked[1] = s2.contains(co.Value);
				co.Checked[2] = s3.contains(co.Value);
			}

			s1 = String.isBlank(this.Efq.S2_Systems_Other_Implemented__c) ? new Set<String>() : new Set<String>(this.Efq.S2_Systems_Other_Implemented__c.split(';'));
			s2 = String.isBlank(this.Efq.S2_Systems_Other_Certified__c) ? new Set<String>() : new Set<String>(this.Efq.S2_Systems_Other_Certified__c.split(';'));
			s3 = String.isBlank(this.Efq.S2_Systems_Other_Future__c) ? new Set<String>() : new Set<String>(this.Efq.S2_Systems_Other_Future__c.split(';'));
			for (CheckOption co : this.MySystemsOther) {
				co.Checked[0] = s1.contains(co.Value);
				co.Checked[1] = s2.contains(co.Value);
				co.Checked[2] = s3.contains(co.Value);
			}

			s1 = String.isBlank(this.Efq.S5_Standards__c) ? new Set<String>() : new Set<String>(this.Efq.S5_Standards__c.split(';'));
			for (CheckOption co : this.MyStandards) co.Checked[0] = s1.contains(co.Value);

			s1 = String.isBlank(this.Efq.S5_Training_Public__c) ? new Set<String>() : new Set<String>(this.Efq.S5_Training_Public__c.split(';'));
			s2 = String.isBlank(this.Efq.S5_Training_In_house__c) ? new Set<String>() : new Set<String>(this.Efq.S5_Training_In_house__c.split(';'));
			for (CheckOption co : this.MyTraining) {
				co.Checked[0] = s1.contains(co.Value);
				co.Checked[1] = s2.contains(co.Value);
			}

			s1 = String.isBlank(this.Efq.S5_Improvement__c) ? new Set<String>() : new Set<String>(this.Efq.S5_Improvement__c.split(';'));
			for (CheckOption co : this.MyImprovement) co.Checked[0] = s1.contains(co.Value);

			s1 = String.isBlank(this.Efq.S5_Certification__c) ? new Set<String>() : new Set<String>(this.Efq.S5_Certification__c.split(';'));
			for (CheckOption co : this.MyCertification) co.Checked[0] = s1.contains(co.Value);

			s1 = String.isBlank(this.Efq.S5_Other__c) ? new Set<String>() : new Set<String>(this.Efq.S5_Other__c.split(';'));
			for (CheckOption co : this.MyOther) co.Checked[0] = s1.contains(co.Value);
			
			// Build data
			List<ChartPoint> d = new List<ChartPoint>();
			d.add(new ChartPoint(10, 8.561053414, -100, (this.Efq.S4_Chart_Position__c == 10 ? 8.561053414 : -100), '. Your Organization'));
			d.add(new ChartPoint(10.25, 8.782073765, -100, -100, ''));
			d.add(new ChartPoint(10.5, 9.014179603, -100, -100, ''));
			d.add(new ChartPoint(10.75, 9.258158943, -100, -100, ''));
			d.add(new ChartPoint(11, 9.514922867, -100, (this.Efq.S4_Chart_Position__c == 11 ? 9.514922867 : -100), '. Your Organization'));
			d.add(new ChartPoint(11.25, 9.785533906, -100, -100, ''));
			d.add(new ChartPoint(11.5, 10.07124353, -100, -100, ''));
			d.add(new ChartPoint(11.75, 10.3735426, -100, -100, ''));
			d.add(new ChartPoint(12, 10.69423075, -100, (this.Efq.S4_Chart_Position__c == 12 ? 10.69423075 : -100), '. Your Organization'));
			d.add(new ChartPoint(12.25, 11.03551422, -100, -100, ''));
			d.add(new ChartPoint(12.5, 11.40014777, -100, -100, ''));
			d.add(new ChartPoint(12.75, 11.79164804, -100, -100, ''));
			d.add(new ChartPoint(13, 12.21462765, -100, (this.Efq.S4_Chart_Position__c == 13 ? 12.21462765 : -100), '. Your Organization'));
			d.add(new ChartPoint(13.25, 12.67534657, -100, -100, ''));
			d.add(new ChartPoint(13.5, 13.18268331, -100, -100, ''));
			d.add(new ChartPoint(13.75, 13.75, 13.75, -100, '. Necessary Evil'));
			d.add(new ChartPoint(14, 14.31731669, -100, (this.Efq.S4_Chart_Position__c == 14 ? 14.31731669 : -100), '. Your Organization'));
			d.add(new ChartPoint(14.25, 14.82465343, -100, -100, ''));
			d.add(new ChartPoint(14.5, 15.28537235, -100, -100, ''));
			d.add(new ChartPoint(14.75, 15.70835196, -100, -100, ''));
			d.add(new ChartPoint(15, 16.09985223, -100, (this.Efq.S4_Chart_Position__c == 15 ? 16.09985223 : -100), '. Your Organization'));
			d.add(new ChartPoint(15.25, 16.46448578, -100, -100, ''));
			d.add(new ChartPoint(15.5, 16.80576925, -100, -100, ''));
			d.add(new ChartPoint(15.75, 17.1264574, -100, -100, ''));
			d.add(new ChartPoint(16, 17.42875647, -100, (this.Efq.S4_Chart_Position__c == 16 ? 17.42875647 : -100), '. Your Organization'));
			d.add(new ChartPoint(16.25, 17.71446609, -100, -100, ''));
			d.add(new ChartPoint(16.5, 17.98507713, -100, -100, ''));
			d.add(new ChartPoint(16.75, 18.24184106, -100, -100, ''));
			d.add(new ChartPoint(17, 18.4858204, -100, (this.Efq.S4_Chart_Position__c == 17 ? 18.4858204 : -100), '. Your Organization'));
			d.add(new ChartPoint(17.25, 18.71792623, -100, -100, ''));
			d.add(new ChartPoint(17.5, 18.93894659, -100, -100, ''));
			d.add(new ChartPoint(17.75, 19.14956824, -100, -100, ''));
			d.add(new ChartPoint(18, 19.3503938, -100, (this.Efq.S4_Chart_Position__c == 18 ? 19.3503938 : -100), '. Your Organization'));
			d.add(new ChartPoint(18.25, 19.54195523, -100, -100, ''));
			d.add(new ChartPoint(18.5, 19.7247246, -100, -100, ''));
			d.add(new ChartPoint(18.75, 19.89912284, -100, -100, ''));
			d.add(new ChartPoint(19, 20.06552692, -100, (this.Efq.S4_Chart_Position__c == 19 ? 20.06552692 : -100), '. Your Organization'));
			d.add(new ChartPoint(19.25, 20.22427569, -100, -100, ''));
			d.add(new ChartPoint(19.5, 20.37567478, -100, -100, ''));
			d.add(new ChartPoint(19.75, 20.52000069, -100, -100, ''));
			d.add(new ChartPoint(20, 20.65750422, -100, (this.Efq.S4_Chart_Position__c == 20 ? 20.65750422 : -100), '. Your Organization'));
			d.add(new ChartPoint(20.25, 20.78841341, -100, -100, ''));
			d.add(new ChartPoint(20.5, 20.91293601, -100, -100, ''));
			d.add(new ChartPoint(20.75, 21.03126159, -100, -100, ''));
			d.add(new ChartPoint(21, 21.14356342, -100, (this.Efq.S4_Chart_Position__c == 21 ? 21.14356342 : -100), '. Your Organization'));
			d.add(new ChartPoint(21.25, 21.25, 21.25, -100, '. Grass Roots'));
			d.add(new ChartPoint(21.5, 21.35643658, -100, -100, ''));
			d.add(new ChartPoint(21.75, 21.46873841, -100, -100, ''));
			d.add(new ChartPoint(22, 21.58706399, -100, (this.Efq.S4_Chart_Position__c == 22 ? 21.58706399 : -100), '. Your Organization'));
			d.add(new ChartPoint(22.25, 21.71158659, -100, -100, ''));
			d.add(new ChartPoint(22.5, 21.84249578, -100, -100, ''));
			d.add(new ChartPoint(22.75, 21.97999931, -100, -100, ''));
			d.add(new ChartPoint(23, 22.12432522, -100, (this.Efq.S4_Chart_Position__c == 23 ? 22.12432522 : -100), '. Your Organization'));
			d.add(new ChartPoint(23.25, 22.27572431, -100, -100, ''));
			d.add(new ChartPoint(23.5, 22.43447308, -100, -100, ''));
			d.add(new ChartPoint(23.75, 22.60087716, -100, -100, ''));
			d.add(new ChartPoint(24, 22.7752754, -100, (this.Efq.S4_Chart_Position__c == 24 ? 22.7752754 : -100), '. Your Organization'));
			d.add(new ChartPoint(24.25, 22.95804477, -100, -100, ''));
			d.add(new ChartPoint(24.5, 23.1496062, -100, -100, ''));
			d.add(new ChartPoint(24.75, 23.35043176, -100, -100, ''));
			d.add(new ChartPoint(25, 23.56105341, -100, (this.Efq.S4_Chart_Position__c == 25 ? 23.56105341 : -100), '. Your Organization'));
			d.add(new ChartPoint(25.25, 23.78207377, -100, -100, ''));
			d.add(new ChartPoint(25.5, 24.0141796, -100, -100, ''));
			d.add(new ChartPoint(25.75, 24.25815894, -100, -100, ''));
			d.add(new ChartPoint(26, 24.51492287, -100, (this.Efq.S4_Chart_Position__c == 26 ? 24.51492287 : -100), '. Your Organization'));
			d.add(new ChartPoint(26.25, 24.78553391, -100, -100, ''));
			d.add(new ChartPoint(26.5, 25.07124353, -100, -100, ''));
			d.add(new ChartPoint(26.75, 25.3735426, -100, -100, ''));
			d.add(new ChartPoint(27, 25.69423075, -100, (this.Efq.S4_Chart_Position__c == 27 ? 25.69423075 : -100), '. Your Organization'));
			d.add(new ChartPoint(27.25, 26.03551422, -100, -100, ''));
			d.add(new ChartPoint(27.5, 26.40014777, -100, -100, ''));
			d.add(new ChartPoint(27.75, 26.79164804, -100, -100, ''));
			d.add(new ChartPoint(28, 27.21462765, -100, (this.Efq.S4_Chart_Position__c == 28 ? 27.21462765 : -100), '. Your Organization'));
			d.add(new ChartPoint(28.25, 27.67534657, -100, -100, ''));
			d.add(new ChartPoint(28.5, 28.18268331, -100, -100, ''));
			d.add(new ChartPoint(28.75, 28.75, 28.75, -100, '. Embraced'));
			d.add(new ChartPoint(29, 29.31731669, -100, (this.Efq.S4_Chart_Position__c == 29 ? 29.31731669 : -100), '. Your Organization'));
			d.add(new ChartPoint(29.25, 29.82465343, -100, -100, ''));
			d.add(new ChartPoint(29.5, 30.28537235, -100, -100, ''));
			d.add(new ChartPoint(29.75, 30.70835196, -100, -100, ''));
			d.add(new ChartPoint(30, 31.09985223, -100, (this.Efq.S4_Chart_Position__c == 30 ? 31.09985223 : -100), '. Your Organization'));
			d.add(new ChartPoint(30.25, 31.46448578, -100, -100, ''));
			d.add(new ChartPoint(30.5, 31.80576925, -100, -100, ''));
			d.add(new ChartPoint(30.75, 32.1264574, -100, -100, ''));
			d.add(new ChartPoint(31, 32.42875647, -100, (this.Efq.S4_Chart_Position__c == 31 ? 32.42875647 : -100), '. Your Organization'));
			d.add(new ChartPoint(31.25, 32.71446609, -100, -100, ''));
			d.add(new ChartPoint(31.5, 32.98507713, -100, -100, ''));
			d.add(new ChartPoint(31.75, 33.24184106, -100, -100, ''));
			d.add(new ChartPoint(32, 33.4858204, -100, (this.Efq.S4_Chart_Position__c == 32 ? 33.4858204 : -100), '. Your Organization'));
			d.add(new ChartPoint(32.25, 33.71792623, -100, -100, ''));
			d.add(new ChartPoint(32.5, 33.93894659, -100, -100, ''));
			d.add(new ChartPoint(32.75, 34.14956824, -100, -100, ''));
			d.add(new ChartPoint(33, 34.3503938, -100, (this.Efq.S4_Chart_Position__c == 33 ? 34.3503938 : -100), '. Your Organization'));
			d.add(new ChartPoint(33.25, 34.54195523, -100, -100, ''));
			d.add(new ChartPoint(33.5, 34.7247246, -100, -100, ''));
			d.add(new ChartPoint(33.75, 34.89912284, -100, -100, ''));
			d.add(new ChartPoint(34, 35.06552692, -100, (this.Efq.S4_Chart_Position__c == 34 ? 35.06552692 : -100), '. Your Organization'));
			d.add(new ChartPoint(34.25, 35.22427569, -100, -100, ''));
			d.add(new ChartPoint(34.5, 35.37567478, -100, -100, ''));
			d.add(new ChartPoint(34.75, 35.52000069, -100, -100, ''));
			d.add(new ChartPoint(35, 35.65750422, -100, (this.Efq.S4_Chart_Position__c == 35 ? 35.65750422 : -100), '. Your Organization'));
			d.add(new ChartPoint(35.25, 35.78841341, -100, -100, ''));
			d.add(new ChartPoint(35.5, 35.91293601, -100, -100, ''));
			d.add(new ChartPoint(35.75, 36.03126159, -100, -100, ''));
			d.add(new ChartPoint(36, 36.14356342, -100, (this.Efq.S4_Chart_Position__c == 36 ? 36.14356342 : -100), '. Your Organization'));
			d.add(new ChartPoint(36.25, 36.25, 36.25, -100, '. Embedded'));
			d.add(new ChartPoint(36.5, -100, -100, 36.35643658, ''));
			d.add(new ChartPoint(36.75, -100, -100, 36.46873841, ''));
			d.add(new ChartPoint(37, 36.58706399, -100, (this.Efq.S4_Chart_Position__c == 37 ? 36.58706399 : -100), '. Your Organization'));
			d.add(new ChartPoint(37.25, 36.71158659, -100, -100, ''));
			d.add(new ChartPoint(37.5, 36.84249578, -100, -100, ''));
			d.add(new ChartPoint(37.75, 36.97999931, -100, -100, ''));
			d.add(new ChartPoint(38, 37.12432522, -100, (this.Efq.S4_Chart_Position__c == 38 ? 37.12432522 : -100), '. Your Organization'));
			d.add(new ChartPoint(38.25, 37.27572431, -100, -100, ''));
			d.add(new ChartPoint(38.5, 37.43447308, -100, -100, ''));
			d.add(new ChartPoint(38.75, 37.60087716, -100, -100, ''));
			d.add(new ChartPoint(39, 37.7752754, -100, (this.Efq.S4_Chart_Position__c == 39 ? 37.7752754 : -100), '. Your Organization'));
			d.add(new ChartPoint(39.25, 37.95804477, -100, -100, ''));
			d.add(new ChartPoint(39.5, 38.1496062, -100, -100, ''));
			d.add(new ChartPoint(39.75, 38.35043176, -100, -100, ''));
			d.add(new ChartPoint(40, 38.56105341, -100, (this.Efq.S4_Chart_Position__c == 40 ? 38.56105341 : -100), '. Your Organization'));
			this.Chart1 = d;
		}
	}
	
	public PageReference CustomSave() {
		
		// Build new values
		String s1;
		String s2;
		String s3;

		s1 = '';
		s2 = '';
		for (CheckOption co : this.MySectors) {
			if (co.Checked[0]) s1 += co.Value + ';';
			if (co.Checked[1]) s2 += co.Value + ';';
		}
		this.Efq.S1_Organization_Sectors__c = s1;
		this.Efq.S1_Sell_to_Sectors__c = s2;

		s1 = '';
		s2 = '';
		for (CheckOption co : this.MySizes) {
			if (co.Checked[0]) s1 = co.Value;
			if (co.Checked[1]) s2 = co.Value;
		}
		this.Efq.S1_Organization_Employees__c = s1;
		this.Efq.S1_Project_Employees__c = s2;

		s1 = '';
		s2 = '';
		s3 = '';
		for (CheckOption co : this.MySystemsOperational) {
			if (co.Checked[0]) s1 += co.Value + ';';
			if (co.Checked[1]) s2 += co.Value + ';';
			if (co.Checked[2]) s3 += co.Value + ';';
		}
		this.Efq.S2_Systems_Operational_Implemented__c = s1;
		this.Efq.S2_Systems_Operational_Certified__c = s2;
		this.Efq.S2_Systems_Operational_Future__c = s2;

		s1 = '';
		s2 = '';
		s3 = '';
		for (CheckOption co : this.MySystemsInformation) {
			if (co.Checked[0]) s1 += co.Value + ';';
			if (co.Checked[1]) s2 += co.Value + ';';
			if (co.Checked[2]) s3 += co.Value + ';';
		}
		this.Efq.S2_Systems_Information_Implemented__c = s1;
		this.Efq.S2_Systems_Information_Certified__c = s2;
		this.Efq.S2_Systems_Information_Future__c = s2;

		s1 = '';
		s2 = '';
		s3 = '';
		for (CheckOption co : this.MySystemsOther) {
			if (co.Checked[0]) s1 += co.Value + ';';
			if (co.Checked[1]) s2 += co.Value + ';';
			if (co.Checked[2]) s3 += co.Value + ';';
		}
		this.Efq.S2_Systems_Other_Implemented__c = s1;
		this.Efq.S2_Systems_Other_Certified__c = s2;
		this.Efq.S2_Systems_Other_Future__c = s2;

		s1 = '';
		for (CheckOption co : this.MyStandards) if (co.Checked[0]) s1 += co.Value + ';';
		this.Efq.S5_Standards__c = s1;

		s1 = '';
		s2 = '';
		for (CheckOption co : this.MyTraining) {
			if (co.Checked[0]) s1 += co.Value + ';';
			if (co.Checked[1]) s2 += co.Value + ';';
		}
		this.Efq.S5_Training_Public__c = s1;
		this.Efq.S5_Training_In_house__c = s2;

		s1 = '';
		for (CheckOption co : this.MyImprovement) if (co.Checked[0]) s1 += co.Value + ';';
		this.Efq.S5_Improvement__c = s1;

		s1 = '';
		for (CheckOption co : this.MyCertification) if (co.Checked[0]) s1 += co.Value + ';';
		this.Efq.S5_Certification__c = s1;

		s1 = '';
		for (CheckOption co : this.MyOther) if (co.Checked[0]) s1 += co.Value + ';';
		this.Efq.S5_Other__c = s1;

		// Insert or update?		
		if (this.IsNew) {
			
			// Insert
			Database.SaveResult sr = Database.insert(this.Efq, false);
			if (!sr.isSuccess()) {
				for (Database.Error e : sr.getErrors()) ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
    			return null;
			}
			
		} else {
			
			// Update
			Database.SaveResult sr = Database.update(this.Efq, false);
			if (!sr.isSuccess()) {
				for (Database.Error e : sr.getErrors()) ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
    			return null;
			}
		}
		
		// Jump to view page
		PageReference redirectPage = Page.EfQuestionnaireView;
    	redirectPage.setRedirect(true);
    	redirectPage.getParameters().put('id', this.Efq.Id);
    	redirectPage.getParameters().put('sfdc.override', '1');
    	return redirectPage;
	}

    public class CheckOption {
    	public String Value { get; set; }
    	public String Label { get; set; }
    	public List<Boolean> Checked { get; set; }
    	
    	public CheckOption(String v, String l, List<Boolean> c) {
    		this.Value = v;
    		this.Label = l;
    		this.Checked = c;
    	}
	}
	
	public class ChartPoint {
		public Decimal Score { get; set; }
		public Decimal Line { get; set; }
		public Decimal Milestone { get; set; }
		public Decimal Position { get; set; }
		public String Description { get; set; }
		
		public ChartPoint(Decimal s, Decimal l, Decimal m, Decimal p, String d) {
			this.Score = s;
			this.Line = l;
			this.Milestone = m;
			this.Position = p;
			this.Description = d;
		}
	}
}