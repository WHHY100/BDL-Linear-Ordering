/*
==========================================================================
Clean work
==========================================================================
*/
proc datasets library=work kill nolist;
quit;

/*
==========================================================================
Config local paths.
==========================================================================
*/
%let data_path = ;
%let pathImgExport = ;

/*define name for input file*/
data tab_input_file_paths;
infile datalines delimiter='|'; 
length id 3 path $2000.;
input id path $;
datalines;                      
01|average_salary.csv
02|criminals.csv
03|deaths_in_cars_accidents.csv
04|inflation_rate.csv
05|km_roads_per_100_kmsq.csv
06|new_cars.csv
07|number_of_people.csv
08|people_per_one_place_hospital.csv
09|price_1_square_meter_apartment.csv
10|registered_unemployment.csv
11|thefts.csv
;
run;

/*
==========================================================================
Determining variables is a stimulant(positive) or destimulant(negative)
==========================================================================
*/

data tab_dict_type_var;
infile datalines delimiter='|'; 
length id 3 type_var $2000.;
input id type_var $;
datalines;                      
01|stimulant
02|destimulant
03|destimulant
04|destimulant
05|stimulant
06|stimulant
07|indifferent
08|destimulant
09|destimulant
10|destimulant
11|destimulant
;
run;

/*
==========================================================================
Import all data to one big dataframe.
==========================================================================
*/

%macro import;
proc sql noprint;
select max(id) into: maxId from tab_input_file_paths
;quit;

%do i = 1 %to &maxId;
	
	/*path*/
	proc sql noprint;
	select 
		cats("&data_path", path) into: filePath 
	from tab_input_file_paths 
	where id = &i
	;quit;
	
	/*dataframe name*/
	proc sql noprint;
	select 
		substr(path, 1, index(path, '.csv') - 1) into: dataframeName 
	from tab_input_file_paths 
	where id = &i
	;quit;

	/*set file encoding*/
	filename file "&filePath" encoding='wlatin2';
	
	/*import file (problem with length variables) to check the name of col 4*/
	proc import datafile=file
	out=tab_csv_cols
	dbms=dlm replace;
	delimiter=';';
	getnames=no;
	run;
	
	data tab_csv_cols;
	set tab_csv_cols(obs=1);
	run;
	
	/*get name of col 4*/
	proc sql noprint;
	select VAR4 into: colname from tab_csv_cols
	;quit;
	
	proc delete data=tab_csv_cols;
	run;

	/*write data to dataframe*/	
	data &dataframeName;
	infile file
	delimiter = ";"
	firstobs=2;
	length id 3 area $200. year 3;
	input id area year val;  
	run;
		
	/*put data together*/
	%if &i = 1 %then %do;
		data tab_data;
		set &dataframeName;
		var = "&dataframeName";
		run;
	%end;
	%else %do;
		
		data &dataframeName;
		set &dataframeName;
		var = "&dataframeName";
		run;
	
		data tab_data;
		set tab_data &dataframeName;
		run;	
	%end;
	
	proc delete data=&dataframeName;
	run;
	
%end;
%mend;

%import;

/*
==========================================================================
Check min year for group of data some variables start from 2000, some 2003.
We want to find min year where all observations are filled.
==========================================================================
*/

proc sql;
create table tab_min_year as
select
	var
	,min(year) as min_year
from tab_data
group by var
;quit;

proc sql noprint;
select max(min_year) into: yearAllObsAvalaible from tab_min_year
;quit;

proc delete data=tab_min_year;
run;

data tab_data;
set tab_data;
where year >= &yearAllObsAvalaible;
run;

/*
==========================================================================
We have some variables in absolute numbers. In this step we will convert then
to numbers per one person in area.

Vars in absolute numbers:
-criminals
-deaths_in_car_accidents
-thefts
==========================================================================
*/

/*get the variable with number of people to new dataframe*/
data tab_counter_people_area;
set tab_data;
where var = 'number_of_people';
rename val = number_of_people;
run;

/*assign number of people to area and year*/
proc sql;
create table tab_data_people as
select
	a.*
	,b.number_of_people
from tab_data a
left join tab_counter_people_area b on a.area = b.area and a.year = b.year
where
	a.var ne 'number_of_people'
order by a.area, a.year
;quit;

/*recalculate and rename*/
data tab_data;
retain id area year correct_val correct_var number_of_people;
length correct_var $1000.;
set tab_data_people;
if var in ('criminals', 'deaths_in_cars_accidents', 'thefts') then
	correct_val = round(val/number_of_people, .0001);
