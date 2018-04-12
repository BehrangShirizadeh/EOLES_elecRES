$OnText
French power sector financial modelling for only renewable energies as supply technologies (Offshore and Onshore wind, PV, Hydroelectricity and biogas)
and Battery and PHS (pumped hydro storage) as storage technologies,including primary and secondary reserve requirements for meteo and electricity consumption data of 2016;

Offshore and onshore wind power, Solar power and biogas capacities as well as battery storage and hydrogen (P2G) storage capacity are chosen endogenousely, while hydroelectricity lake and run-of-river and Phumped hydro storage capacities are chosen exogenousely.

Existing capacities by December 2017 are also entered as lower bound of each capacity, and investment cost for existing capacities has been considered zero.

Linear optimisation using one-hour time step with respect to Investment Cost.

By Behrang SHIRIZADEH -  March 2018
$Offtext

*-------------------------------------------------------------------------------
*                                Defining the sets
*-------------------------------------------------------------------------------
sets     h               'all hours'                     /0*8783/
         first(h)        'first hour'
         last(h)         'last hour'
         m               'month'                         /jan, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dec/
         tec             'technology'                    /offshore, onshore, pv, river, lake, biogas, phs, battery, hydrogen, methanation/
         gen(tec)        'power plants'                  /offshore, onshore, pv, river, lake, biogas/
         vre(tec)        'variable tecs'                 /offshore, onshore, pv/
         str(tec)        'storage technologies'          /phs, battery, hydrogen, methanation/
         frr(tec)        'technologies for upward FRR'   /lake, biogas, phs, battery, methanation/
;
first(h) = ord(h)=1;
last(h) = ord(h)=card(h);
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
$include  inputs/vre_inputs_max_3.csv
$offdelim
/;
parameter demand(h) 'demand profile in each hour in GW'
/
$ondelim
$include inputs/dem_electricity.csv
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
parameter epsilon(vre) 'additional FRR requirement for variable renewable energies because of forecast errors'
/
$ondelim
$include  inputs/reserve_requirements.csv
$offdelim
/ ;

parameter capa_ex(tec) 'existing capacities of the technologies by December 2017 in GW'
*Resource: RTE
/
$ondelim
$include  inputs/existing_capacities.csv
$offdelim
/ ;
$ontext
1) Resource for the costs of power plants : EUR 26950 EN – Joint Research Centre – Institute for Energy and Transport;
"Energy Technology Reference Indicator (ETRI) projections for 2010-2050", 2014, ISBN 978-92-79-44403-6.
2) Resource for the storage costs : FCH JU (fuel cell and hydrogen joint undertaking) and 32 companies and McKinsey & Company;
"commercialization of energy storage in europe", March 2015.
$offtext
parameter capex(tec) 'annualized power capex cost in M€/GW/year'
/
$ondelim
$include  inputs/annuities.csv
$offdelim
/ ;
parameter capex_en(str) 'annualized energy capex cost of storage technologies in M€/GWh/year'
/
$ondelim
$include  inputs/str_annuities.csv
$offdelim
/ ;
parameter fOM(tec) 'annualized fixed operation and maintenance costs M€/GW/year'
/
$ondelim
$include  inputs/fO&M.csv
$offdelim
/ ;
Parameter vOM(tec) 'Variable operation and maintenance costs in M€/GWh'
/
$ondelim
$include  inputs/vO&M.csv
$offdelim
/ ;
$Onlisting
parameter eta_in(str) 'charging efifciency of storage technologies' /PHS 0.95, battery 0.9, hydrogen 0.85, methanation 0.75/;
parameter eta_out(str) 'discharging efficiency of storage technolgoies' /PHS 0.9, battery 0.95, hydrogen 0.5, methanation 0.43/;
scalar pump_capa 'pumping capacity in GW' /9.3/;
scalar max_phs 'maximum volume of energy can be stored in PHS reservoir in TWh' /0.18/;
scalar max_hydrogene 'maximum energy that can be stored in the form of hydrogene in TWh' /5/;
scalar max_biogas 'maxium energy can be generated by biogas in TWh' /15/;
scalar load_uncertainty 'uncertainty coefficient for hourly demand' /0.01/;
scalar delta 'load variation factor'     /0.1/;
*-------------------------------------------------------------------------------
*                                Model
*-------------------------------------------------------------------------------
variables        GENE(tec,h)     'hourly energy generation in TWh'
                 CAPA(tec)       'overal yearly installed capacity in GW'
                 STORAGE(str,h)  'hourly electricity input of battery storage GW'
                 STORED(str,h)   'energy stored in each storage technology in GWh'
                 CAPACITY(str)     'energy volume of storage technologies in GWh'
                 RSV(frr,h)      'required upward frequency restoration reserve in GW'
                 COST            'final investment cost in b€'
