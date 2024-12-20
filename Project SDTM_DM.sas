/****************************************************************************
* PROJECT GOAL: Create the SDTM DM data set based on the SDTM specification *
* file (i.e. dm_only.xlsx).                                                 *
*                                                                           *
*                                                                           *
* ABOUT THE DATA: The CDM data sets capture the data recorded on the Case   *
* Report Forms (CRF). The data is captured during the clinical trial,       *
* either by hand or electronically, on CRF.                                 *
*                                                                           *
* The cleansed data from the form will then be converted into CDM data sets *
*                                                                           *
* For the Project, we have five CDM data sets:                              *
* DEALTH                                                                    *
* DM                                                                        *
* DS                                                                        *
* EX                                                                        *
* SPCPKB1                                                                   *
****************************************************************************/


/************************
* Import the Data Files *
************************/

proc import datafile="/home/u63696516/EPG1V2/PSDTM_DM/CDM.xlsx"
              dbms=xlsx
              out= SDTM.CDM;
run;

proc import datafile="/home/u63696516/EPG1V2/PSDTM_DM/DEATH.xlsx"
              dbms=xlsx
              out= SDTM.DEATH;
run;

proc import datafile="/home/u63696516/EPG1V2/PSDTM_DM/DM.xlsx"
              dbms=xlsx
              out= CLINICAL.DM;
run;

proc import datafile="//home/u63696516/EPG1V2/PSDTM_DM/DS.xlsx"
              dbms=xlsx
              out= SDTM.DS;
run;

proc import datafile="/home/u63696516/EPG1V2/PSDTM_DM/EX.xlsx"
              dbms=xlsx
              out= SDTM.EX;
run;

proc import datafile="/home/u63696516/EPG1V2/PSDTM_DM/SPCPKB1.xlsx"
              dbms=xlsx
              out= SDTM.SPCPKB1;
run;


/****************************************************************************
* Set up and populate the STDM_DM data, by assigning the data variables and *
* observations from the provided data (DEATH, DM, DS, EX, SPCPKB1) files,   *
* as required through the DM_ONLY file.                                     *
*                                                                           *
*****************************************************************************
* STUDYID = "XYZ"                                                           *
* DOMAIN = "DM"                                                             *
* USUBJID  = Concatenate STUDYID and SUBJECT with a '/' as a separator        *
* SUBJID = CDM.DM.SUBJECT                                                   *
****************************************************************************/

DATA SDTM_DM1;
  SET CLINICAL.DM;
    STUDYID = 'XYZ';
    DOMAIN = 'DM';
    USUBJID  = CATX('/', STUDYID, SUBJECT);
    SUBJID = SUBJECT;
  KEEP Studyid Domain Userid Subjid;
RUN;


/******************************************************************* 
* Create a temporary table "Concatenate" to join two column values *
* from the SPCPKB1 data file as RFSTDTC.                           *
*                                                                  *
********************************************************************
* RFSTDTC = The first non missing value of CDM.SPCPKB1.IPFD1DAT    *
* concatenated with SPCPKB1.IPFD1TIM where CDM.SPCPKB1.PSCHDAY = 1 *
* and CDM.SPCPKB1.PART = "A"                                       *
*******************************************************************/ 

DATA Concatenate;
  SET CLINICAL.SPCPKB1;
   RFSTDTC = CATX(" ", IPFD1DAT, IPFD1TIM);
  WHERE PSCHDAY = 1
  AND PART = "A";
RUN;
  

/******************************************************************* 
* Join the "Concatenate" table with the intial SDTM_DM1 data table *
* to assign the next variable in line.                             *
*******************************************************************/

PROC SQL;
CREATE TABLE SDTM_DM2 AS
SELECT STUDYID,
       DOMAIN,
       USUBJID,
       SUBJID,
       RFSTDTC
FROM SDTM_DM1
  LEFT JOIN Concatenate
    ON SDTM_DM1.SUBJID = Concatenate.SUBJECT
WHERE RFSTDTC IS NOT NULL;
QUIT;


/*************************** 
* RFENDTC = CDM.EX.EXENDAT *
***************************/ 

PROC SQL;
CREATE TABLE SDTM_DM3 AS
SELECT STUDYID,
       DOMAIN,
       USUBJID,
       SUBJID,
       RFSTDTC,
       EXENDAT AS RFENDTC
FROM SDTM_DM2
  LEFT JOIN CLINICAL.EX
    ON SDTM_DM2.SUBJID=EX.SUBJECT;
QUIT;


/*********************************************************************
* Extend the SDTM_DM3 variables by representing specific data values *
*                                                                    *
**********************************************************************
* RFXSTDTC = SDTM.DM.RFSTDTC                                         *
* RFXENDTC = SDTM.DM.RFENDTC                                         *
*********************************************************************/

DATA SDTM_DM4;
  SET SDTM_DM3;
   RFXSTDTC = RFSTDTC;
   RFXENDTC = RFENDTC;
RUN;


/******************************************************************
* Update the SDTM_DM4 data table with the DM and DS table values  *
*                                                                 *
*******************************************************************
* RFXENDTC = SDTM.DM.RFENDTC                                      *
* RFPENDTC = CDM.DS.DSSTDAT                                       *
* DTHDTC = CDM.DEATH.DTH_DAT                                      *
******************************************************************/

PROC SQL;
CREATE TABLE SDTM_DM5 AS
SELECT STUDYID,
       DOMAIN,
       USUBJID,
       SUBJID,
       RFSTDTC,
       RFENDTC,
       RFXSTDTC,
       RFXENDTC,
       DSSTDAT AS RFPENDTC,
       DTH_DAT AS DTHDTC