else
	correct_val = val;
if var eq 'criminals' then 
	correct_var = 'criminals_per_person';
else if var eq 'deaths_in_cars_accidents' then 
	correct_var = 'deaths_in_cars_accidents_per_person';
else if var eq 'thefts' then 
	correct_var = 'thefts_per_person';
else 
	correct_var = var;
drop val number_of_people;
run;

proc delete data=tab_counter_people_area;
run;

proc delete data=tab_data_people;
run;

/*
==========================================================================
Create dictionary for variables.
Some of variables are to loong to sas colname.
Adding the type of war to dataframe.
==========================================================================
*/

proc sql;
create table tab_varnames as
select distinct
	a.correct_var
	,c.type_var
from tab_data a
left join tab_input_file_paths b on a.var = tranwrd(b.path, '.csv', '')
left join tab_dict_type_var c on b.id = c.id
order by correct_var
;quit;

data tab_varnames;
set tab_varnames;
var_code = cats('X', _N_);
run;

proc sql;
create table tab_data_code_var as
select
	a.*
	,b.var_code
	,b.type_var
from tab_data a
left join tab_varnames b on a.correct_var = b.correct_var
;quit;

data tab_data;
set tab_data_code_var;
drop var;
run;

proc delete data = tab_varnames;
run;

proc delete data = tab_data_code_var;
run;

/*
==========================================================================
Linear ordering algorithm
==========================================================================
*/

/*loop contraints*/
proc sql noprint;
select min(year) into: minYear from tab_data
;quit;

/*2021 -> incomplete data*/
proc sql noprint;
select max(year) - 1 into: maxYear from tab_data
;quit;

%macro linear_ordering;

%do i = &minYear %to &maxYear;
	
	data tab_entry_data;
	set tab_data;
	where year = &i;
	run;
	
	/*count area*/
	proc sql noprint;
	select 
		count(*) into: countArea
	from tab_entry_data
	;quit;
	
	/*add mean and sum to data*/
	proc sql;
	create table tab_data_sd_1 as
	select
		a.var_code
		,mean(a.correct_val) as mean
		,sum(a.correct_val) as sum
	from tab_entry_data a
	group by a.var_code
	;quit;
	
	/*pre standard deviation -> val_minus_mean*/
	proc sql;
	create table tab_data_sd_2 as
	select
		a.*
		,(a.correct_val - b.mean) ** 2 as val_minus_mean_sq
	from tab_entry_data a
	left join tab_data_sd_1 b on a.var_code = b.var_code
	;quit;
	
	/*estimate standard deviation*/
	proc sql;
	create table tab_data_sd_3 as
	select
		var_code
		,mean(correct_val) as mean
		,(sum(val_minus_mean_sq)/&countArea) ** 0.5 as standard_deviation
	from tab_data_sd_2
	group by var_code
	;quit;
	
	/*standarization of variables*/
	proc sql;
	create table tab_standarization as
	select
		a.area
		,a.var_code
		,(a.correct_val - b.mean)/b.standard_deviation as correct_val_s
		,a.type_var
	from tab_entry_data a
	left join tab_data_sd_3 b on a.var_code = b.var_code
	;quit;
	
	/*create pattern and anti-pattern*/
	proc sql;
	create table tab_pattern as
	select distinct
		var_code
		,case
			when type_var = 'destimulant' then min(correct_val_s)
			when type_var = 'stimulant' then max(correct_val_s)
		 end as reference_value
	from tab_standarization
	group by var_code
	;quit;
	
	proc sql;
	create table tab_antipattern as
	select distinct
		var_code
		,case
			when type_var = 'destimulant' then max(correct_val_s)
			when type_var = 'stimulant' then min(correct_val_s)
		 end as anti_reference_value
	from tab_standarization
	group by var_code
	;quit;
	
	/*estimate D0 parameter - need to estimate the Mi*/
	proc sql;
	create table tab_d0_estimate as
	select
		a.var_code
		,(a.reference_value - b.anti_reference_value) ** 2 as distance_patt_antipatt
	from tab_pattern a
	left join tab_antipattern b on a.var_code = b.var_code
	;quit;
	
	proc sql noprint;
	select (sum(distance_patt_antipatt)) ** 0.5 into: D0 from tab_d0_estimate
	;quit;
	
	/*Euclidean distance for area from the pattern*/
	/*higher Mi index -> area closer patter (better place to live)*/
	proc sql;
	create table tab_distance as
	select
		a.area
		,1 - (((sum((a.correct_val_s - b.reference_value) ** 2)) ** 0.5)/&D0) as Mi
	from tab_standarization a
	left join tab_pattern b on a.var_code = b.var_code
	group by a.area
	;quit;
	
	/*create simply ranking*/
	proc sort data=tab_distance;
	by descending Mi;
	run;
	
	data tab_ranking_&i;
	retain ranking;
	set tab_distance;
	ranking = _N_;
	run;
	
	proc transpose data=tab_distance out=tab_result(drop=_NAME_);
	id area;
	run;
	
	/*put result together to one dataframe*/
	%if &i = &minYear %then %do;
		data tab_Mi_per_year;
		retain year;
		set tab_result;
		year = &i;
		run;
	%end;
	%else %do;
		data tab_Mi_per_year_prev;
		retain year;
		set tab_result;
		year = &i;
		run;
		
		data tab_Mi_per_year;
		set tab_Mi_per_year tab_Mi_per_year_prev;
		run;
		
		proc delete data=tab_Mi_per_year_prev;run;
	%end;
	
	/*clean work from unnecessary table*/
	proc delete data=tab_antipattern;run;
	proc delete data=tab_D0_estimate;run;
	proc delete data=tab_data_sd_1;run;
	proc delete data=tab_data_sd_2;run;
	proc delete data=tab_data_sd_3;run;
	proc delete data=tab_distance;run;
	proc delete data=tab_entry_data;run;
	proc delete data=tab_pattern;run;
	proc delete data=tab_standarization;run;
