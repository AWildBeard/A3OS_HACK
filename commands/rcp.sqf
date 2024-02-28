params ["_computer", "_options", "_command_name"];

print = {[_computer, _this] call AE3_armaos_fnc_shell_stdout};

private _command_opts = [
	["_remote_computer_var_name", "c", "computer", "string", "", true, "Eden variable name for computer to copy files from"]
];
private _command_syntax = [
	[
		["command", _command_name, true, false],
		["options", "OPTIONS", true, false],
		["path", "{remote path}", true, false],
		["path", "{local path}", true, false]
	]
];

[] params ([_computer, _options, [_command_name, _command_opts, _command_syntax]] call AE3_armaos_fnc_shell_getOpts);
if !(_ae3OptsSuccess) exitWith {};

_ae3OptsThings params ["_remote_path", "_local_path"];

scopeName "main";

_remote_computer = missionNamespace getVariable [_remote_computer_var_name, objNull];
if (isNull _remote_computer) then {
	["Critical failure accessing remote device", "#e53109"] call print;
	breakOut "main";
};

private _terminal = _computer getVariable "AE3_terminal";
private _user = _terminal get "AE3_terminalLoginUser";
private _filesystem = _computer getVariable "AE3_filesystem";
private _ptr = _computer getVariable "AE3_Filepointer";

try {
	[_remote_computer, _ptr, _filesystem, _user, _remote_path, _local_path] call A3OSHACK_fnc_remoteCopy;
	_computer setVariable ["AE3_filesystem", _filesystem, 2];
} catch {
	[_exception] call print;
};

