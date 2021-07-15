options source source2 msglevel=I SYMBOLGEN=1 mprint=1 spool;
libname datain "E:\pro_Brian_k08\data\input";

%MACRO aha(yr, year);
LIBNAME aha&yr "Z:\mgmt-e\Working_Data\Resources\Provider\AHA_American_Hosp_Assoc_Survey\SAS_Data_Files\AHA&year";
 DATA aha&yr (keep = PRVNUMGRP AHAID prov_npi zip year 
					 /* 1. Teaching status */ 	provteach provteach_all provteach_minor
					 /* 2. nurse2??? ratios */ 	rntopt RN_BED_ratio nurse_ratio nurse_ratio2 
					 /* 3. Bed size */ 			bedsize_cat beds_lt200 beds_200_349 beds_350_499 beds_ge500 bedsize_cat2 beds_lt250 beds_250_499
					 /* 4. Region */ 			region_ne  region_west region_midwest region_south region_cat
					 /* 5. Urban vs rural */ 	urban cbsa_rural cbsa_urban
					 /* 6. Critical access */ 	CriticalAH 
					 /* 7. Cancer hospital */	NCI_hosp 
					 /* 8. Medicaid days/tot facility inpatient days  */ mcdipdtoipdtot 
					 /* 9. Profit status */		profit for_profit non_profit other_profit
					 /* 10. Technology hosp */ 	tech_hosp 
					 /* 11. Transplant svc */	Transplant_serv 
					 /* 12. Transplant hosp */	Transplant_hosp 
					 /* 13. Technology hosp as adult cardiac services or transplant services */	 Tech_Cardiac_Transplant
					 /* 14. Medical or surgical intensive care */  MedSurg_HospICU MedSurg_HlthsysICU MedSurg_NWICU
					 /* 15. Trauma centers levels*/ TRAUML90_cat trauma_level1 trauma_level2 trauma_level3 trauma_level45
				);
 SET aha&yr..aha_&year;

	LENGTH PRVNUMGRP $6. zip $5. prov_npi 8.;

	year = &year;
	zip=(substr(MLOCZIP, 1, 5)); 
	AHAID = ID;

	/* prov_npi: No NPI in 2005-2007 */
	IF year in (2008) THEN DO;
		prov_npi = input(compress(NPI_NUM), 10.);
	END;
	IF year in (2009,2010,2011,2012,2013,2014,2015,2016,2017) THEN DO;
		prov_npi = input(compress(NPINUM), 10.);
	END;


	/* PRVNUMGRP */
	IF year in (2005,2006,2007) THEN DO;
		PRVNUMGRP = hcfaid;
		drop hcfaid;
	END; ELSE
	IF year in (2008, 2009,2010,2011,2012,2013,2014,2015,2016,2017) THEN DO;
		PRVNUMGRP = MCRNUM;
		drop MCRNUM;
	END;


	/* 1. Teaching status:
		mapp3: Residency training approval by Accreditation Council for Graduate Medical Education
		mapp5: Medical school affiliation reported to American Medical Association
		mapp8: Member of Council of Teaching Hospital of the Association of American Medical Colleges (COTH)
		mapp12: Internship approved by American Osteopathic Association
		mapp13: Residency approved by American Osteopathic Association
	*/
		* 1a: Using only mapp8;
		if mapp8=1       then provteach=1;
		else if mapp8=2  then provteach=0;
		else provteach=.;

		* 1b: Using all five variables;
		if coalesce(mapp3, mapp5, mapp8, mapp12, mapp13) ^= '' then do;
			if  mapp3='1' or 
				mapp5='1' or 
				mapp8='1' or 
				mapp12='1' or 
				mapp13='1' 
			then provteach_all=1;
			else provteach_all=0;
		end;

		* 1c: Using four variables;	
		if coalesce(mapp3, mapp5, mapp12, mapp13) ^= '' then do; 
			if  mapp3='1' or 
				mapp5='1' or 
				mapp12='1' or 
				mapp13='1' 
			then provteach_minor=1;
			else provteach_minor=0;
		end;

	/* 2. Nurse to ??? ratio */
		/* nurse to adjusted inpatient days/Number of Days in Reporting Period ratio (better variable than nurse to bed ratio) */
		if adjadc gt 0 then rntopt=ftern/adjadc;

		/* nurse to inpatient days ratio */
		if ipdtot>0 then nurse_ratio2=ftern/ipdtot*1000;
		if ipdtot>0 then nurse_ratio=round(ftern/ipdtot, .01);
		
		
		/* full time registered nurse to bed ratio */
		if HOSPBD gt 0 then RN_BED_ratio=round(FTERN/HOSPBD, .01) ;
		

	/* 3. Bed size */
		/* 3a. bed size - <200, 200-349, 350-499, >/=500 */
		if not missing(hospbd) then do;  
			if hospbd lt 200 then bedsize_cat=1; else 
			if 200 le hospbd le 349 then bedsize_cat=2; else 
			if 350 le hospbd le 499 then bedsize_cat=3; else 
			if hospbd ge 500 then bedsize_cat=4;

			beds_lt200		=(bedsize_cat=1);
			beds_200_349	=(bedsize_cat=2);
			beds_350_499	=(bedsize_cat=3);
			beds_ge500		=(bedsize_cat=4);
		end;
		label bedsize_cat="Bedsize: 1.<200, 2.200-349, 3.350-499, 4.>=500";

		/* 3b. bed size - <250, 250-500, >/=500 */
		if not missing (hospbd) then do;
			if hospbd lt 250 then bedsize_cat2=1; else 
			if 250 le hospbd lt 500 then bedsize_cat2=2; else 
		    if hospbd ge 500 then bedsize_cat2=3; 

			beds_lt250 		=(bedsize_cat2=1);
			beds_250_499	=(bedsize_cat2=2);
		end;
		label bedsize_cat2="Bedsize: 1.<250, 2.250-499, 3.>=500";

	/* 4. Regions  */
		  region=substr(ID,2,1);
		   if region in ('1','2') 			then region_ne 		= 1;  else region_ne 		= 0;
		   if region in ('8', '9') 			then region_west 	= 1;  else region_west 		= 0;
		   if region in ('4','6') 			then region_midwest = 1;  else region_midwest	= 0;
		   if region in ('3','5','7','0') 	then region_south 	= 1;  else region_south 	= 0;

		   length region_cat $10. ;
		   if region in ('1','2') then region_cat='North-East'; else 
		   if region in ('8','9') then region_cat='West'; else 
		   if region in ('4','6') then region_cat='Mid-west'; else 
		   region_cat='South';

	/* 5. Urban vs rural */
	
		/* 5a.  urban vs. rural */
		if year in (2008) then do;
			if not missing(rrctr) then do;
			if rrctr='1' then urban=0;
			else urban=1;
			end;
		end;
		if year in (2005, 2006, 2007, 2009,2010,2011,2012,2013,2014,2015,2016, 2017) then do;
			if not missing(MAPP19) then do;
				if MAPP19='1' then urban=0;
				else urban=1;
			end;
		end;

		/* 5b. using cbsa (Core-Based Statistical Areas) type: Metro, Micro, Division, Rural; Source: U.S. Census Bureau */
		if not missing(CBSAtype) then do;
			if cbsatype in ('Rural') then cbsa_rural=1; else cbsa_rural=0;
			if cbsatype not in ('Rural') then cbsa_urban=1; else cbsa_urban=0;
		end;

	/* 6. Critical access hospital */

	   if year in (2005, 2006, 2007, 2008) then do;
		 if CAH='1' then CriticalAH=1; else 
		 if CAH='2' then CriticalAH=0;
	   end;

	   if year in (2009,2010,2011,2012,2013,2014,2015,2016,2017) then do;
		 if mapp18='1' then CriticalAH=1; else 
		 if mapp18='2' then CriticalAH=0;
		end;

	/* 7. Cancer hospital (SERV='41') or cancer program approved by ACS (MAPP2=1) */
		if not missing(serv) or not missing(mapp2) then do;
			if serv='41' or mapp2='1' then NCI_hosp=1; else NCI_hosp=0;
		end;
		label NCI_hosp="1.Cancer hosp/Cancer program approved by ACS, 0.Non-Cancer hosp";

	/* 8. Total facility medicaid days/total facility inpatient days */
		if ipdtot>0 then mcdipdtoipdtot=round(mcdipd/ipdtot, .01);

	/* 9. Profit status - using cntrl, mcntrl. Don't have govt variable in 2005. could use 2006/07 later */ 
		 	if year in (2005,2006,2007,2008) then do;
				if cntrl in ('30','31','32','33') 	or mcntrl in ('30','31','32','33') 	then profit=1; else 
				if cntrl in ('21','22','23') 		or mcntrl in ('21','22','23') 		then profit=2;
				else profit=3;
			end;

		 	if year in (2009,2010,2011,2012,2013,2014,2015,2016,2017) then do;
				if cntrl in (30,31,32,33)  then profit=1; else 
				if cntrl in (21,22,23) then profit=2;
				else profit=3;
			end;

			label profit="Profit satus: 1.for-profit, 2.not-for-profit, 3-other";

			for_profit	=(profit=1);
			non_profit	=(profit=2);
			other_profit=(profit=3);

	
	if year in (2009,2010,2011,2012) then do;

	   /* 10a. Technology hospital */
			if coalesce(ADTCHOS, ADTCSYS, ADTCVEN) ^= '' then 
				tech_hosp =(ADTCHOS='1' or ADTCSYS='1'  or ADTCVEN='1');

		/* 11a. Any transplant service */
		if coalesce( OTBONHOS, 	OTBONSYS, 	OTBONVEN, 
					 HARTHOS, 	HARTSYS, 	HARTVEN,
					 KDNYHOS, 	KDNYSYS, 	KDNYVEN,
					 LIVRHOS, 	LIVRSYS, 	LIVRVEN,
					 LUNGHOS, 	LUNGSYS, 	LUNGVEN,
					 TISUHOS, 	TISUSYS, 	TISUVEN,
					 OTOTHHOS,	OTOTHSYS, 	OTOTHVEN) ^= '' then do ;

			Transplant_serv=(OTBONHOS='1' 	or OTBONSYS='1' 	or OTBONVEN='1' 	or 
							 HARTHOS='1' 	or HARTSYS='1' 		or HARTNET='1' 		or
							 KDNYHOS='1' 	or KDNYSYS='1' 		or KDNYVEN='1' 		or 
							 LIVRHOS='1' 	or LIVRSYS='1'  	or LIVRVEN='1' 		or
							 LUNGHOS='1' 	or LUNGSYS='1' 		or LUNGVEN='1' 		or 
							 TISUHOS='1' 	or TISUSYS='1'  	or TISUVEN='1' 		or
							 OTOTHHOS='1' 	or OTOTHSYS='1' 	or OTOTHVEN='1'); 
			end;
	end;

	if year in (2005,2006,2007,2008,2013,2014,2015,2016,2017) then do;
		/*10b.  technology hospital */
			if coalesce(ADTCHOS, ADTCSYS, ADTCVEN, ADTCNET) ^= '' then 
				tech_hosp =(ADTCHOS='1' or ADTCSYS='1'  or ADTCVEN='1' or ADTCNET='1');

		/*11b.  Any transplant service */
		if coalesce( OTBONHOS, 	OTBONSYS, 	OTBONVEN,	OTBONNET,
					 HARTHOS, 	HARTSYS, 	HARTVEN,	HARTNET,
					 KDNYHOS, 	KDNYSYS, 	KDNYVEN,	KDNYNET,
					 LIVRHOS, 	LIVRSYS, 	LIVRVEN,	LIVRNET,
					 LUNGHOS, 	LUNGSYS, 	LUNGVEN,	LUNGNET,
					 TISUHOS, 	TISUSYS, 	TISUVEN,	TISUNET,
					 OTOTHHOS,	OTOTHSYS, 	OTOTHVEN, 	OTOTHNET) ^= '' then do ;

			Transplant_serv=(OTBONHOS='1' 	or OTBONSYS='1' or OTBONVEN='1'	or OTBONNET='1' or 
							 HARTHOS='1' 	or HARTSYS='1' 	or HARTNET='1' 	or HARTVEN='1'	or
							 KDNYHOS='1' 	or KDNYSYS='1' 	or KDNYVEN='1' 	or KDNYNET='1'	or 
							 LIVRHOS='1' 	or LIVRSYS='1'  or LIVRVEN='1' 	or LIVRNET='1'	or
							 LUNGHOS='1' 	or LUNGSYS='1' 	or LUNGVEN='1' 	or LUNGNET='1'	or 
							 TISUHOS='1' 	or TISUSYS='1'  or TISUVEN='1' 	or TISUNET='1'	or
							 OTOTHHOS='1' 	or OTOTHSYS='1' or OTOTHVEN='1' or OTOTHNET='1'); 
			end;
	end;

	/*12.   Any transplant  hospital  */
		if coalesce(OTBONHOS, HARTHOS, KDNYHOS, LIVRHOS, LUNGHOS, TISUHOS, OTOTHHOS) ^= '' then do;
			Transplant_hosp=(OTBONHOS='1' or HARTHOS='1' or KDNYHOS='1' or LIVRHOS='1' or LUNGHOS='1' or TISUHOS='1' or OTOTHHOS='1'); 
		end;


	/* 13. Technology hosp as adult cardiac services or transplant services */
		if not missing(tech_hosp) or not missing(Transplant_hosp) then do;
			Tech_Cardiac_Transplant=(tech_hosp=1 or Transplant_hosp=1);
		end; 

	/* 14. Medical or surgical intensive care: 
			MSICBD        Num       8    BEDS, INTENSIVE CARE, MED/SURG
			MSICHOS       Char      1    MED/SURG INTENSIVE CARE HOSPITAL
			MSICNET       Char      1    MED/SURG INTENSIVE CARE NETWORK
			MSICSYS       Char      1    MED/SURG INTENSIVE CARE HLTH SYS
			MSICVEN       Char      1    MED/SURG INTENSIVE CARE JNT VENT
		*/
		if not missing(MSICHOS) then MedSurg_HospICU	=(MSICHOS in ('1'));
		if not missing(MSICSYS) then MedSurg_HlthsysICU	=(MSICSYS in ('1'));
		if not missing(MSICNET) then MedSurg_NWICU		=(MSICNET in ('1'));


	/* 15. Certified trauma centers levels:  TRAUMHOS TRAUMSYS TRAUMVEN 
			TRAUML90: 1=regional resource trauma center, 
					  2=community trauma center, 
					  3=rural trauma hospital, 
					  4 or greater=other (specific to some states)
	*/
			if not missing(TRAUML90) then do;
				if TRAUML90=1 then TRAUML90_cat=1; else 
				if TRAUML90=2 then TRAUML90_cat=2; else 
				if TRAUML90=3 then TRAUML90_cat=3; else 
				TRAUML90_cat=4;

				trauma_level1=(TRAUML90=1);
				trauma_level2=(TRAUML90=2);
				trauma_level3=(TRAUML90=3);
				trauma_level45=(TRAUML90 ge 4);
			end;
	PROC SORT;
	BY PRVNUMGRP;

RUN;

%mend;
%aha(05, 2005);
%aha(06, 2006);
%aha(07, 2007);
%aha(08, 2008);
%aha(09, 2009);
%aha(10, 2010);
%aha(11, 2011);
%aha(12, 2012);
%aha(13, 2013);
%aha(14, 2014);
%aha(15, 2015);
%aha(16, 2016);
%aha(17, 2017);

/* Get a single data across years  */
	data datain.aha_hosp_05_17;
	set aha05-aha17;
	run;

