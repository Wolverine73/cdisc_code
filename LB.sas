/*STUDY					: 
PROGRAM					: LB.sas 
SAS VERSION				: 9.4
DESCRIPTION				: To generate LB (SDTM) dataset as per CDISC standard by using raw DM & LB dataset. 
And to also validate it with primary demographic dataset by writing independent code in SAS.
AUTHOR					: Adeyemo Olamide
DATE COMPLETED			: 7/26/2023
PROGRAM INPUT			: LB.sas7bdat DM.sas7bdat
PROGRAM OUTPUT			:  
PROGRAM LOG				: lab.log
EXTERNAL MACROS CALLED	: None
EXTERNAL CODE CALLED	: LB.sas

LIMITATIONS				: None

PROGRAM ALGORITHM:
	Step 01: Setup macro variables, drive, project and protocol.            
   	Step 02: Define filename/libname for protocol.  
	Step 03: Define global options.
	Step 04: Include format files. 

REVISIONS: 					
	1. DD/MM/YYYY - Name (First Last) - Description of revision 1
	2. DD/MM/YYYY - Name (First Last) - Description of revision 2
------------------------------------------------------------------------*/
*----------------------------------------------------------------*;
*- Step 01: Setup macro variables, drive, project and protocol. -*;
*----------------------------------------------------------------*;
%include "/home/u63305369/02.SDTM Dataset Development(Laboratory)/work/03utility/initial.sas~";
proc printto log = "&logdir/lb.log";



proc sort data=rawdata.dm out=dmf1;
by usubjid;
run;

****generating usubjid for lab;
data l1;
set rawdata.lab;
prot1= substr(prot, 1, 6);
prot2= substr(prot, 8, 3);
protx= put(prot1, 6.) || put(prot2, 3.0);
run;

****generating usubjid for lab;
data lbfind;
set l1;
USUBJID= catx("-", protx, batch, pno);
drop prot1 prot2;
run;


*sort by usubjid;
proc sort data=lbfind out=lbfind1;
by usubjid;
run;

***merging lab and dm by usubjid;
data lab;
merge lbfind1 dmf1;
by usubjid;
drop pno batch prot domain protx batch VORDER L_DIG_D YESCOMM LAB_ODAY R_VISD R_VISN SITEID
R_DIF protx visit L_DIG_U SIPVALUE SICVALUE;
run;
  
***** generaing controlled terminology for lbtest and lbtestcd;
data lab1;
length LBTESTCD $8 LBTEST $40;;
set lab; 

***generating "LB" domain and LBNAM;
if usubjid ne " " then do;
DOMAIN ="LB";
LBNAM= "WHITEBOARD";
END;
***** generaing controlled terminology for lbtest and lbtestcd;
if param = "ALT" then do;
LBTESTCD= "ALT";
LBTEST = "Alanine Aminotransferase";
end;

else if param = "AST" then do;
LBTESTCD="AST";
LBTEST = "Aspartate Aminotransferase";
end;

else if param = "ALKALINE PHOSPHATASE" then do;
LBTESTCD="ALP";
LBTEST = "Alkaline Phosphatase";
end;

else if param = "ALBUMIN" then do;
LBTESTCD="ALB";
LBTEST = "Albumin";
end;

else if param = "UREA" then do;
LBTESTCD="UREA";
LBTEST = "Urea";
end;

else if param = "HEMOGLOBIN" then do;
LBTESTCD="HGB";
LBTEST = "Hemoglobin";
end;

else if param = "BILIRUBIN TOTAL" then do;
LBTESTCD="BILI";
LBTEST = "Bilirubin";
end;

else if param = "BILIRUBIN DIRECT" then do;
LBTESTCD="BILDIR";
LBTEST = "Direct Bilirubin";
end;

else if param = "HEMATOCRIT" then do;
LBTESTCD="HCT";
LBTEST = "Hematocrit";
end;

else if param = "B-HCG, QUAL" then do;
LBTESTCD="HCG";
LBTEST = "Choriogonadotropin Beta";
end;

else if param = "ERYTHROCYTES" then do;
LBTESTCD="RBC";
LBTEST = "Erythrocytes";
end;

else if param = "LEUCOCYTES" then do;
LBTESTCD="WBC";
LBTEST = "Leukocytes";
end;

