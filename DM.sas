*-------------------------------------------------------------------------------------
STUDY					: 
PROGRAM					: dm.sas 
SAS VERSION				: 9.4
DESCRIPTION				: To generate DM (SDTM) dataset as per CDISC standard by using raw DM & Comvar dataset. 
And to also validate it with primary demographic dataset by writing independent code in SAS.
AUTHOR					: Adeyemo Olamide
DATE COMPLETED			: 18/5/2023
PROGRAM INPUT			: DM.sas7bdat,COMVAR.sas7bdat.
PROGRAM OUTPUT			: DM.sas,DM.sas7bdat,DM.log.
PROGRAM LOG				: &workpath\05out_logs\dm.log
EXTERNAL MACROS CALLED	: None
EXTERNAL CODE CALLED	: dm.sas

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

*options fmterr;
%include "/home/u63305369/QC of SDTM Datasets Development (Demography)/Work/04utility/initial.sas";
proc printto log="&logdir/dm.log";
ods rtf file = "&validatedir/dm.rtf";
data comvar1;
*length STUDYID $8;
set rawdata.comvar;
study= substr(STUDYID, 1,5);
id= substr(STUDYID, 7, 3);
STUDYIDX = put(study, 5.) || put(id, 3.);
drop studyid;
run;

data comvar2;
set comvar1(rename=(STUDYIDX=STUDYID));
run;

proc sort data=comvar2 out=comvar;
by usubjid;
run;


****usubjid is a required variable in dm domain;
data _dm;
length USUBJID $30;
set rawdata.dm;
USUBJID= (STUDYID||'-'||SITEID||'-'||SUBJID);
run;

proc sort data=_dm out=dm1;
by usubjid;
run;

*merge dm1 and comvar;
data _dm1;
merge dm1 comvar;
by usubjid;
drop id study;
run;

***check for duplicate value for usubjid, and missing value for usubjid siteid sex subjid studyid,;
proc sort data=_dm1 nodupkey out=_dm2;
by usubjid;
where usubjid ne " " and  sex ne " " and SITEID ne " "  and SUBJID ne " " and STUDYID ne " " ;
run;

**DERIVING VARIABLES AGE AGEU DMDY and DM Domain;
data _dm3;
length STUDYID $10.;
set _dm2;
if dovdtc ne " " and _rfstdt ne . then DMDY=(input(dovdtc,yymmdd10.)- _rfstdt)+1;
if _rfstdt ne . and brthdtc ne " " then AGE=floor((_rfstdt -input(brthdtc,yymmdd10.))/365.25 );
*The country variable(a required variable in SDTM) is not avalaible in the provided data. 
On the 25th of May the sponsor directed that the variable country should be set to missing;
if usubjid ne " " then COUNTRY= " ";
if AGE ne . then AGEU = "YEAR";
if usubjid ne " " then DOMAIN="DM";
run;

***visit visitnum DSSTDTC RACEOTH _LDOSDT _FDOSDT _RFSTDT _RFSTTM _RFSTDTN
_LDOSDTN _FDOSDTN _RFENDT _RFENTM _RFENDTN do not belong to the dm domain ;

data dm;
*arrange the variable in the order they appear in DM SDTM guidelines;
retain STUDYID DOMAIN USUBJID SUBJID RFSTDTC RFENDTC
 SITEID INVNAM BRTHDTC AGE AGEU SEX RACE ARMCD ARM COUNTRY DMDTC DMDY;
set _dm3(rename=(_RFSTDTC=RFSTDTC _RFENDTC=RFENDTC _ARM=ARM _ARMCD=ARMCD _INVNAM=INVNAM DOVDTC=DMDTC));
drop visit visitnum DSSTDTC RACEOTH _LDOSDT _FDOSDT _RFSTDT _RFSTTM _RFSTDTN 
_LDOSDTN _FDOSDTN _RFENDT _RFENTM _RFENDTN _siteid _subjid;
label STUDYID="Study Identifier" DOMAIN="Domain Abbreviation" USUBJID ="Unique Subject Identifier" 
SUBJID="Subject Identifier for the Study" RFSTDTC="Subject Reference Start Date/Time" RFENDTC="Subject Reference End Date/Time"
SITEID="Study Site Identifier" INVNAM="Investigator Name" BRTHDTC="Date/Time of Birth" AGE="Age Units" AGEU="YEAR" SEX="Sex" 
Race="Race" ARMCD="Planned Arm Code" ARM="Description of Planned Arm"
DMDTC="Date/Time of Collection" DMDY="Study Day of Collection" COUNTRY="Country";
run;

**creating sas7bdat;
data anadata.dm;
set dm;
run;


PROC COMPARE data=original.DM COMPARE=ANADATA.DM listvar 
out=toprint;
run;

ods rtf close;
proc printto;
run;






