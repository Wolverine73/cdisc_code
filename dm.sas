/*log file*/
proc printto log='/home/u63774111/Project/Log files/dm.log';



libname raw "/home/u63774111/Project/Project_2/Raw_CRF";

/*Initially, 24 rows; 29 columns*/

data data1;
set raw.dm;
run; 


/*To see the variable names in raw DM data*/
proc contents data=data1 varnum;
run;



/*Creating SDTM data: v1*/
data data2;
retain STUDYID DOMAIN USUBJID SUBJID;
set raw.dm;
rename SUBJECT=SUBJID;
length USUBJID $40;
label STUDYID='Study Identifier' DOMAIN='Domain Abbreviation'
      SUBJECT='Subject Identifier for the Study'
      RFSTDTC='Subject Reference Start Date/Time';
STUDYID = 'CMP135';
DOMAIN = 'DM';
USUBJID = catx('-',STUDYID,SUBJECT);
run; 



/*Exposure data for RFSTDTC, RFXSTDTC, RFXENDTC, ACTARMCD, ACTARM*/
data ex1(keep=SUBJECT RFSTDTC RFXSTDTC ACTARMCD ACTARM EXSTDTN);
    set raw.ex;
    length RFSTDTC $10 RFXSTDTC $16;
    label RFSTDTC = 'Subject Reference Start Date/Time'
          SUBJECT = 'Subject Identifier for the Study'
          RFXSTDTC = 'Date/Time of First Study Treatment'
          ACTARMCD = 'Actual Arm Code'
          ACTARM = 'Description of Actual Arm';   
          
    /* Construct the RFSTDTC variable */
    RFSTDTC = put(mdy(EXSTDTN_MM, EXSTDTN_DD, EXSTDTN_YY), YYMMDD10.);
    /* Construct the RFXSTDTC variable */
    RFXSTDTC = catx('T', RFSTDTC, EXSTTM); 


if EXDOSE>0 then ACTARMCD='CMP135_5'; /*Assign 'CMP135_5', if subject received drug*/
if EXDOSE>0 then ACTARM='Group 1'; /*Assign 'Group 1', if subject received drug*/
run;
proc print;

proc sort data=ex1 out=sort_ex1;
by SUBJECT EXSTDTN;
run;

/*For RFXSTDTC*/
data ex2;
set sort_ex1;
rename SUBJECT=SUBJID;
if first.SUBJECT;
by SUBJECT;
run;

/*For RFXENDTC*/
data ex3(drop=RFSTDTC);
set sort_ex1;
rename SUBJECT=SUBJID RFXSTDTC=RFXENDTC;
if last.SUBJECT;
by SUBJECT;
run;

/*Merging data2, ex2, ex3; naming it as data3*/
proc sort data=data2 out=sort_data2;
by SUBJID;
run;

data data3;
merge sort_data2 ex2 ex3;
by SUBJID;
run;



/*Creating SDTM data: v2*/
data data4;
retain STUDYID DOMAIN USUBJID SUBJID RFSTDTC;
set data3;
run;
proc print;



/*Disposition data for RFENDTC*/
data ds1(keep=SUBJECT RFENDTC);
    set raw.ds;
    length RFENDTC $ 10 RFXENDTC $16;
    label RFENDTC = 'Subject Reference End Date/Time'
          SUBJECT = 'Subject Identifier for the Study'
          RFXENDTC = 'Date/Time of Last Study Treatment';

    /* Construct the RFENDTC variable */
    RFENDTC = put(mdy(DSSTDAT_MM, DSSTDAT_DD, DSSTDAT_YY), YYMMDD10.);
run;


proc sort data=ds1 out=sort_ds1(rename=(SUBJECT=SUBJID));
by SUBJECT;
run;

/*Merging data4 and sort_ds1; naming it as data5*/
proc sort data=data4 out=sort_data4;
by SUBJID;
run;

data data5;
merge sort_data4 sort_ds1;
by SUBJID;
run;



/*Creating SDTM data: v3*/
data data6;
retain STUDYID DOMAIN USUBJID SUBJID RFSTDTC RFENDTC RFXSTDTC RFXENDTC;
set data5;
run;



/*Enrollment data for RFICDTC, AGE, ARMCD, ARM*/
data enr1(keep=SUBJECT RFICDTC CNSTDTN ARMCD ARM);
    set raw.enr;
    length RFICDTC $10;
    label RFICDTC = 'Date/Time of Informed Consent'
          ARMCD = 'Planned Arm Code'
          ARM= 'Description of Planned Arm';

    /* Construct the RFICDTC variable */
    RFICDTC = put(mdy(CNSTDTN_MM, CNSTDTN_DD, CNSTDTN_YY), YYMMDD10.);

if ENRGRP='Group 1' then ARMCD = 'CMP135_5';
ARM = ENRGRP;
run;

proc sort data=enr1 out=sort_enr1(rename=(SUBJECT=SUBJID));
by SUBJECT;
run;


/*Merging data6 and sort_enr1; naming it as data7*/
proc sort data=data6 out=sort_data6;
by SUBJID;
run;

data data7;
merge sort_data6 sort_enr1;
by SUBJID;
run;



/*Creating SDTM data: v4*/
data data8;
retain STUDYID DOMAIN USUBJID SUBJID RFSTDTC RFENDTC RFXSTDTC RFXENDTC RFICDTC RFPENDTC;
label RFPENDTC='Date/Time of End of Participation';
set data7;
RFPENDTC=RFENDTC;
run;


