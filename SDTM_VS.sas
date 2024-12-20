/*Derving Vital signs Sdtm */
Options Validvarname =  Upcase missing =  '' ;





 
Data Vs1;
Set Raw.Demowide;
Usubjid = catx( '-', study, stdysite,patient);
Keep  Usubjid;
Run;


Data Vs2;
Set Raw.VITTEST (Drop = Studyid Rename= visit= visit_);
Studyid = Study;
Domain = "VS";
Usubjid = catx( '-', study, stdysite,patient);
VSTESTCD = Strip(TEST);
VSTEST = Strip(TEST);
 IF  TEST In ( "DIA_BP"  "SYS_BP"  "HEART_RATE" "RESP_RATE") THEN VSPOS  = Strip(POSITION);
VSORRES = Strip(LVALC);
If TEST IN ("HEIGHT",  "WEIGHT" , "TEMPERATURE" )  Then VSORRESU = UNIT;
VSSTRESC = Strip(Vsorres);
 VSSTRESN = Input(VSORRES,best.);
 
 VSSTRESU = Strip(VSORRESU);
 If Vsorres = '' THen VSSTAT = 'NOT DONE';
IF TEST = "TEMPERATURE" THEN DO;
    SELECT (METHOD);
      WHEN ("Oral") VSLOC = "ORAL CAVITY";
      WHEN ("Axillary") VSLOC = "AXILLA";
      WHEN ("Tympanic") VSLOC = "TYMPANIC MEMBRANE";
      OTHERWISE VSLOC = "";
    END;
  END;

VISITNUM = VISIT_;
  VISIT = Strip( CPENM);
If  VISITNUM =1 then VSBLFL = "Y";
else VSBLFL=  "N";
VSDTC = Put (Datepart(VISITDT),is8601da.);
Keep Studyid Domain Usubjid VSTESTCD VSTEST VSPOS VSORRES VSORRESU VSSTRESC  VSSTRESN VSSTRESU VSSTAT VISIT VISITNUM VSDTC VSBLFL ;

Run;

Proc sort data = Vs2;
By usubjid;
run;

Proc sort data = Vs1;
By usubjid;
run;



Data vs3;
Set Sdtm.dm;
Keep USUBJID RFSTDTC RFENDTC;
RUN;
PROC SORT DATA = Vs3;
by usubjid;
run;
 Data Vs4 ;
 Merge Vs2 (in = a) Vs3 (in = b);
 by usubjid;
 if a and b;
 run;

 Proc sort data = Vs4;
 by usubjid;
 run;


 DATA Vs5;
 Length Epoch $15;
SET Vs4;
IF RFSTDTC NE '' THEN RFSTDT=INPUT(RFSTDTC,YYMMDD10.);
IF RFENDTC NE '' THEN RFENDT=INPUT(RFENDTC,YYMMDD10.);

IF VSDTC NE '' THEN VSTDT= INPUT(VSDTC,YYMMDD10.);

IF NMISS(VSTDT,RFSTDT)=0 THEN DO;
IF VSTDT<RFSTDT THEN VSDY=VSTDT-RFSTDT;
ELSE IF VSTDT>=RFSTDT THEN VSDY=(VSTDT-RFSTDT)+1;
END;

IF VSDTC <RFSTDTC THEN EPOCH='SCREENING';
ELSE IF VSDTC>=RFSTDTC AND VSDTC <=RFENDTC THEN EPOCH='TREATMENT';
ELSE IF VSDTC>RFENDTC THEN EPOCH='FOLLOW-UP';
RUN;
  

Proc sort data = Vs5 Out = Vs6 Nodupkey Dupout = Vs7;
by usubjid VSTESTCD VSTDT;
Run;

Data Vs8;
Set Vs6;
Drop RFSTDTC RFENDTC RFSTDT RFENDT  VSTDT;
RUN;



Data Vs9;
Set Vs8;
By Usubjid;
If first. Usubjid then VSSEQ =1;
else VSSEQ+1;
RUN;

Data Sdtm.VS;
Set Vs9;
ATTRIB
STUDYID LABEL='Study Identifier'
DoMAIN LABEL='Domain'
USUBJID	LABEL='Unique Subject Identifier'
VSSEQ	LABEL='Sequence Number'
VSTESTCD LABEL = 'Vital Signs Test Short Name'
 VSTEST  LABEL = 'Vital Signs Test Name'
VSPOS LABEL = 'Vital Signs Position of Subject'
VSORRES   LABEL = 'Result or Finding in Original Units'
VSORRESU  LABEL = 'Original Units'
VSSTRESC LABEL = 'Character Result/Finding in Std Format'
VSSTRESN LABEL = 'Numeric Result/Finding in Standard Units'
VSSTRESU LABEL = 'Standard Units'
  VSSTAT  LABEL = 'Completion Status'
   VSLOC LABEL = 'Location of Vital Signs Measurement'
 VSBLFL LABEL = 'Baseline Flag'
    VISITNUM LABEL = 'Visit Number'
 VISIT LABEL = 'Visit Name'
     EPOCH    LABEL = ' Epoch'
       VSDY  LABEL = 'Study Day of Vital Signs';
	   run;