FROM SDTM_DM4
  LEFT JOIN CLINICAL.DS
    ON SDTM_DM4.SUBJID=DS.SUBJECT
  LEFT JOIN CLINICAL.DEATH
    ON DS.SUBJECT=DEATH.SUBJECT;
QUIT;


/**************************************************************** 
* Update the SDTM_DM5 variables; using the IF THEN DO statement *
*                                                               *
*****************************************************************
*                                                               *
* When SDTM.DM.DTHDTC is NOT MISSING then DTHFL = "Y"           *
****************************************************************/

DATA SDTM_DM6;
  SET SDTM_DM5;
    IF DTHDTC NE " " THEN DO 
       DTHFL="Y";
    END;
RUN;


/******************************************************************
* Further update the SDTM_DM6 data table through the DM data file *
*                                                                 *
*******************************************************************
* SITEID: Set to CDM.DM.CENTRE                                    *
* BRTHDTC = CDM.DM.BRTHDAT                                        *
* AGE = CDM.DM.AGE                                                *
* AGEU = CDM.DM.AGEU                                              *
* SEX = CDM.DM.SEX                                                *
* RACE = CDM.DM.RACE                                              *
* ETHNIC = CDM.DM.ETHNIC                                          *
******************************************************************/

PROC SQL;
CREATE TABLE SDTM_DM7 AS
SELECT STUDYID,
       DOMAIN,
       USUBJID,
       SUBJID,
       RFSTDTC,
       RFENDTC,
       RFXSTDTC,
       RFXENDTC,
       RFPENDTC,
       DTHDTC,
       DTHFL,
       CENTRE AS SITEID,
       BRTHDAT AS BRTHDC,
       DM.AGE,
       DM.AGEU,
       DM.SEX,
       DM.RACE,
       DM.ETHNIC AS ETHNIC_CODE
FROM SDTM_DM6
  LEFT JOIN CLINICAL.DM
    ON SDTM_DM6.SUBJID=DM.SUBJECT;
QUIT;


/*************************************************************
* Assign a column tagged "ETHNIC" with defined observational *
* text format                                                *
*************************************************************/

DATA SDTM_DM8;
  length ETHNIC $ 22;
  SET SDTM_DM7;
    ETHNIC=" ";
RUN;

/********************************************************************
* Further update the data variables; using the IF THEN DO statement *
*                                                                   *
*********************************************************************
*                                                                   *
* If AGEU = 'C29848' then equal to"YEARS"                           *
* IF SEX='C20197'then 'M';                                          *
*          Otherwise, when SEX='C16576' then 'F';                   *
*          Otherwise, set to 'U'                                    *
* When RACE = 'C41260' then = 'ASIAN'                               *
* When RACE = 'C41261' then = 'WHITE'                               *
* If ETHNIC = 'C41222' then = "NOT HISPANIC OR LATINO"              *
* When RFSTDTC is NOT missing then ARMCD = "A01-A02-A03"            *
********************************************************************/

DATA SDTM_DM9;
  SET SDTM_DM8;
    IF AGEU="C29848" THEN DO
       AGEU="YEARS";
    IF SEX="C20197" THEN
       SEX="M";
     ELSE IF SEX="C16576" THEN
       SEX="F";
     ELSE SEX="U";
    IF RACE="C41260" THEN
       RACE="ASIA";
     ELSE IF RACE="C41261" THEN
       RACE="WHITE";
    IF ETHNIC_CODE="C41222" THEN
       ETHNIC="NOT HISPANIC OR LATINO";
    IF RFSTDTC NE " " THEN
       ARMCD = "A01-A02-A03";
    END;
RUN;


/********************************************************************* 
* Set additional variable by representing specific variable from the *
* SDTM_DM8 data table                                                *
*********************************************************************/

DATA SDTM_DM10;
  SET SDTM_DM9;
   ACTARMCD = ARMCD;
RUN;


/********************************************************************** 
* Finally, update the SDTM_DM9 data file with the required variables, *
* then create the SDTM_DM data file.                                  *
*                                                                     *
***********************************************************************
* ACTARMCD = SDTM.DM.ARMCD                                            *
* DMDTC = DM.VIS_DAT                                                  *
* CENTRE = DM.CENTRE                                                  *
* PART = DM.PART                                                      *
* RACEOTH = DM.RACEOTH in uppercase                                   *
* VISITDTC = DM.VIS_DAT                                               *
**********************************************************************/

PROC SQL;
CREATE TABLE Clinical.SDTM_DM AS
SELECT STUDYID,
       DOMAIN,
       USUBJID,
       SUBJID,
       RFSTDTC,
       RFENDTC,
       RFXSTDTC,
       RFXENDTC,
       RFPENDTC,
       DTHDTC,
       DTHFL,
       SITEID,
       BRTHDC,
       SDTM_DM10.AGE,
       SDTM_DM10.AGEU,
       SDTM_DM10.RACE,
       SDTM_DM10.ETHNIC,
       SDTM_DM10.SEX,
       ARMCD,
       ACTARMCD,
       DM.VIS_DAT AS DMDTC,
       DM.CENTRE,
       DM.PART,
       DM.RACEOTH,
       VIS_DAT AS VISITDTC
FROM SDTM_DM10
  LEFT JOIN CLINICAL.DM
    ON SDTM_DM10.SUBJID=DM.SUBJECT;
QUIT;


/**********************************
* Export the data in EXCEL format *
**********************************/

ODS excel FILE="&Output/SDTM_DM.xlsx";
TITLE "PROJECT SDTM_DM";
TITLE2 "Compilation of Customers' specific details from the Case Report Forms";
PROC PRINT DATA=Clinical.SDTM_DM;
RUN;
ODS excel CLOSE;
