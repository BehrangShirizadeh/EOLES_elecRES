$OnText
French power sector financial modelling for only renewable energies as supply technologies (Offshore and Onshore wind, PV and Hydro)
and Battery and PHS (pumped hydro storage) as storage technologies, for 2016;
Linear optimisation using one-hour time step with respect to Investment Cost.
By Behrang SHIRIZADEH -  February 2018
$Offtext

*-------------------------------------------------------------------------------
*                                Defining the sets
*-------------------------------------------------------------------------------
sets     h               'all hours'             /0*8783/
         i(h)            'experimental period'   /0*100/
         m               'month'                 /jan, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dec/
         tec             'technology'            /offshore, onshore, PV, river, lake, PHS1, PHS2, battery/
         vre(tec)        'variable tecs'         /offshore, onshore, PV/;
alias(h,hh);
*-------------------------------------------------------------------------------
*                                Inputs
*-------------------------------------------------------------------------------
$ontext
2016 had 366 days, and the hours of each month is as below:
January from 0 to 743, February from 744 to 1439, March from 1440 to 2183,
April from 2184 to 2903, May from 2904 to 3647, June from 3648 to 4367,
July from 4368 to 5111, August from 5112 to 5855, September from 5856 to 6575,
October from 6576 to 7319, November from 7320 to 8039 and December from 8040 to 8783.
$offtext
parameter month(h)  /0*743 1, 744*1439 2, 1440*2183 3, 2184*2903 4
                    2904*3647 5, 3648*4367 6, 4368*5111 7, 5112*5855 8
                    5856*6575 9, 6576*7319 10, 7320*8039 11, 8040*8783 12/
$Offlisting
parameter load_factor(vre,h) 'Production profiles of VRE'
/
$ondelim
$include  inputs/vre_inputs.csv
$offdelim
/;
parameter demand(h) 'demand profile in each hour in kW'
/
$ondelim
$include inputs/dem_input.csv
$offdelim
/;
Parameter lake_inflows(m) 'monthly lake inflows in GWh'
*Resource: RTE - Hourly nationwide electricity generation by sectors in 2016 for France
/
$ondelim
$include  inputs/lake_inflows.csv
$offdelim
/ ;
parameter gene_river(h) 'hourly run of river power generation in GWh'
*Resource: RTE - Hourly nationwide electricity generation by sectors in 2016 for France
/
$ondelim
$include  inputs/run_of_river.csv
$offdelim
/ ;
$Onlisting

$ontext
Resource: EUR 26950 EN – Joint Research Centre – Institute for Energy and Transport;
"Energy Technology Reference Indicator (ETRI) projections for 2010-2050", 2014, ISBN 978-92-79-44403-6.
$offtext
parameter CAPEX(tec) 'annualized capex cost in M€/GW/year' /offshore 92.82,onshore 55.44,PV 34.54,river 108,lake 65.15,PHS1 12.56, PHS2 28.99,battery 14.38/ ;
parameter fOM(tec) 'annualized fixed operation and maintenance costs M€/GW' /offshore 2.78,onshore 1.22,PV 0.86,river 1.62,lake 0.977,PHS1 0.188,PHS2 0.435,battery 0.201/ ;
parameter fuel_costs(tec) 'fuel cost in M€/GWh' /offshore 0,onshore 0,PV 0,river 0.005,lake 0.003,PHS1 0,PHS2 0,battery 0.0026/;
Parameter fixed_costs(tec) 'Fixed costs in M€/GW';
fixed_costs(tec) = (CAPEX(tec)+fOM(tec));
Parameter variable_costs(tec) 'Variable costs in M€/GWh';
variable_costs(tec)= fuel_costs(tec);
Parameter pump_capa 'pumping capacity in GWh';
pump_capa = 5.048;
parameter river_capa 'run of river capacity in GW' ;
river_capa = smax(h,gene_river(h));
scalar bat_eff_in 'battery charging efficiency' /0.9/;
scalar bat_eff_out 'battery decharging efficiency' /0.9/;
scalar pump_eff1 'pump input efficiency' /0.9/;
scalar pump_eff2 'pump input efficiency' /0.95/;
scalar turb_eff1 'turbine output efficiency' /0.8/;
scalar turb_eff2 'turbine output efficiency' /0.9/;
*-------------------------------------------------------------------------------
*                                Model
*-------------------------------------------------------------------------------
variables        GENE(tec,h)     'energy generation'
                 CAPA(tec)       'capacity'
                 STORAGE(h)      'hourly electricity input of battery storage'
                 COST            'final investment cost'
                 PUMP1(h)        'pumping for older PHS facilities'
                 PUMP2(h)        'pumping for new PHS faciltiies'