positive variables GENE(tec,h),CAPA(tec),STORAGE(str,h),STORED(str,h),CAPACITY(str),RSV(frr,h) ;
equations        gene_vre        'variables renewable profiles generation'
                 gene_capa       'capacity and genration relation for technologies'
                 capa_frr        'capacity needed for the secondary reserve requirements'
                 storing         'the definition of stored energy in the storage options'
                 storage_const   'storage in the first hour is equal to the storage in the last hour'
                 lake_res        'constraint on water for lake reservoirs'
                 stored_cap      'maximum energy that is stored in storage units'
                 biogas_const    'maximum energy can be produced by biogas'
                 reserves        'FRR requirement'
                 adequacy        'supply/demand relation'
                 obj             'the final objective function which is COST';
gene_vre(vre,h)..                GENE(vre,h)             =e=     CAPA(vre)*load_factor(vre,h);
gene_capa(tec,h)..               CAPA(tec)               =g=     GENE(tec,h);
capa_frr(frr,h)..                CAPA(frr)               =g=     GENE(frr,h) + RSV(frr,h);
storing(h,h+1,str)..             STORED(str,h+1)         =e=     STORED(str,h) + STORAGE(str,h)*eta_in(str) - GENE(str,h)/eta_out(str);
storage_const(str,first,last)..  STORED(str,first)       =e=     STORED(str,last);
lake_res(m)..                    lake_inflows(m)         =g=     sum(h$(month(h) = ord(m)),GENE('lake',h));
stored_cap(str,h)..              STORED(str,h)           =l=     CAPACITY(str);
biogas_const..                   sum(h,GENE('biogas',h)) =l=     max_biogas*1000;
reserves(h)..                    sum(frr, RSV(frr,h))    =e=     sum(vre,epsilon(vre)*CAPA(vre))+ demand(h)*load_uncertainty*(1+delta);
adequacy(h)..                    sum(tec,GENE(tec,h))    =g=     demand(h) + sum(str,STORAGE(str,h));
obj..                            COST                    =e=     (sum(tec,(CAPA(tec)-capa_ex(tec))*capex(tec))+ sum(str,CAPACITY(str)*capex_en(str))+sum(tec,(CAPA(tec)*fOM(tec))) +sum((tec,h),GENE(tec,h)*vOM(tec)))/1000;
*-------------------------------------------------------------------------------
*                                Initial and fixed values
*-------------------------------------------------------------------------------
CAPA.lo(tec) = capa_ex(tec);
CAPA.fx('phs') = pump_capa;
CAPA.fx('river')= capa_ex('river');
CAPA.fx('lake') = 13;
STORAGE.up('phs',h) = pump_capa;
CAPACITY.fx('phs') = max_phs*1000;
CAPACITY.up('hydrogen') = max_hydrogene*1000;
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
sumgene = sum((gen,h),GENE.l(gen,h))/1000;
display sumdemand; display sumgene;
parameter battery_storage 'battery energy storage per year in TWh';
battery_storage = sum (h,GENE.l('battery',h))/1000;
display battery_storage;
parameter sumgene_river  'yearly hydro-river energy generation in TWh';
sumgene_river = sum(h,GENE.l('river',h))/1000;
parameter sumgene_lake  'yearly hydro-lake energy generation in TWh';
sumgene_lake = sum(h,GENE.l('lake',h))/1000;
parameter sumgene_PHS  'pumped hydro storage per year in TWh';
sumgene_PHS = sum(h,GENE.l('phs',h))/1000;
parameter sumgene_offshore  'yearly offshore energy generation in TWh';
sumgene_offshore = sum(h,GENE.l('offshore',h))/1000;
parameter sumgene_onshore  'yearly onshore energy generation in TWh';
sumgene_onshore = sum(h,GENE.l('onshore',h))/1000;
parameter sumgene_PV  'yearly PV energy generation in TWh';
sumgene_PV = sum(h,GENE.l('pv',h))/1000;
parameter sumgene_biogas 'yearly biogas generation in TWh';
sumgene_biogas = sum(h,GENE.l('biogas',h))/1000;
parameter sumgene_H2 'yearly H2 storage in TWh';
sumgene_H2 = sum(h,GENE.l('hydrogen',h))/1000;
parameter sumgene_CH4 'yearly CH4 storage in TWh';
sumgene_CH4 = sum(h,GENE.l('methanation',h))/1000;
display sumgene_river;
display sumgene_lake;
display sumgene_PHS;
display sumgene_offshore;
display sumgene_onshore;
display sumgene_PV;
display sumgene_biogas;
display sumgene_H2;
display sumgene_CH4;
display RSV.l;
parameter sum_FRR 'the whole yearly energy budgeted for reserves in TWh';
sum_FRR = sum((h,frr),RSV.l(frr,h))/1000;
display sum_FRR;
parameter reserve_lake 'yearly energy spent from the lake power plants for the reserve requirements in TWh';
reserve_lake = sum(h,RSV.l('lake',h))/1000;
display reserve_lake;
parameter reserve_battery 'yearly energy spent from the stored electricity in battery for the reserve requirements in TWh';
reserve_battery = sum(h,RSV.l('battery',h))/1000;
display reserve_battery;
parameter reserve_PHS 'yearly energy spent from the energy stored in PHS stations for the reserve requirements in TWh';
reserve_PHS = sum(h,RSV.l('phs',h))/1000;
display reserve_PHS;
parameter reserve_biogas 'yearly energy spent from the biogas power plants for the reserve requirements in TWh';
reserve_biogas = sum(h,RSV.l('biogas',h))/1000;
display reserve_biogas;
parameter reserve_methanation 'yearly energy spent from the methanation for the reserve requirements in TWh';
reserve_methanation = sum(h,RSV.l('methanation',h))/1000;
display reserve_methanation;
Parameter lcoe(gen);
lcoe(gen) = ((CAPA.l(gen)*(fOM(gen)+capex(gen)))+(sum(h,GENE.l(gen,h))*vOM(gen)))/sum(h,GENE.l(gen,h))*1000;
display lcoe;
parameter lcos(str);
lcos(str) = ((CAPA.l(str)*(fOM(str)+capex(str)))+(sum(h,GENE.l(str,h))*vOM(str))+CAPACITY.l(str)*capex_en(str))/sum(h,GENE.l(str,h))*1000;
display lcos;
display CAPACITY.l;
parameter lf(gen) 'load factor of generation technologies';
lf(gen) = sum(h,GENE.l(gen,h))/(8784*CAPA.l(gen));
display lf;
*-------------------------------------------------------------------------------
*                                Output
*-------------------------------------------------------------------------------
$Ontext
two main output files;
The .txt file just to have a summary and general idea of the key numbers
The .csv file to have a fine output with hourly data for final data processing and analysis
$Offtext