%end;
%mend;

%linear_ordering;

/*
==========================================================================
Result graphs
==========================================================================
*/

/*all area in all years*/
ods graphics on/ reset=index imagename='Summary_all_years' imagefmt=jpg;
ods listing gpath="&pathImgExport";
title color="#00008B" "Ranking of Poland area";
proc sgplot data=tab_Mi_per_year;
series x = year y = WIELKOPOLSKIE / lineattrs=(color=black pattern=dash);
series x = year y = MAZOWIECKIE / lineattrs=(color=black pattern=dot);
series x = year y = POMORSKIE / lineattrs=(color=black pattern=solid);
series x = year y = ŁÓDZKIE / lineattrs=(color=black pattern=MediumDashDotDot);
series x = year y = MAŁOPOLSKIE / lineattrs=(color=green pattern=dash);
series x = year y = LUBELSKIE / lineattrs=(color=green pattern=dot);
series x = year y = ŚLĄSKIE / lineattrs=(color=green pattern=solid);
series x = year y = DOLNOŚLĄSKIE / lineattrs=(color=green pattern=MediumDashDotDot);
series x = year y = LUBUSKIE / lineattrs=(color=red pattern=dash);
series x = year y = PODLASKIE / lineattrs=(color=red pattern=dot);
series x = year y = PODKARPACKIE / lineattrs=(color=red pattern=solid);
series x = year y = OPOLSKIE / lineattrs=(color=red pattern=MediumDashDotDot);
series x = year y = "KUJAWSKO-POMORSKIE"n/ lineattrs=(color=Violet pattern=dash);
series x = year y = "WARMIŃSKO-MAZURSKIE"n/ lineattrs=(color=Violet pattern=dot);
series x = year y = ŚWIĘTOKRZYSKIE/ lineattrs=(color=Violet pattern=solid);
series x = year y = ZACHODNIOPOMORSKIE/ lineattrs=(color=Violet pattern=MediumDashDotDot);
YAXIS LABEL = 'Index Mi';
run;
ods graphics off;
ods listing close;

/*find the table with last year analysis*/
proc contents noprint data=work._ALL_ out=table_work(keep=MEMNAME);
run;

proc sql noprint;
select distinct 
	MEMNAME into: finRanking 
from (
	select
		MEMNAME
		,input(substr(MEMNAME, 13, 4), best12.) as year
	from table_work
	where 
		MEMNAME contains('RANKING')
)
having year = max(year)
;quit;

/*last yeat of analysis*/
ods graphics on/ reset=index imagename="Summary_&maxYear" imagefmt=jpg;
ods listing gpath="&pathImgExport";
title color="#00008B" "Taxonomic measure of development";
proc sgplot data=&finRanking;
vbar area / response = mi dataskin=crisp datalabel categoryorder=RespDesc;
xaxis label = "area";
yaxis label = "Taxonomic measure of development";
run;
ods graphics off;
ods listing close;
