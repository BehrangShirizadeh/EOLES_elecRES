*-------------------------------------------------------------------------------
*                                Defining the sets
*-------------------------------------------------------------------------------
sets     h               'all hours'             /0*8783/
         hh              'experimental period'   /0*100/
         first(h)        'the first hour'
         last(h)         'the last hour'
         tec             'technology'            /offshore, onshore, PV, battery/
         vre(tec)        'variable tecs'         /offshore, onshore, PV/;
first(h) =  yes$(ord(h) eq 1);
last(h)  =  yes$(ord(h) eq card(h));
*-------------------------------------------------------------------------------
*                                Inputs
*-------------------------------------------------------------------------------
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
$Onlisting
parameter CAPEX(tec) 'annualized capex cost in M€/GW/year' /offshore 92.82,onshore 55.44,PV 34.54,battery 14.38/ ;
parameter fOM(tec) 'annualized fixed operation and maintenance costs M€/GW' /offshore 2.78,onshore 1.22,PV 0.86,battery 0.201/ ;
parameter fuel_costs(tec) 'fuel cost in M€/GWh' /offshore 0,onshore 0,PV 0,battery 0.0026/;
Parameter fixed_costs(tec) 'Fixed costs in M€/GW';
fixed_costs(tec) = (CAPEX(tec)+fOM(tec));
Parameter variable_costs(tec) 'Variable costs in M€/GWh';
variable_costs(tec)= fuel_costs(tec);
scalar bat_eff_in 'battery charging efficiency' /0.9/;
scalar bat_eff_out 'battery decharging efficiency' /0.8/;
*-------------------------------------------------------------------------------
*                                Model
*-------------------------------------------------------------------------------
variables        GENE(tec,h)     'energy generation'
                 CAPA(tec)       'capacity'
                 STORED(h)       'stored energy'
                 COST            'final investment cost'
positive variables GENE(tec,h), CAPA(tec), STORED(h);
equations        gene_vre        'variables renewable profiles generation'
                 gene_batt       'capacity and genration relation for battery'
                 batt_storage    'generation of battery should be less than stored energy'
                 conservation    'the balance of the energy stored and battery'
                 adequacy        'supply/demand relation'
                 storage_const   'stored energy in first hour is equal to stored energy in the last hour'
                 obj             'the final objective function which is COST';
gene_vre(vre,h)..                GENE(vre,h)             =e=     CAPA(vre)*load_factor(vre,h);
gene_batt(h)..                   CAPA('battery')         =g=     GENE('battery',h);
batt_storage(tec,h)..            GENE('battery',h)       =l=     bat_eff_out*STORED(h);
storage_const(first,last)..      STORED(first)           =e=     STORED(last);
conservation(h)..                sum(vre, GENE(vre,h))   =g=     GENE('battery',h)/bat_eff_out+(STORED(h+1)-STORED(h))/bat_eff_in+demand(h);
adequacy(h)..                    sum(tec,GENE(tec,h))    =g=     demand(h);
obj..                            COST                    =e=     (sum(tec,CAPA(tec)*fixed_costs(tec)) +sum((tec,h),GENE(tec,h)*variable_costs(tec)))/1000;
*-------------------------------------------------------------------------------
*                                Initial and fixed values
*-------------------------------------------------------------------------------
*capa.up('battery') = 35 ;
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
$If exist flore_p1.gdx execute_loadpoint 'flore_p1';
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
sumgene = sum((vre,h),gene.l(vre,h))/1000;
display sumdemand; display sumgene;
parameter storage 'needed energy storage per year in TWh';
storage = sum (h,gene.l('battery',h))/1000;
display storage;
*-------------------------------------------------------------------------------
*                                Output
*-------------------------------------------------------------------------------
file result /result1.txt/ ;
put result ;
put '                            the main results' //
//
'I)Overall investment cost is' cost.l 'b€' //
//
'II)the Renewable capacity ' //
'PV              'capa.l('PV')'  GW'//
'Offshore        'capa.l('offshore')'    GW'//
'onsore          'capa.l('onshore')'     GW' //
'Battery Storage 'capa.l('battery')'     GW' //
//
'III)Needed storage' //
'Storage         'storage'       GWh' //
//
;
file results /result1.csv / ;
put results;
results.pc=5;
put 'hour'; put 'Offshore';  put 'Onshore'; put 'PV'; put 'battery'; put 'demand'/ ;
loop (h,
put h.tl; put gene.l('offshore',h); put gene.l('onshore',h); put gene.l('PV',h); put gene.l('battery',h); put demand(h)/ ;
;);

$onecho > sedscript
s/\,/\;/g
$offecho
$call sed -f sedscript result1.csv > result12.csv

$onecho > sedscript
s/\./\,/g
$offecho
$call sed -f sedscript result12.csv > result13.csv
*-------------------------------------------------------------------------------
*                                The End :D
*-------------------------------------------------------------------------------
