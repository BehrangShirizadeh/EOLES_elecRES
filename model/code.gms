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
sets     h               'hours'                         /0*8783/
         first(h)        'first hour'
         last(h)         'last hour'
         m               'month'                         /jan, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dec/
         tec             'technology'                    /offshore, onshore, pv, river, lake, biogas, gas, phs, battery, hydrogen, methanation/
*for the case with DSM add dsm in the set called tec
         gen(tec)        'power plants'                  /offshore, onshore, pv, river, lake, biogas, gas/
         vre(tec)        'variable tecs'                 /offshore, onshore, pv/
         ncomb(tec)      'non-combustible generation'    /offshore, onshore, pv, river, lake, phs, battery/
         comb(tec)       'combustible generation techs'  /biogas, hydrogen, methanation/
         str(tec)        'storage technologies'          /phs, battery, hydrogen, methanation/
         frr(tec)        'technologies for upward FRR'   /lake, gas, phs, battery/
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
$include  inputs/vre_profiles.csv
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
$include  inputs/existing_capas.csv
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
$include  inputs/annuities-n.csv
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
$include  inputs/fO&M-n.csv
$offdelim
/ ;
Parameter vOM(tec) 'Variable operation and maintenance costs in M€/GWh'
/
$ondelim
$include  inputs/vO&M.csv
$offdelim
/ ;
$Onlisting
parameter eta_in(str) 'charging efifciency of storage technologies' /PHS 0.95, battery 0.9, hydrogen 0.85, methanation 0.675/;
parameter eta_out(str) 'discharging efficiency of storage technolgoies' /PHS 0.9, battery 0.95, hydrogen 0.5, methanation 0.43/;
scalar pump_capa 'pumping capacity in GW' /9.3/;
scalar max_phs 'maximum volume of energy can be stored in PHS reservoir in TWh' /0.18/;
scalar max_hydrogene 'maximum energy that can be stored in the form of hydrogene in TWh' /5/;
scalar max_biogas 'maxium energy can be generated by biogas in TWh' /15/;
scalar load_uncertainty 'uncertainty coefficient for hourly demand' /0.01/;
scalar delta 'load variation factor'     /0.1/;
*two following line for the case with DSM
*scalar ls_max 'maximum load that can be shifted during one year' /30/;
*capex('dsm') = 2.2521;
*-------------------------------------------------------------------------------
*                                Model
*-------------------------------------------------------------------------------
variables        GENE(tec,h)     'hourly energy generation in TWh'
                 CAPA(tec)       'overal yearly installed capacity in GW'
                 STORAGE(str,h)  'hourly electricity input of battery storage GW'
                 STORED(str,h)   'energy stored in each storage technology in GWh'
                 CAPACITY(str)   'energy volume of storage technologies in GWh'
                 RSV(frr,h)      'required upward frequency restoration reserve in GW'
*variables DS(h) and DH(h) are load shifting related variables and they should be added to positive variables later in the case with DSM
*                 DH(h)           'demand on hold at hour h'
*                 DS(h)           'demand that is served in hour h'
                 COST            'final investment cost in b€'
positive variables GENE(tec,h),CAPA(tec),STORAGE(str,h),STORED(str,h),CAPACITY(str),RSV(frr,h);
equations        gene_vre        'variables renewable profiles generation'
                 gene_capa       'capacity and genration relation for technologies'
                 capa_frr        'capacity needed for the secondary reserve requirements'
                 storing         'the definition of stored energy in the storage options'
                 storage_const   'storage in the first hour is equal to the storage in the last hour'
                 combustion      'the relationship of combustible technologies'
                 lim_hydrogen    'the maximum amount of hydrogen can be injected'
                 lake_res        'constraint on water for lake reservoirs'
                 stored_cap      'maximum energy that is stored in storage units'
                 biogas_const    'maximum energy can be produced by biogas'
                 reserves        'FRR requirement'
*the four following equations are load shifting related equations and should be added to the model in the case with DSM
*                 load_shifting   'the equation for load shifting considering DSM as a tech'
*                 capa_ls         'the capacity of load shifting'
*                 capa_ls2        'the capacity of load shifting'
*                 dsm_max         'yearly maximum dsm usage'
                 adequacy        'supply/demand relation'
                 obj             'the final objective function which is COST';