/*Adverse Event data for DTHDTC, DTHFL*/
data ae1(keep=SUBJECT DTHDTC DTHFL);
    set raw.ae;
    length DTHDTC $1 DTHFL $1;
    label DTHDTC = 'Date/Time of Death'
          DTHFL = 'Subject Death Flag';

    /* Check if the event outcome is fatal and construct DTHDTC */
    if aeout = 'Fatal' then do;
        DTHDTC = put(mdy(AESTDTN_MM, AESTDTN_DD, AESTDTN_YY), YYMMDD10.);
    end;

    /* Assign 'Y' to DTHFL if DTHDTC is not missing */
    if not missing(DTHDTC) then DTHFL = 'Y';
run;


proc sort data=ae1 out=sort_ae1;
by SUBJECT;
run;

data ae2;
set sort_ae1;
rename SUBJECT=SUBJID;
if first.SUBJECT;
by SUBJECT;
run;

/*Merging data8 and ae2; naming it as data9*/
proc sort data=data8 out=sort_data8;
by SUBJID;
run;

data data9;
merge sort_data8 ae2;
by SUBJID;
run;



/*Creating SDTM data: v5*/
data data10;
retain STUDYID DOMAIN USUBJID SUBJID RFSTDTC RFENDTC RFXSTDTC RFXENDTC RFICDTC RFPENDTC DTHDTC DTHFL SITENUMBER;
set data9;
rename SITENUMBER = SITEID;
label SITENUMBER='Study Site Identifier';
run;


/*Investigator dataset for INVID INVNAM*/
data inv1(keep=INVID INVNAM COUNTRY SITEID);
length INVID $ 4 INVNAM $13;
set raw.inv;
INVNAM = catx(' ',strip(INVFNAME), strip(INVLNAME));
run;

proc sort data=inv1 out=sort_inv1;
by SITEID;
run;

/*Merging data10 and inv1*/
data data11;
merge data10(in=a) sort_inv1(in=b);
by SITEID;
if a;
RUN;



/*Creating SDTM data: v6*/
data data12;
retain STUDYID DOMAIN USUBJID SUBJID RFSTDTC RFENDTC RFXSTDTC RFXENDTC RFICDTC RFPENDTC DTHDTC DTHFL SITEID INVID 
       INVNAM BRTHDTC AGE AGEU SEX_COD RACE ETHNIC ARMCD ARM ACTARMCD ACTARM COUNTRY;
length BRTHDTC $ 10 RACE $ 5;
label INVID='Investigator Identifier'
      INVNAM='Investigator Name'
      BRTHDTC='Date/Time of Birth'
      AGE='Age'
      AGEU='Age Units'
      SEX_COD='Sex'
      ETHNIC='Ethnicity';
set data11(drop=SEX);
rename SEX_COD=SEX; 

/* Construct the BRTHDTC variable */
BRTHDTC = put(mdy(BRTHDTN_MM, BRTHDTN_DD, BRTHDTN_YY), YYMMDD10.);

/*Calculating Age*/
AGE=int(yrdif(datepart(BRTHDTN),datepart(CNSTDTN),'actual'));
AGEU='YEARS';
run;


/*Date of Visit data for DMDTC*/
data dov1 (keep= SUBJECT DMDTC);
    label DMDTC = 'Date/Time of Collection';
    length DMDTC $ 10;
    set raw.dov;
    where foldername = 'Screening';
    /* Construct the DMDTC variable */
    DMDTC = put(mdy(VISDTN_MM, VISDTN_DD, VISDTN_YY), YYMMDD10.);
run;

proc sort data=dov1 out=sort_dov1(rename=(SUBJECT=SUBJID));
by Subject;
run;

/*Merging data12 and sort_dov1*/
proc sort data=data12 out=sort_data12;
by SUBJID;
run;

data data13;
merge sort_data12(in=a) sort_dov1(in=b);
by SUBJID;
if a;
run;





/*Creating SDTM data: v7 ---> final SDTM*/
libname mysdtm '/home/u63774111/Project/Output';


data mysdtm.dm;
retain STUDYID DOMAIN SUBJID RFSTDTC RFENDTC RFXSTDTC RFXENDTC RFICDTC RFPENDTC DTHDTC DTHFL SITEID INVID 
       INVNAM BRTHDTC AGE AGEU SEX RACE ETHNIC ARM ACTARM COUNTRY DMDTC DMDY USUBJID ACTARMCD ARMCD;
keep STUDYID DOMAIN USUBJID SUBJID RFSTDTC RFENDTC RFXSTDTC RFXENDTC RFICDTC RFPENDTC DTHDTC DTHFL SITEID INVID 
       INVNAM BRTHDTC AGE AGEU SEX RACE ETHNIC ARMCD ARM ACTARMCD ACTARM COUNTRY DMDTC DMDY;
label DMDY='Study Day of Collection'
      RFXENDTC='Date/Time of Last Study Treatment';
set data13;
DMDY = intck('day',input(RFSTDTC,yymmdd10.),input(RFICDTC,yymmdd10.));
RACE = upcase(RACE);
ETHNIC = upcase(ETHNIC);
run;




/*Checking created SDTM data Specifications*/
proc contents data=mysdtm.dm varnum;
run;

proc print data=mysdtm.dm;
run;


proc printto;
run;

/*Reference:
  =========
Working SDTM-Spec-v1.xls
dm.xpt
*/