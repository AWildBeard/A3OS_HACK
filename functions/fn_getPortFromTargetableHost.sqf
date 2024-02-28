/**
 * Takes a _targetable_host and a _port to return the actual port specification on a _targetable_host
 * 
 * Arguments:
 * 0: Targetable host to search through <ARRAY>
 * 1: Port to search for <STRING>
 *
 * Results:
 * 0: The targetable port <ARRAY>
 * 1: OK <BOOL>
 */

params ["_targetable_host", "_port"];

private _targetable_host_ports = _targetable_host select 2;
private _port_to_return = [];
private _ok = false;
for "_targetable_host_port_count" from 0 to (count _targetable_host_ports)-1 do {
	private _targetable_host_port = (_targetable_host_ports select _targetable_host_port_count);
	if (_port == (_targetable_host_port select 0)) then {
		_port_to_return = _targetable_host_port;
		_ok = true;
		break;
	};
};

[_port_to_return, _ok];