positive variables GENE(tec,h), CAPA(tec), STORAGE(h), PUMP1(h), PUMP2(h);
equations        gene_vre        'variables renewable profiles generation'
                 gene_cap        'capacity and genration relation for technologies'
                 batt_max        'generation of battery should be less than stored energy'
                 lake_res       'constraint on water for lake reservoirs'
                 adequacy        'supply/demand relation'
                 storage_const   'stored energy in first hour is equal to stored energy in the last hour'
                 PHS1_max        'maximum old PHS generation'
                 PHS2_max        'maximum new PHS generation'
                 obj             'the final objective function which is COST';
gene_vre(vre,h)..                GENE(vre,h)             =e=     CAPA(vre)*load_factor(vre,h);
gene_cap(tec,h)..                CAPA(tec)               =g=     GENE(tec,h);
batt_max..                       sum(h,GENE('battery',h))=l=     bat_eff_out*bat_eff_in*sum(h,STORAGE(h));
lake_res(m)..                    lake_inflows(m)         =g=     sum(h$(month(h) = ord(m)),GENE('lake',h));
storage_const..                  sum(h$(ord(h)=1),STORAGE(h)*bat_eff_in - GENE('battery',h)/bat_eff_out) =e= sum(h$(ord(h)<=card(h)), STORAGE(h)*bat_eff_in - GENE('battery',h)/bat_eff_out);
PHS1_max..                       sum(h,GENE('PHS1',h))   =l=     turb_eff1*pump_eff1*sum(h,PUMP1(h));
PHS2_max..                       sum(h,GENE('PHS2',h))   =l=     turb_eff2*pump_eff2*sum(h,PUMP2(h));
adequacy(h)..                    sum(tec,GENE(tec,h))    =g=     demand(h) + PUMP1(h) + STORAGE(h) + PUMP2(h);
obj..                            COST                    =e=     (sum(tec,CAPA(tec)*fixed_costs(tec)) +sum((tec,h),GENE(tec,h)*variable_costs(tec)))/1000;
*-------------------------------------------------------------------------------
*                                Initial and fixed values
*-------------------------------------------------------------------------------
PUMP1.up(h) = pump_capa;
CAPA.up('PHS1') = pump_capa;
CAPA.up ('river')= river_capa;
*-------------------------------------------------------------------------------
*                                Model options
*-------------------------------------------------------------------------------
model flore /all/;
option solvelink=2;
option RESLIM = 1000000;
option lp=cplex;
option Savepoint=1;
option solveopt = replace;
option limcol = 0;
option limrow = 0;
option SOLPRINT = OFF;
*-------------------------------------------------------------------------------
*                                Solve statement
*-------------------------------------------------------------------------------
$If exist res_p1.gdx execute_loadpoint 'res_p1';
Solve flore using lp minimizing COST;
*-------------------------------------------------------------------------------
*                                Display statement
*-------------------------------------------------------------------------------
display cost.l;
display capa.l;
display gene.l;
display demand;
parameter sumdemand      'the whole demand per year in TWh';
sumdemand =  sum(h,demand(h))/1000;
parameter sumgene        'the whole generation per year in TWh';
sumgene = sum((tec,h),GENE.l(tec,h))/1000 - sum (h,gene.l('battery',h))/1000 - sum(h,GENE.l('PHS1',h))/1000;
display sumdemand; display sumgene;
parameter battery_storage 'needed energy storage per year in TWh';
battery_storage = sum (h,GENE.l('battery',h))/1000;
display battery_storage;
parameter sumgene_river  'yearly hydro-river energy generation in TWh';
sumgene_river = sum(h,GENE.l('river',h))/1000;
parameter sumgene_lake  'yearly hydro-lake energy generation in TWh';
sumgene_lake = sum(h,GENE.l('lake',h))/1000;
parameter sumgene_PHS1  'yearly hydro-PHS (old) energy generation in TWh';
sumgene_PHS1 = sum(h,GENE.l('PHS1',h))/1000;
parameter sumgene_PHS2  'yearly hydro-PHS (new) energy generation in TWh';
sumgene_PHS2 = sum(h,GENE.l('PHS2',h))/1000;
parameter sumgene_offshore  'yearly offshore energy generation in TWh';
sumgene_offshore = sum(h,GENE.l('offshore',h))/1000;
parameter sumgene_onshore  'yearly onshore energy generation in TWh';
sumgene_onshore = sum(h,GENE.l('onshore',h))/1000;
parameter sumgene_PV  'yearly PV energy generation in TWh';
sumgene_PV = sum(h,GENE.l('PV',h))/1000;
display sumgene_river;
display sumgene_lake;
display sumgene_PHS1;
display sumgene_PHS2;
display sumgene_offshore;
display sumgene_onshore;
display sumgene_PV;
*-------------------------------------------------------------------------------
*                                Output
*-------------------------------------------------------------------------------
$Ontext
two main output files;
The .txt file just to have a summary and general idea of the key numbers
The .csv file to have a fine output with hourly data for final data processing and analysis
$Offtext