gene_vre(vre,h)..                GENE(vre,h)             =e=     CAPA(vre)*load_factor(vre,h);
gene_capa(tec,h)..               CAPA(tec)               =g=     GENE(tec,h);
capa_frr(frr,h)..                CAPA(frr)               =g=     GENE(frr,h) + RSV(frr,h);
storing(h,h+1,str)..             STORED(str,h+1)         =e=     STORED(str,h) + STORAGE(str,h+1)*eta_in(str) - GENE(str,h+1)/eta_out(str);
storage_const(str,first,last)..  STORED(str,first)       =e=     STORED(str,last);
combustion(h)..                  GENE('gas',h)           =e=     sum(comb,GENE(comb,h));
lim_hydrogen(h)..                GENE('hydrogen',h)      =l=     GENE('gas',h)/32;
lake_res(m)..                    lake_inflows(m)         =g=     sum(h$(month(h) = ord(m)),GENE('lake',h));
stored_cap(str,h)..              STORED(str,h)           =l=     CAPACITY(str);
biogas_const..                   sum(h,GENE('biogas',h)) =l=     max_biogas*1000;
reserves(h)..                    sum(frr, RSV(frr,h))    =e=     sum(vre,epsilon(vre)*CAPA(vre))+ demand(h)*load_uncertainty*(1+delta);
*load_shifting(h,h-1)..           DH(h)                   =e=     DH(h-1)+GENE('dsm',h)-DS(h);
*capa_ls(h)..                     DH(h)                   =l=     sum(hh$(ord(hh)>=ord(h)-5 and ord(hh)<=ord(h)),GENE('dsm',hh));
*capa_ls2(h)..                    DH(h)                   =l=     sum(hh$(ord(hh)>=ord(h)+1 and ord(hh)<=ord(h)+6),DS(hh));
*dsm_max..                        sum(h,GENE('dsm',h))    =l=     ls_max*1000;
adequacy(h)..                    sum(tec,GENE(tec,h))    =g=     demand(h) + sum(str,STORAGE(str,h)) + DS(h) ;
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
*DS.up(h) = 12.15;
*CAPA.up('dsm') = 12.15;
*GENE.fx('dsm','0') = 0;
*-------------------------------------------------------------------------------
*                                Model options
*-------------------------------------------------------------------------------
model RES_F /all/;
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
$If exist RES_F.gdx execute_loadpoint 'RES_F';
Solve RES_F using lp minimizing COST;
*-------------------------------------------------------------------------------
*                                Display statement
*-------------------------------------------------------------------------------
display cost.l;
display capa.l;
display gene.l;
parameter gene_tec(tec) 'yearly generated power by each technology in TWh';
gene_tec(tec) = sum(h,GENE.l(tec,h))/1000;
parameter sumgene        'the whole generation per year in TWh';
sumgene = sum((gen,h),GENE.l(gen,h))/1000-gene_tec('gas');
display sumgene;
display gene_tec;
parameter reserve(frr) 'yearly energy spent from reserve technologies in TWh';
reserve(frr) = sum(h,RSV.l(frr,h))/1000;
display reserve;
Parameter lcoe(gen);
lcoe(gen) = ((CAPA.l(gen)*(fOM(gen)+capex(gen)))+(sum(h,GENE.l(gen,h))*vOM(gen)))/sum(h,GENE.l(gen,h))*1000;
display lcoe;
parameter lcos(str);
lcos(str) = ((CAPA.l(str)*(fOM(str)+capex(str)))+(sum(h,GENE.l(str,h))*vOM(str))+CAPACITY.l(str)*capex_en(str))/sum(h,GENE.l(str,h))*1000;
display lcos;
display CAPACITY.l;
parameter cf(gen) 'load factor of generation technologies';
cf(gen) = sum(h,GENE.l(gen,h))/(8784*CAPA.l(gen));
display cf;
parameter lc 'load curtailment of the network';
lc = (sumgene - 480.3)/sumgene;
display lc;
*-------------------------------------------------------------------------------
*                                Output
*-------------------------------------------------------------------------------
$Ontext
two main output files;
The .txt file just to have a summary and general idea of the key numbers
The .csv file to have a fine output with hourly data for final data processing and analysis
$Offtext

