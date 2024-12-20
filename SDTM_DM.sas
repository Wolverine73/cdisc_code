
options validvarname = Upcase missing = '';
Proc format;
Value $tpc
"A" =  "40 mg/day"
"B"= 	"80 mg/day "
"C" = "120 mg/day"
"D"= 	"180 mg/day"
"E"	=  "240 mg/day"
"F" = 	"320 mg/day"
"G"=	"400 mg/day"
"J"= 	"320 mg/day - MTD" ;
run;




Data demo1 (Rename= (Sex1= Sex Race1 = Race Ethnic1 = Ethnic));
Length studyid subjid brthdtc $10 Doamain $2  Sex1 $1 usubjid $18 siteid Ageu $5 Race1 Ethnic1 $40 racoth$40 subjini $3 ;
Set Raw.Demowide( where = (tpcode ne '') drop = studyid Ageu);
STUDYID = study;
Domain = 'DM';
Usubjid = catx( '-', study, stdysite,patient);
subjid = catx ('-', stdysite , patient);
siteid = stdysite;
brthdtc = Put(Datepart(Birthd), is8601da.);
Ageu = 'YEARS';
Sex1= substr (sex,1,1);
If Race = "Hispanic" then Race1 = " ";
 else If index( Race, "OTHER") > 0 then Race1 = "OTHER";
else if Race ='African American' then Race1	='BLACK OR AFRICAN AMERICAN';
ELSE Race1 = upcase(Race);
If Race = "Hispanic" then Ethnic1 = "Hispanic or Latino";
Else Ethnic1 = '';
DMDTC = Put(Datepart(INTVDT), is8601da.);


Keep studyid Domain Usubjid subjid Age Ageu siteid  brthdtc Sex1 Race1 Ethnic1 country  Dmdtc  ;
run;

Proc sort data = demo1;
by Usubjid;
Run;



Data Med1;
Length Usubjid$18 RFXSTDTC $19;
Set Raw.Stdymedl;
where tpcode ne '' and STINT="Single Dose Period"  ;
USUBJID = catx('-',STUDY,STDYSITE,PATIENT);
If startdtp='MI' then Rfxstdtc=put(Startdt,is8601dt.);
Keep Usubjid RFXSTDTC; 
Run;

Data Med2;
Length Usubjid$18 RFXENDTC $19;
set Raw.Stdymedl(where=(tpcode ne ''));
USUBJID = catx('-',STUDY,STDYSITE,PATIENT);
RFXENDTC = Put (datepart(STOPDT), is8601da.);
Keep Usubjid RFXENDTC;
RUN;

proc sort data=Med2;
by usubjid Rfxendtc;
run;
Data endt;
set Med2;
if last.usubjid;
by usubjid Rfxendtc;
run;
Proc sort data = Med1;
by usubjid;
Run;
Proc sort data = endt;
by Usubjid;
Run;

data trtsdt;
merge Med1(in =a) endt (in=b);
by USUBJID;
if a;
   If Usubjid='3144102-007-000708' and rfxendtc='' then rfxendtc=Substr(Rfxstdtc,1,10);
run;

Proc sort data = trtsdt;
by Usubjid;
run;

Proc sort data=Raw.random out=rndn;
where tpcode ne '' and randn ne '';
by Patient;
run;

Data Rndn1;
Length  Usubjid $18 RFSDTC randn $10 ARMCD Actarmcd $20 Arm Actarm $40  ;
Set rndn;
Usubjid = catx( '-', study, stdysite,patient);
RFSTDTC = put(Datepart(VISITDT), is8601da.);
ARMCD = strip (TPCODE) ;
Actarmcd = strip (TPCODE) ;
Arm = put ( tpcode, $tpc.);
Actarm = strip(Arm);
RANDN = randn;
Keep RFSTDTC Usubjid ARMCD Actarmcd Arm Actarm tpcode randn ;
Run;


Proc sort data = Rndn1;
by Usubjid;
Run;


Data demo2;
Merge demo1(In=a) trtsdt(in=b) rndn1(in=c);;
By Usubjid;
if a ;


IF randn eq '' then do;
armcd='SCRNFAIL';
arm='Screen Failure';
end;

if Randn ne '' and tpcode eq '' then do;
armcd='NOTASSGN';
arm='Not Assigned';
end;

 if  randn ne '' and tpcode ne '' and rfxstdtc='' then do;
 armcd='NOTTRT';
 arm='Not Treated';
 end;

 Actarmcd=strip(Armcd);
 Actarm=Strip(ARm);
run;




