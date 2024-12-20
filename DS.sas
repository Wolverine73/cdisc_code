/*Property of Clip Lab of Cytel. For use by Clip Lab students only.*/
/*Copyright � 2014, Cytel Statistical Software & Services Pvt. Ltd.*/
/*All Rights Reserved. Copying in any form is prohibited.*/
/*--------------------------------------------------------------------------------------
STUDY					: 
PROGRAM					: ds.sas 
SAS VERSION				: 9.4
DESCRIPTION				: To generate DS (SDTM) dataset as per CDISC standard by using raw DS, RAND & COMVAR dataset. 
And to also validate it with primary Disposition dataset by writing independent code in SAS.
AUTHOR					: Adeyemo Olamide
DATE COMPLETED			: 19/5/2023
PROGRAM INPUT			: DS.sas7bdat,COMVAR.sas7bdat,,RANDsas7bdat.
PROGRAM OUTPUT			: DS.sas,DS.sas7bdat,DS.log.
PROGRAM LOG				: &workpath\05out_logs\ds.log
EXTERNAL MACROS CALLED	: None
EXTERNAL CODE CALLED	: ds.sas

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
options fmterr;
%include "/home/u63305369/03.QC of SDTM Datasets Development 
(Demography and Disposition)/Work/04utility/initial.sas~";

proc printto log="&logdir/ds.log";
ods html close;
ods listing close;
ods rtf file = "&validatedir/ds.rtf";
*derving dsterm ans dsdecod variables in the dm dataset;
Data _dm;
length usubjid $30 DSDECOD $100 DSTERM $200;
set rawdata.dm;
USUBJID=(STUDYID||'-'||SITEID||'-'||SUBJID);
If usubjid ne " " then do;
DSTERM='INFORMED CONSENT OBTAINED';
DSDECOD='INFORMED CONSENT OBTAINED';
end;
run;

*sorting _dm;
proc sort data=_dm out=_dm2;
by usubjid;
run;

*deriving Usubjid by concatenate studyid siteid subjid;
data _rand;
length usubjid $30;
set rawdata.rand;
USUBJID=(STUDYID||'-'||SITEID||'-'||SUBJID);
run;

*sorting _rand; 
proc sort data=_rand out=_rand2;
by usubjid;
run;

*study id without "-";
data comvar_ds;
set rawdata.comvar;
study= substr(STUDYID, 1,5);
id= substr(STUDYID, 7, 3);
STUDYIDX = put(study, 5.) || put(id, 3.);
drop studyid;
run;

data comvar_ds2;
set comvar_ds(rename=(STUDYIDX=STUDYID));
run;


*sorting comvar_ds2;
proc sort data=comvar_ds out=comvar_ds2;
by usubjid;
run;

*joining _dm2 and comvar_ds2 horizontally;
data dm_co;
merge _dm2 comvar_ds2;
by USUBJID;
run;

*joining dm_co and _rand2 vertically;
data dm_ra_co;
set dm_co _rand2;
run;

*filter to remove missing values as dsdecod is a required variable;
data dm_ra_co1;
set dm_ra_co;
where dsdecod ne " ";
run;

*sorting dm_ra_co1;
proc sort data=dm_ra_co1 out=dm_ra_co2;
by usubjid;
run;

*deriving usubjid in ds domain;;
data _ds;
length USUBJID $30;
set rawdata.ds;
USUBJID=(STUDYID||'-'||SITEID||'-'||SUBJID);
run;

*sorting _ds;
proc sort data=_ds out=_ds1;
by usubjid;
run;


data ds1;
set _ds1 dm_ra_co2;
if USUBJID ne " " then DOMAIN="DS";
****generating numeric value of _RFSTDTC 
DSSTDTC as  DSSTDTN DSSTDTN respectively;
DSSTDTN = input(DSSTDTC,yymmdd10.);
RFSTDTN = input(_RFSTDTC,yymmdd10.);
format DSSTDTN RFSTDTN yymmdd10.;
dsterm= compress(dsterm, "#");
run;

 
*standardizing dsdecod and dscat as per cdisc  controlled terminology;
data ds2;
set ds1;
if dsdecod= "SUBJECT WITHDREW CONSENT" then dsdecod="WITHDRAWAL OF CONSENT";
if dsdecod= "INVESTIGATOR JUDGMENT" then dsdecod="PHYSICIAN DECISION";
if dsdecod= "SUBJECT WITHDREW CONSENT: TIME CONSTRAINTS" then dsdecod="WITHDRAWAL OF CONSENT";
if dsdecod= "SUBJECT LOST TO FOLLOW-UP" then dsdecod="LOST TO FOLLOW-UP";
if dsdecod= "SUBJECT DID NOT MEET INCLUSION/EXCLUSION CRITERIA" 
then dsdecod="SCREEN FAILURE";
if dsdecod= "SUBJECT RELOCATED" then dsdecod="WITHDRAWAL OF CONSENT";
if dsdecod= "INCARCERATION" then dsdecod="LOST TO FOLLOW-UP";
if dsdecod= "MAJOR PROTOCOL VIOLATION" then dsdecod="PROTOCOL VIOLATION";
if dsdecod = "INFORMED CONSENT OBTAINED"  then DSCAT = "PROTOCOL MILESTONE";
else if dsdecod = "RANDOMIZED" then DSCAT = "PROTOCOL MILESTONE";
else DSCAT = "DISPOSITION EVENT";
if DSCAT = "DISPOSITION EVENT" then DSSCAT="STUDY PARTICIPATION";
****DSTERM must not be missing hence mapped with dsdecod;
if DSTERM = " " then DSTERM=DSDECOD;
***calculate DSSTDY;
***sum function when substracting missing vslue from number where the missing value will be treated  as zero;
*If DSSTDTN ge RFSTDTN THEN DSSTDY= sum(DSSTDTN,-RFSTDTN)+1;
*ELSE DSSTDY=sum(DSSTDTN,-RFSTDTN);
             ***calculate DSSTDY;
if RFSTDTN ne .  then DSSTDY=DSSTDTN-RFSTDTN;
else if DSSTDTN ge RFSTDTN and RFSTDTN ne .  THEN DSSTDY= (DSSTDTN-RFSTDTN)+1;
run;


data ds3;
set ds2;
   *keeping only the variables in the data that belongs to the DS domain;
Keep STUDYID DOMAIN USUBJID DSTERM DSDECOD DSCAT DSSTDTC DSSCAT DSSTDY; 
run;

***sorting the data to create uniqueness as per RSD;
proc sort data=ds3 out=ds4;
by USUBJID DSSTDTC DSDECOD;
run;

*derving DSSEQ in the by group;
data ds;
set ds4;
by USUBJID DSSTDTC DSDECOD; 
if first.usubjid then DSSEQ=.;
DSSEQ+1; 
label STUDYID="Study Identifier" DOMAIN="Domain Abbreviation" USUBJID ="Unique Subject Identifier" 
DSTERM="Reported Term for the Disposition Event" DSSEQ="Sequence Number" DSDECOD="Standardized Disposition Term"
DSCAT="Category for Disposition Event" DSSCAT="Subcategory for disposition event" 
DSSTDTC="Start Date/Time of disposition event" DSSTDY="Study Day of Start of Disposition Event";
run;

data anadata.ds;
set ds;
run;


PROC COMPARE data=DS COMPARE=ANADATA.DS listvar 
out=toprint;
*id subjid;
RUN;

run;
ods html;
ods listing;
ods rtf close;
proc printto;
run;




