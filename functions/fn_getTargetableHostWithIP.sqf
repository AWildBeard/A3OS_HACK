/**
 * Takes a _router and returns the targetable host with _ip
 * 
 * Arguments:
 * 0: Router to search through <OBJECT>
 * 1: IP to search for <STRING>
 *
 * Results:
 * 0: The targetable host <ARRAY>
 * 1: OK <BOOL>
 *
 */

params ["_router", "_ip"];

private _targetable_hosts = (_router select 6);
private _host_to_return = [];
private _ok = false;
for "_targetable_host_count" from 0 to (count _targetable_hosts)-1 do {
	private _targetable_host = (_targetable_hosts select _targetable_host_count);
	// offset 0, defined via spec.
	if (_ip == (_targetable_host select 0)) then {
		_host_to_return = _targetable_host;
		_ok = true;
		break;
	};
};

[_host_to_return, _ok];
