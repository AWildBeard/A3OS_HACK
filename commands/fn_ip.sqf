params ["_computer", "_options", "_command_name"];

private _print = {[_computer, _this] call AE3_armaos_fnc_shell_stdout};
private _getRouterIpAddr = {_this select 2};
private _getClientIpAddr = {_this select 3};
private _getClientBrdAddr = {_this select 4};

([_computer, DistanceMin] call A3OSHACK_fnc_getFirstRouterWithinCutoffDistance) params ["_router", "_connected"];

private _command_syntax = 
[
	[
		["command", _command_name, true, false],
		["path", "a[ddr]", true, false]
	],
	[
		["command", _command_name, true, false],
		["path", "r[oute]", true, false]
	]
];

[] params ([_computer, _options, [_command_name, [], _command_syntax]] call AE3_armaos_fnc_shell_getOpts);
if !(_ae3OptsSuccess) exitWith {};

_ae3OptsThings params ["_first"];

if (_first == "a" or _first == "addr") then {
	"1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000" call _print;
	"	link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00" call _print;
	"	inet 127.0.0.1/8 scope host lo" call _print;
	"		valid_lft forever preferred_lft forever" call _print;
	"	inet6 ::1/128 scope host" call _print;
	"		valid_lft forever preferred_lft forever" call _print;

	if (_connected) then {
		"2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_code1 state UP group default qlen 1000" call _print;
		"	link/ether 02:73:7b:8d:5d:6a brd ff:ff:ff:ff:ff:ff" call _print;
		format ["	inet %1/24 metric 100 brd %2 scope global dynamic eth0", (_router call _getClientIpAddr), (_router call _getClientBrdAddr)] call _print;
		"		valid_lft forever preferred_lft forever" call _print;
	};
};

if (_first == "r" or _first == "route") then {
	if (_connected) then {
		format ["default via %1 dev eth0", (_router call _getRouterIpAddr)] call _print;
	}
};
