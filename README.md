#EOLES_RE

French power sector financial modelling for only renewable energies as supply technologies (Offshore and Onshore wind, PV, Hydro and biogas) and Li-Ion Battery, PHS (pumped hydro storage) and methanation as storage technologies, including reserve requirements, optimization by hourly time slices over one year and 18 years.

Offshore and onshore wind power, Solar power and biogas capacities as well as battery and power-to-gas (methanation) storage capacities are chosen endogenousely, while hydroelectricity lake and run-of-river and Phumped hydro storage capacities are chosen exogenousely. All hourly power production profiles are also modelled endogenously for optimization of dispatch. 

Existing capacities by December 2018 are also entered as lower bound of each hydroelectricity technology capacity, and capital related costs for existing hydroelectricity capacities has been considered zero.

Linear optimisation by CPLEX on GAMS using one-hour time step with respect to Investment Cost.