data Conclus1;
set Raw.Conclus(encoding = any);
length USUBJID $18 RFENDTC RFPENDTC $10;
where tpcode ne '' and STINT= "Final Evaluation";
USUBJID = catx('-',STUDY,STDYSITE,PATIENT);
RFENDTC = put(datepart(TERMDT),is8601da.);
RFPENDTC = put(datepart(TERMDT),is8601da.);
Keep USUBJID RFENDTC RFPENDTC;
run;


Proc sort data = Conclus1;
by Usubjid;
Run;




data Eligibil2;
length usubjid $18 rficdtc $10;
set Raw.Eligibil(where = (tpcode ne '' and upcase(LBLSTYP)= "CONSENT")encoding = any);
USUBJID = catx('-',STUDY,STDYSITE,PATIENT);
RFICDTC = put(datepart(CONSDT),is8601da.);
Keep USUBJID RFICDTC;
run;

proc sort data = Eligibil2  ; by usubjid rficdtc; run;  


data Eligibil3;
set Eligibil2;
by usubjid rficdtc;
if first.usubjid;
run;

proc sort data = Eligibil3  ; by usubjid ; run;  


data death1;
set Raw.death(encoding = any where=(tpcode ne ''));
length USUBJID $18 DTHDTC $10 DTHFL $1;
USUBJID = catx('-',STUDY,STDYSITE,PATIENT);
if deathdt ne . then do ;
DTHDTC = put(datepart(DeathDT),is8601da.) ;
DTHFL = "Y";
end  ;
if deathdt eq . then do ;
DTHDTC = "" ;
DTHFL = "";
end  ;  
Keep USUBJID DTHDTC DTHFL;
run;

Proc sort data = death1;
by usubjid;
run;
proc sort data = Death1 out=dth nodupkey ; by usubjid dthdtc ; run;  


Data Demo3;
merge demo2 (in=a)  Conclus1(in =c)  dth(in =e) Eligibil3 ;
by USUBJID;
if a;
RUN;



data demo4;
set demo3;
length USUBJID $18 DMDY 3;

Rfstdt = input(RFSTDTC,yymmdd10.);
Rfxstdt = input (RFXSTDTC,yymmdd10.);
Dmdt = input(DMDTC,yymmdd10.);


If Rfstdt=Rfxstdt  AND Dmdt<Rfstdt  THEN do;
IF Nmiss(Rfstdt,Dmdt)=0 then do;
If Dmdt<Rfstdt then DMDY=Dmdt-Rfstdt; 
ELSE IF Dmdt>=Rfstdt THEN DMDY=(Dmdt-Rfstdt)+1;
end;
end;

IF Rfstdt <Rfxstdt AND Dmdt<Rfxstdt  THEN do;
IF Nmiss(Rfxstdt,Dmdt)=0 then do;
If Dmdt<Rfxstdt then DMDY=Dmdt-Rfxstdt; 
ELSE IF Dmdt>=Rfxstdt THEN DMDY=(Dmdt-Rfxstdt)+1;
end;
end;

keep Studyid Domain Usubjid Subjid Rfstdtc Rfendtc Rfxstdtc Rfxendtc brthdtc Rficdtc Rfpendtc Dthdtc Dthfl
     Sex Race Ethnic Age Ageu Country Siteid Armcd Arm Actarmcd Actarm Dmdtc DMDY   ;
	 run;

Proc sort Data=demo4 out=fin;
by Usubjid;
run;

data Sdtm.dm;
set fin;
ATTRIB
Studyid label='Study Identifier'
Domain Label='Domain Abbreviation'
Usubjid label='Unique Subject Identifier'
Subjid label='Subject Identifier for the Study'
RFSTDTC	label = 'Subject Reference Start Date/Time'
RFENDTC Label = '	Subject Reference End Date/Time' 
RFXSTDTC Label = 'Date/Time of First Study Treatment' 
RFXENDTC Label = 'Date/Time of Last Study Treatment'
RFICDTC	 Label ='Date/Time of Informed Consent'
RFPENDTC Label = 'Date/Time of End of Participation'
DTHDTC Label = '	Date/Time of Death '
DTHFL Label = 'Subject Death Flag'
SITEID Label = 	'Study Site Identifier'
BRTHDTC Label = 'Date/Time of Birth'
AGE label = '	Age' 
AGEU Label = '	Age Units'
SEX	 Label = 'Sex'
RACE Label= 'Race'
ETHNIC Label = 'Ethnicity'
ARMCD Label =	'Planned Arm Code'
ARM	 label = 'Description of Planned Arm'
ACTARMCD Label = 'Actual Arm Code'
ACTARM	label ='Description of Actual Armcd'
COUNTRY Label = '	Country'
DMDTC Label = '	Date/Time of Collection'
DMDY Label = 'Study Day of Collection';


Run;










 
