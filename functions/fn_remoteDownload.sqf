/**
 * Administratively downloads a file from a different computer to the local computer. This will bypass remote filesystem permission requirements.
 * Arguments:
 * 0: Remote Computer <OBJECT>
 * 1: Local Filesystem Pointer <[STRING]>
 * 2: Local Filesystem <HASHMAP>
 * 3: Local User <STRING>
 * 4: Remote file path to read from <STRING>
 * 5: Local file path to write to <STRING>
 *
 * Results:
 * None
 * 
 * Most of the credit for this file belongs to @GermanHydrogen on Github. The logic is straight copied from them, I simply changed *which* filesystem
 * the source file is coming from.
 */

params ["_remote_computer", "_local_ptr", "_local_fs", "_local_user", "_remote_file_to_download", "_local_file_to_download"];

private _remote_filesystem = _remote_computer getVariable "AE3_filesystem";
private _remote_pntr = _remote_computer getVariable "AE3_Filepointer";
private _remote_dir = [_remote_pntr, _remote_filesystem, _remote_file_to_download, "root"] call AE3_filesystem_fnc_getParentDir;
private _remote_current = _remote_dir select 1;
private _remote_file = _remote_dir select 2;

private _local_dir = [_local_ptr, _local_fs, _local_file_to_download, _local_user] call AE3_filesystem_fnc_getParentDir;
private _local_current = _local_dir select 1;
private _local_new = _local_dir select 2;

if (_local_new in (_local_current select 0)) then {
	if (((_local_current select 0) get _local_new) select 0 isEqualType (createHashMap)) then {
		_local_file_to_download = _local_file_to_download + "/";
	};
};

_remote_current = _remote_current select 0;
if (!(_remote_file in _remote_current)) throw (format [localize "STR_AE3_Filesystem_Exception_NotFound", _remote_file]);

if ((_local_file_to_download find ["/", count _local_file_to_download - 1]) == (count _local_file_to_download - 1)) then { // Last character in string is a "/"
	_local_current = _local_current select 0;
	if(!(_local_new in _local_current)) throw (format [localize "STR_AE3_Filesystem_Exception_NotFound", _local_new]);
	_local_current = (_local_current get _local_new);

	[_local_current, _local_user, 2] call AE3_filesystem_fnc_hasPermission;
	_local_current = _local_current select 0;

	if(_local_new in _local_current) throw (format [localize "STR_AE3_Filesystem_Exception_AlreadyExists", _local_new]);

	_local_current set [_local_new, _remote_current get _remote_file];
} else {
	[_local_current, _local_user, 2] call AE3_filesystem_fnc_hasPermission;
	_local_current = _local_current select 0;

	if(_local_new in _local_current) throw (format [localize "STR_AE3_Filesystem_Exception_AlreadyExists", _remote_file]);

	_local_current set [_local_new, _remote_current get _remote_file];
};
