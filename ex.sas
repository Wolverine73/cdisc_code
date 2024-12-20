/*log file*/
proc printto log='/home/u63774111/Project/Log files/ex.log';

libname raw "/home/u63774111/Project/Project_2/Raw_CRF";

/*Initially, 1904 rows; 32 columns*/

data data1;
set raw.ex;
run; 


/*To see the variable names in raw DM data*/
proc contents data=data1 varnum;
run;


/* Creating SDTM data: v1 */
data data2;
length EXTRT $10 USUBJID $40;
label STUDYID='Study Identifier' 
      DOMAIN='Domain Abbreviation'
      EXTRT='Name of Actual Treatment'
      EXDOSE='Dose per Administration'
      EXDOSU='Dose Units'
      EXDOSFRM='Dose Form'
      EXROUTE='Route of Administration';
set data1;
STUDYID = 'CMP135';
DOMAIN = 'EX';
EXTRT = 'CMP135';
EXDOSU = 'mg';
EXDOSFRM = 'INJECTION';
EXROUTE = 'SUBCUTANEOUS';
USUBJID = catx('-', STUDYID, SUBJECT);
run;


/*EXSTDY*/
/*Determing baseline date*/
data data3;
set data2;
if exdose>0;
run;

proc sort data=data3 out=sort_data3;
by SUBJECT EXSTDTN;
run;

data data4(keep=SUBJECT date_baseline);
set sort_data3;
by SUBJECT EXSTDTN;
if first.SUBJECT;
date_baseline=datepart(EXSTDTN);
run;


/*Combining two datasets*/
proc sort data=data2 out=sort_data2;
by SUBJECT;
run;

proc sort data=data4 out=sort_data4;
by SUBJECT;
run;

data data5;
merge sort_data2(in=a) sort_data4(in=b);
by SUBJECT;
if a;
run;


data data6;
    set data5;
    label EXSTDY='Study Day of Start of Treatment';
    if datepart(EXSTDTN) >= date_baseline then 
        EXSTDY = (datepart(EXSTDTN) - date_baseline + 1);
    else 
        EXSTDY = (datepart(EXSTDTN) - date_baseline);
run;

/*EXSTDTC*/
data data7;
label EXSTDTC='Start Date/Time of Treatment';
length EXSTDTC $16;
set data6;
if EXSTTM NE '' then do;
   if length(EXSTTM)=5 then do;
      EXSTDTC = cat(put(datepart(EXSTDTN), yymmdd10.),'T',strip(EXSTTM));
      end;
   else if length(EXSTTM)=4 then do;
           EXSTDTC = cat(put(datepart(EXSTDTN), yymmdd10.),'T0',strip(EXSTTM));
           end;
   end;
else do;
     EXSTDTC = put(datepart(EXSTDTN), yymmdd10.);
     end;
run;


/*EPOCH*/
data data8;
set raw.se;
run;

/*Transposing Start Dates*/
proc transpose data=data8 out=transp_data8(drop=_:) prefix=ST_;
by USUBJID;
id ETCD;
var SESTDTC;
run;

/*Transposing End Dates*/
proc transpose data=data8 out=transp1_data8(drop=_:) prefix=EN_;
by USUBJID;
id ETCD;
var SEENDTC;
run;

/*Get EPOCH from SE domain by checking dates of EXSTDTC between SESTDTC and SEENDTC*/
data data9;
label EPOCH='Epoch';
length USUBJID $40 EPOCH $11;
merge data7 transp_data8 transp1_data8;
by USUBJID;
     if input(ST_FU, yymmdd10.) <= input(EXSTDTC, yymmdd10.) <= input(EN_FU, yymmdd10.) then EPOCH='FOLLOW-UP';
     else if input(ST_P3, yymmdd10.) <= input(EXSTDTC, yymmdd10.) <= input(EN_P3, yymmdd10.) then EPOCH='MAINTENANCE';
     else if input(ST_P2, yymmdd10.) <= input(EXSTDTC, yymmdd10.) <= input(EN_P2, yymmdd10.) then EPOCH='TITRATION';
     else if input(ST_P1, yymmdd10.) <= input(EXSTDTC, yymmdd10.) <= input(EN_P1, yymmdd10.) then EPOCH='INDUCTION';
     else if input(ST_SCRN, yymmdd10.) <= input(EXSTDTC, yymmdd10.) <= input(EN_SCRN, yymmdd10.) then EPOCH='SCREENING';
run;


/*EXLOC*/
data data10;
label EXLOC='Location of Dose Administration';
length EXLOC $20;
set data9;
EXLOC=upcase(EXLOC);
if EXLOC='OTHER' then EXLOC=upcase(EXLOCOTH);
run;


/*EXSEQ*/
proc sort data=data10 out=sort_data10;
by STUDYID USUBJID EXTRT EXSTDTC;
run;

data data11;
label EXSEQ='Sequence Number';
set sort_data10;
by STUDYID USUBJID EXTRT EXSTDTC;
if first.USUBJID then EXSEQ=0;
EXSEQ+1;
run;


/*Creating SDTM data: v2*/
libname mysdtm '/home/u63774111/Project/Output';

data mysdtm.ex;
keep STUDYID DOMAIN EXSEQ EXTRT EXDOSE EXDOSU EXDOSFRM EXROUTE EXLOC EXSTDTC EXSTDY USUBJID EPOCH;
retain STUDYID DOMAIN EXSEQ EXTRT EXDOSE EXDOSU EXDOSFRM EXROUTE EXLOC EPOCH EXSTDTC EXSTDY USUBJID;
set data11;
run;
proc print;

proc contents data=mysdtm.ex varnum;
run;


proc printto;
run;


/*Reference:
  =========
Working SDTM-Spec-v1.xls
ex.xpt
Reference Code
*/