file results1 /results1.txt/ ;
*the .txt file  
put results1;
put '                            the main results' //
//
'I)Overall investment cost is' cost.l 'b€' //
//
'II)the Renewable capacity ' //
'PV              'capa.l('PV')'  GW'//
'Offshore        'capa.l('offshore')'    GW'//
'onsore          'capa.l('onshore')'     GW' //
'run of river    'CAPA.l('river') 'GW' //
'lake            'CAPA.l('lake') 'GW' //
'Pumped Storage (old)  'CAPA.l('PHS1') 'GW' //
'Pumped Storage (new)  'CAPA.l('PHS2') 'GW' //
'Battery Storage 'capa.l('battery')'     GW' //
//
'III)Needed storage' //
'Battery Storage         'battery_storage'       TWh' //
'Old PHS Storage         'sumgene_PHS1'       TWh' //
'New PHS Storage         'sumgene_PHS2'       TWh' //
//
;
file results11 /results1.csv / ;
*the .csv file
put results11;
results11.pc=5;
put 'hour'; put 'Offshore';  put 'Onshore'; put 'PV'; put 'lake' ; put 'river' ; put 'PHS old' ; put 'PHS new' ; put 'battery'; put 'demand'/ ;
loop (h,
put h.tl; put gene.l('offshore',h); put gene.l('onshore',h); put gene.l('PV',h); put GENE.l('lake',h);put GENE.l('river',h);put GENE.l('PHS1',h);put GENE.l('PHS2',h); put gene.l('battery',h); put demand(h)/ ;
;);

$onecho > sedscript
s/\,/\;/g
$offecho
$call sed -f sedscript results1.csv > results2.csv

$onecho > sedscript
s/\./\,/g
$offecho
$call sed -f sedscript results2.csv > results.csv
*-------------------------------------------------------------------------------
*                                The End :D
*-------------------------------------------------------------------------------