file results /results5.txt/ ;
*the .txt file
put results;
put '                            the main results' //
//
'I)Overall investment cost is' cost.l 'b€' //
//
'II)the Renewable capacity ' //
'PV              'capa.l('PV')'  GW'//
'Offshore        'capa.l('offshore')'    GW'//
'Onsore          'capa.l('onshore')'     GW' //
'run of river    'CAPA.l('river') 'GW' //
'lake            'CAPA.l('lake') 'GW' //
'biogas          'CAPA.l('biogas')' GW'//
'gas             'CAPA.l('gas')'  GW'//
'battery         'CAPA.l('battery')' GW'//
'phs             'CAPA.l('biogas')'  GW'//
'Hydrogen        'CAPA.l('hydrogen')' GW'//
'Methanation     'CAPA.l('methanation')'GW'//
*'DSM             'CAPA.l('dsm')' GW'//
//
'III)Needed storage volume' //
'Battery Storage         'Capacity.l('battery')'       TWh' //
'PHS Storage             'Capacity.l('phs')'       TWh'//
'hydrogen storage        'Capacity.l('hydrogen')' TWh'//
'methane storage         'Capacity.l('methanation')'   TWh'//
//
'IV)Secondary reserve requirements'//
'lake                    'smax(h,RSV.l('lake',h)) 'GW'//
'gas                     'smax(h,RSV.l('gas',h))  'GW'//
'Pumped Storage          'smax(h,RSV.l('PHS',h)) 'GW'//
'Battery                 'smax(h,RSV.l('battery',h)) 'GW'//
//
'V)Overall yearly energy generation of each technology'//
'PV              'gene_tec('PV')'  TWh'//
'Offshore        'gene_tec('offshore')'    TWh'//
'onsore          'gene_tec('onshore')'     TWh' //
'run of river    'gene_tec('river') 'TWh' //
'lake            'gene_tec('lake') 'TWh' //
'biogas          'gene_tec('biogas')' TWh'//
'gas             'gene_tec('gas')'  TWh'//
'battery         'gene_tec('battery')' TWh'//
'phs             'gene_tec('biogas')'  TWh'//
'Hydrogen        'gene_tec('hydrogen')' TWh'//
'Methanation     'gene_tec('methanation')'TWh'//
*'DSM             'gene_tec('dsm')' TWh'//
//
'VI)more details'//
'LCOE for Offshore' lcoe('offshore')' €/MWh'//
'LCOE for Onshore' lcoe('onshore')' €/MWh'//
'LCOE for PV' lcoe('pv')' €/MWh'//
'LCOE for Run-of-river' lcoe('river')' €/MWh'//
'LCOE for Lake' lcoe('lake')' €/MWh'//
'LCOE for Biogas' lcoe('biogas')' €/MWh'//
'LCOE for Gas'   lcoe('gas')' €/MWh'//
'LCOS for battery' lcos('battery')' €/MWh'//
'LCOS for pumped storage' lcos('phs')' €/MWh'//
'LCOS for hydrogen' lcos('hydrogen')' €/MWh'//
'LCOS for methanation' lcos('methanation')' €/MWh'//
//
'Load Curtailment' lc//
;

;

file results1 /results51.csv / ;
*the .csv file
parameter nSTORAGE(str,h);
nSTORAGE(str,h) = 0 - STORAGE.l(str,h);
*parameter nDSM(h);
*nDSM(h) = 0 - DS.l(h);
put results1;
results1.pc=5;
put 'hour'; loop(tec, put tec.tl;); put 'demand' ;put 'ElecStr' ;put 'Pump' ; put 'H2' ; put 'CH4'/ ;
loop (h,
put h.tl; loop(tec, put gene.l(tec,h);) ;put demand(h); put nSTORAGE('PHS',h) ; put nSTORAGE('battery',h) ; put nSTORAGE('hydrogen',h) ; put nSTORAGE('methanation',h)/
;);
*for the case with DSM use the next four lines instead of previous four lines
*put 'hour'; loop(tec, put tec.tl;) ; put 'demand' ;put 'ElecStr' ;put 'Pump' ; put 'H2' ; put 'CH4' ; put 'LS' / ;
*loop (h,
*put h.tl; loop(tec, put gene.l(tec,h);); put demand2(h); put nSTORAGE('battery',h) ; put nSTORAGE('phs',h) ; put nSTORAGE('hydrogen',h) ; put nSTORAGE('methanation',h); put nDSM(h)/
*;);

$onecho > sedscript
s/\,/\;/g
$offecho
$call sed -f sedscript results51.csv > results52.csv

$onecho > sedscript
s/\./\,/g
$offecho
$call sed -f sedscript results52.csv > results5.csv


*-------------------------------------------------------------------------------
*                                The End :D
*-------------------------------------------------------------------------------
