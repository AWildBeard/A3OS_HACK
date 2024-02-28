/*
 * fn_getFirstRouterWithinCutoffDistance returns the first router within the supplied cutoff distance.
 * This will be the "router" level entry of the HackState global array variable
 */
params ["_computer", "_cutoff_distance"];

private _router = [];
private _found = false;

for [{_router_id = 0}, {_router_id <= ((count HackState) - 1)}, {_router_id = _router_id + 1}] do {
	private _tmp_router = HackState select _router_id;
	private _tmp_router_var_name = _tmp_router select 0;
	scopeName "routerSearch";

	if ((_tmp_router select 1) == "router") then {
		private _router_variable = missionNamespace getVariable [_tmp_router_var_name, objNull]; 
		if (isNull _router_variable) then {continue;};
	
		private _distance = _computer distance _router_variable;
		if (_distance <= _cutoff_distance) then {
			_router = _tmp_router;
			_found = true;
			breakOut "routerSearch";
		};
	};
};

[_router, _found];