else if param = "CREATININE" then do;
LBTESTCD="CREAT";
LBTEST = "Creatinine";
end;

else if param = "SODIUM" then do;
LBTESTCD="SODIUM";
LBTEST = "Sodium";
end; 

else if param = "POTASSIUM" then do;
LBTESTCD="K";
LBTEST = "Potassium";
end;

else if param = "GLUCOSE" then do;
LBTESTCD="GLUC";
LBTEST = "Glucose";
end;

else if param = "PLATELETS" then do;
LBTESTCD="PLAT";
LBTEST = "Platelets";
end;
drop param;
run;


****renaming lb_unit to LBORRESU, si_unit to LBSTRESU, LB_VALUE to LBORRES, and deriving LBSTRESC and LBSTRESN;
data lab2;
length LBSTRESC $8  LBNRIND $20 LBCAT $50;
set lab1(rename=(lb_unit=LBORRESU si_unit=LBSTRESU si_value=LBSTRESN NORL_INV=LBORNRLO NORH_INV=LBORNRHI SHIFT_L=LBSTNRLO  SHIFT_H=LBSTNRHI));
LBORRES = compress(LB_VALUE);
LBSTRESC = LBORRES;
LBSTRESN = input(compress(LBSTRESC,"ABCDEFGHIJKLMNOPQRSTUVWXYZ"),comma8.);
RFSTDTC1= input(RFSTDTC, yymmdd10.);
LBDT= input(date, date7.);

format lbdt yymmdd10. RFSTDTC1 yymmdd10.;

**baseline flag and derived flag;
drop Age race arm armcd BRTHDTC sex AGEU country RFSTDTC date LB_VALUE;
if lbtestcd in('ALP', 'ALT', 'AST', 'BILDIR', 'BILI', 'HCT', 'HGB') then lbtestcd= "T"||lbtestcd;
if substr(lbtestcd,1,1)= 'T' then LBDRVFL= 'Y';
if lbdt ne . and RFSTDTC1 ne .  and LBORRES ne " " and RFSTDTC1>= lbdt then LBBLFL = "Y";



***deriving the variable lbcat from labt_ using substr;
if labt_ = "02CLINICAL CHEMISTRY" then
LBCAT = "CHEMISTRY";
else if labt_ = "03URINE" then
LBCAT = "URINALYSIS";
else if labt_ = "01HEMATOLOGY" then
LBCAT = "HEMATOLOGY";

**variable LBNRIND;
if lbcat not in("URINALYSIS") and lborres not
in(" ") then do;
If .<lbstresn<lbstnrlo then LBNRIND='LOW';
else if lbstnrlo<=lbstresn<=lbstnrhi then
LBNRIND='Normal';
else if lbstresn>lbstnrhi then LBNRIND='HIGH';
End;
Else if lbcat not in
("HEMATOLOGY", "CHEMISTRY") and lborres
not in (" ") then do;
If flag in ("H") then LBNRIND="HIGH";
else If flag in ("L") then LBNRIND="LOW";
else If flag in (" ") then LBNRIND="NORMAL";
End;
run;

proc sort data=lab2 out=lab2a;
by subjid lbtestcd lbdt visitd;
run;

data lab2b; 
set lab2a;
by subjid lbtestcd lbdt visitd;
*by descending usubjid lbdt;
if first.subjid or first.lbtestcd then VISITNUM=.;
VISITNUM+1;
run;