file results /results4.txt/ ;
*the .txt file
put results;
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
'biogas          'CAPA.l('biogas')' GW'//
//
//
'III)Needed storage volume' //
'Battery Storage         'battery_storage'       TWh' //
'PHS Storage             'sumgene_PHS'       TWh'//
'hydrogen storage        'sumgene_h2' TWh'//
'methane storage         'sumgene_ch4'   TWh'//
//
'IV)Secondary reserve requirements'//
'lake                    'smax(h,RSV.l('lake',h)) 'GW'//
'biogass                 'smax(h,RSV.l('biogas',h))  'GW'//
'Pumped Storage          'smax(h,RSV.l('PHS',h)) 'GW'//
'Battery                 'smax(h,RSV.l('battery',h)) 'GW'//
'methanation             'smax(h,RSV.l('methanation',h)) 'GW'//
//

;
file results4 /results41.csv / ;
*the .csv file
parameter nSTORAGE(str,h);
nSTORAGE(str,h) = 0 - STORAGE.l(str,h);
put results4;
results4.pc=5;
put 'hour'; put 'Offshore';  put 'Onshore'; put 'PV'; put 'lake' ; put 'river' ; put 'biogas' ; put 'PHS' ; put 'battery'; put 'hydrogen'; put 'methane' ; put 'demand' ;put 'Electrical Storage' ;put 'Pumped Storage' ; put 'H2 storage' ; put 'CH4 storage'/ ;
loop (h,
put h.tl; put gene.l('offshore',h); put gene.l('onshore',h); put gene.l('PV',h); put GENE.l('lake',h);put GENE.l('river',h); put GENE.l('biogas',h); put GENE.l('PHS',h); put GENE.l('battery',h); put GENE.l('hydrogen',h) ; put GENE.l('methanation',h) ; put demand(h); put nSTORAGE('PHS',h) ; put nSTORAGE('battery',h) ; put nSTORAGE('hydrogen',h) ; put nSTORAGE('methanation',h)/
;);

$onecho > sedscript
s/\,/\;/g
$offecho
$call sed -f sedscript results41.csv > results42.csv

$onecho > sedscript
s/\./\,/g
$offecho
$call sed -f sedscript results42.csv > results.csv
*-------------------------------------------------------------------------------
*                                The End :D
*-------------------------------------------------------------------------------