***proc format for visitd;
proc format;
value $visitfmt
"SCREENING_R.1" ="SCREENING (DAY -28 TO DAY -1): UNSCHEDULED 1"
"SCREENING_R.2" ="SCREENING (DAY -28 TO DAY -1): UNSCHEDULED 2"
"WEEK 2" ="VISIT 2 (WEEK 2)"
"MONTH 1" = "VISIT 2 (MONTH 1)"
"MONTH 2" = "VISIT 2 (MONTH 2)"
"MONTH 3" = "VISIT 2 (MONTH 3)"
"MONTH 4" = "VISIT 2 (MONTH 4)"
"MONTH 5" = "VISIT 2 (MONTH 5)"
"MONTH 6" = "VISIT 2 (MONTH 6)"
"MONTH 7" = "VISIT 2 (MONTH 7)"
"MONTH 8" = "VISIT 2 (MONTH 8)"
"MONTH 9" = "VISIT 2 (MONTH 9)"
"MONTH 10" = "VISIT 2 (MONTH 10)"
"MONTH 11" = "VISIT 2 (MONTH 11)"
"MONTH 12" = "VISIT 2 (MONTH 12)"
"MONTH 13" = "VISIT 2 (MONTH 13)"
"MONTH 14" = "VISIT 2 (MONTH 14)"
"MONTH 15" = "VISIT 2 (MONTH 15)"
"MONTH 16" = "VISIT 2 (MONTH 16)"
"MONTH 17" = "VISIT 2 (MONTH 17)"
"MONTH 18" = "VISIT 2 (MONTH 18)"
"MONTH 19" = "VISIT 2 (MONTH 19)"
"MONTH 20" = "VISIT 2 (MONTH 20)"
"MONTH 21" = "VISIT 2 (MONTH 21)"
"MONTH 22" = "VISIT 2 (MONTH 22)"
"MONTH 23" = "VISIT 2 (MONTH 23)"
"MONTH 24" = "VISIT 2 (MONTH 24)"
"MONTH 25" = "VISIT 2 (MONTH 25)"
"MONTH 26" = "VISIT 2 (MONTH 26)"
"MONTH 27" = "VISIT 2 (MONTH 27)"
"MONTH 28" = "VISIT 2 (MONTH 28)"
"MONTH 29" = "VISIT 2 (MONTH 29)"
"MONTH 30" = "VISIT 2 (MONTH 30)"
"MONTH 31" = "VISIT 2 (MONTH 31)"
"MONTH 32" = "VISIT 2 (MONTH 32)"
"MONTH 33" = "VISIT 2 (MONTH 33)"
"MONTH 34" = "VISIT 2 (MONTH 34)"
"MONTH 35" = "VISIT 2 (MONTH 35)"
"MONTH 36" = "VISIT 2 (MONTH 36)"
"MONTH 37" = "VISIT 2 (MONTH 37)"
"MONTH 38" = "VISIT 2 (MONTH 38)"
"MONTH 39" = "VISIT 2 (MONTH 39)"
"MONTH 40" = "VISIT 2 (MONTH 40)"
"MONTH 41" = "VISIT 2 (MONTH 41)"
"MONTH 42" = "VISIT 2 (MONTH 42)"
"MONTH 43" = "VISIT 2 (MONTH 43)"
"MONTH 1_R.1" = "VISIT 2 (MONTH 1)UNSCHEDULED 1"
"MONTH 2_R.1" = "VISIT 2 (MONTH 2) UNSCHEDULED 2"
"MONTH 3_R.1" = "VISIT 2 (MONTH 3) UNSCHEDULED 3"
"MONTH 4_R.1" = "VISIT 2 (MONTH 4) UNSCHEDULED 4"
"MONTH 5_R.1" = "VISIT 2 (MONTH 5) UNSCHEDULED 5"
"MONTH 6_R.1" = "VISIT 2 (MONTH 6)UNSCHEDULED 6"
"MONTH 7_R.1" = "VISIT 2 (MONTH 7)UNSCHEDULED 7"
"MONTH 8_R.1" = "VISIT 2 (MONTH 8)UNSCHEDULED 8"
"MONTH 9_R.1" = "VISIT 2 (MONTH 9)UNSCHEDULED 9"
"MONTH 10_R.1" = "VISIT 2 (MONTH 10)UNSCHEDULED 10"
"MONTH 11_R.1" = "VISIT 2 (MONTH 11)UNSCHEDULED 11"
"MONTH 12_R.1" = "VISIT 2 (MONTH 12)UNSCHEDULED 12"
"MONTH 13_R.1" = "VISIT 2 (MONTH 13)UNSCHEDULED 13"
"MONTH 14_R.1" = "VISIT 2 (MONTH 14)UNSCHEDULED 14"
"MONTH 15_R.1" = "VISIT 2 (MONTH 15)UNSCHEDULED 15"
"MONTH 16_R.1" = "VISIT 2 (MONTH 16)UNSCHEDULED 16"
"MONTH 17_R.1" = "VISIT 2 (MONTH 17)UNSCHEDULED 17"
"MONTH 18_R.1" = "VISIT 2 (MONTH 18)UNSCHEDULED 18"
"MONTH 19_R.1" = "VISIT 2 (MONTH 19)UNSCHEDULED 19"
"MONTH 20_R.1" = "VISIT 2 (MONTH 20)UNSCHEDULED 20"
"MONTH 21_R.1" = "VISIT 2 (MONTH 21)UNSCHEDULED 21"
"MONTH 22_R.1" = "VISIT 2 (MONTH 22)UNSCHEDULED 22"
"MONTH 23_R.1" = "VISIT 2 (MONTH 23)UNSCHEDULED 23"
"MONTH 24_R.1" = "VISIT 2 (MONTH 24)UNSCHEDULED 24"
"MONTH 25_R.1" = "VISIT 2 (MONTH 25)UNSCHEDULED 25"
"MONTH 26_R.1" = "VISIT 2 (MONTH 26)UNSCHEDULED 26"
"MONTH 27_R.1" = "VISIT 2 (MONTH 27)UNSCHEDULED 27"
"MONTH 28_R.1" = "VISIT 2 (MONTH 28)UNSCHEDULED 28"
"MONTH 29_R.1" = "VISIT 2 (MONTH 29)UNSCHEDULED 29"
"MONTH 30_R.1" = "VISIT 2 (MONTH 30)UNSCHEDULED 30"
"MONTH 31_R.1" = "VISIT 2 (MONTH 1)UNSCHEDULED 31"
"MONTH 32_R.1" = "VISIT 2 (MONTH 1)UNSCHEDULED 32"
"MONTH 33_R.1" = "VISIT 2 (MONTH 1)UNSCHEDULED 33"
"MONTH 34_R.1" = "VISIT 2 (MONTH 1) UNSCHEDULED 34"
"MONTH 35_R.1" = "VISIT 2 (MONTH 35)UNSCHEDULED 35"
"MONTH 36_R.1" = "VISIT 2 (MONTH 36) UNSCHEDULED 36"
"MONTH 40_R.1" = "VISIT 2 (MONTH 40)UNSCHEDULED 40"
"END OF TREAT_R.1" = "END OF TREAT (DAY -28 TO DAY -1): UNSCHEDULED 1"
"END OF TREAT_R.2" = "END OF TREAT (DAY -28 TO DAY -1): UNSCHEDULED 2"
"EVENT_R.1" = "EVENT (DAY -28 TO DAY -1): UNSCHEDULED 1"
"EVENT_R.2" = "EVENT (DAY -28 TO DAY -1): UNSCHEDULED 2"
"FOLLOW UP_R.1" = "FOLLOW UP_R.1 (DAY -28 TO DAY -1): UNSCHEDULED 1"
"FOLLOW UP_R.2" = "FOLLOW UP_R.2 (DAY -28 TO DAY -1): UNSCHEDULED 2"
"Local Lab - Page 001a" = "Local Lab (DAY -28 TO DAY -1): UNSCHEDULED 1a"
"Local Lab - Page 001b" = "Local Lab (DAY -28 TO DAY -1): UNSCHEDULED 1b"
"Local Lab - Page 001c" = "Local Lab  (DAY -28 TO DAY -1): UNSCHEDULED 1c"
"RETEST 1" = "VISIT 2 (RETEST 1)"
"RETEST 2" = "VISIT 2 (RETEST 2)"
"RETEST 3" = "VISIT 2 (RETEST 3)"
"RETEST 4" = "VISIT 2 (RETEST 4)"
"RETEST 5" = "VISIT 2 (RETEST 5)"
"RETEST 6" = "VISIT 2 (RETEST 6)"
"RETEST 7" = "VISIT 2 (RETEST 7)"
"RETEST 8" = "VISIT 2 (RETEST 8)"
"RETEST 9" = "VISIT 2 (RETEST 9)"
"RETEST 10" = "VISIT 2 (RETEST 10)"
"RETEST 11" = "VISIT 2 (RETEST 11)"
"RETEST 12" = "VISIT 2 (RETEST 12)"
"RETEST 13" = "VISIT 2 (RETEST 13)"
"RETEST 14" = "VISIT 2 (RETEST 14)"
"RETEST 15" = "VISIT 2 (RETEST 15)"
"RETEST 1_R.1" = "VISIT 2 (RETEST 1)UNSCHEDULED 1"
"RETEST 2_R.1" = "VISIT 2 (RETEST 2) UNSCHEDULED 2"
"RETEST 3_R.1" = "VISIT 2 (RETEST 3) UNSCHEDULED 3"
"RETEST 5_R.1" = "VISIT 2 (RETEST 5) UNSCHEDULED 5"
"RETEST 6_R.1" = "VISIT 2 (RETEST 6)UNSCHEDULED 6"
"RETEST 7_R.1" = "VISIT 2 (RETEST 7)UNSCHEDULED 7"
"RETEST 8_R.1" = "VISIT 2 (RETEST 8)UNSCHEDULED 8"
"RETEST 9_R.1" = "VISIT 2 (RETEST 9)UNSCHEDULED 9"
"RETEST 10_R.1" = "VISIT 2 (RETEST 10)UNSCHEDULED 10"
"RETEST 11_R.1" = "VISIT 2 (RETEST 11)UNSCHEDULED 11"
"RETEST 12_R.1" = "VISIT 2 (RETEST 12)UNSCHEDULED 12"
"RETEST 13_R.1" = "VISIT 2 (RETEST 13)UNSCHEDULED 13"
"RETEST  14_R.1" = "VISIT 2 (RETEST 14)UNSCHEDULED 14"
"RETEST 15_R.1" = "VISIT 2 (RETEST 15)UNSCHEDULED 15"
"RETEST 16_R.1" = "VISIT 2 (RETEST 15)UNSCHEDULED 16";
run;


***sorting to create uniqness;
proc sort data = lab2b out=lab2b1;
by usubjid lbtestcd lbdt visitd;
run;

***lbseq and lbdy;
data lab4a(DROP=DMDY DMDTC RFENDTC TRTEM28 FLAG TRTEM1 SUBJID LAB_TDAY PAR_ LABT_ VTYPE);
length VISITD $100; 
set lab2b1(rename=(RFSTDTC1=RFSTDTC));
format VISITD $visitfmt.;
if LBDT >= RFSTDTC then LBDY =
(LBDT-RFSTDTC)+1;
else if LBDT<RFSTDTC then LBDY = LBDT-RFSTDTC;
by usubjid lbtestcd lbdt visitd;
*by descending usubjid lbdt;
if first.usubjid then LBSEQ=.;
LBSEQ+1;
run;


***label names for the variables;
data lb(drop=LBDT RFSTDTC);
retain STUDYID DOMAIN USUBJID LBSEQ LBTESTCD LBTEST LBCAT LBORRES LBORRESU 
LBORNRLO LBORNRHI LBSTRESC LBSTRESN LBSTRESU LBSTNRLO LBSTNRHI LBNRIND LBNAM LBBLFL 
LBDRVFL VISITNUM VISIT LBDTC LBDY;
set lab4a(rename=(visitd=VISIT));
label LBDTC = "Date/Time of SpecimenCollection" 
VISIT = "Visit Name" 
LBCAT = "Category for Lab Test" 
LBORRES = "Result or Finding in Original Units" 
LBORRESU = "Original Units" 
LBORNRLO = "Reference Range Lower Limit in Orig Unit"  
LBORNRHI= "Reference Range Upper Limit in Orig Unit" 
LBSTRESC = "Character Result/Finding in Std Format" 
LBSTRESN = "Numeric Result/Finding in Standard Units" 
LBSTRESU= "Standard Units" 
LBSTNRLO = "Reference Range Lower Limit-Std Units" 
LBSTNRHI ="Reference Range Upper Limit-Std Units" 
LBNRIND = "Reference Range Indicator"
LBBLFL = "Baseline Flag"
LBDRVFL = "Derived Flag" 
VISITNUM = "Visit Number"  
LBDY = "Study Day of Specimen Collection" 
DOMAIN = "Domain Abbreviation" 
LBTEST = "Lab Test or Examination Name" 
LBTESTCD = "Lab Test or Examination Short Name" 
LBSEQ = "Sequence Number";
LBDTC = put(LBDT, yymmdd10.);
run;

**sasdataset;
data anadata.LB;
set lb;
run;
proc printto;
run;


