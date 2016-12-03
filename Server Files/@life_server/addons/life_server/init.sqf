#define __CONST__(var1,var2) var1 = compileFinal (if(typeName var2 == "STRING") then {var2} else {str(var2)})

life_server_isReady = false;
publicVariable "life_server_isReady";

[] execFSM "\life_server\cleanup.fsm";
[] execVM "\life_server\functions.sqf";
[] execVM "\life_server\eventhandlers.sqf";

// DATABASE INIT
if(isNil {uiNamespace getVariable "life_sql_id"}) then {
	life_sql_id = round(random(999999));
	__CONST__(life_sql_id,life_sql_id);
	uiNamespace setVariable ["life_sql_id",life_sql_id];
	_version = "extDB2" callExtension "9:VERSION";
	if(_version isEqualTo "") exitWith {diag_log text "EXTDB ERROR:: DLL FILE NOT FOUND ! CHECK THE INSTALLATION !"};
	if((parseNumber _version) < 64) exitWith {diag_log text format["EXTDB ERROR:: ALTIS-LIFE NEED VERSION 64 OR HIGHER ! CURRENT VERSION: %1",_version]};
	"extDB2" callExtension "9:ADD_DATABASE:LIFE";
	"extDB2" callExtension format ["9:ADD_DATABASE_PROTOCOL:LIFE:SQL_RAW_v2:%1:ADD_QUOTES",(call life_sql_id)];
	"extDB2" callExtension "9:LOCK";
	_lockStatus = "extDB2" callExtension "9:LOCK_STATUS";
	if(_lockStatus isEqualTo "[1]") then {
		diag_log text "EXTDB:: LOCK SUCCESSFULL";
	} else {
		diag_log text "EXTDB:: LOCK FAILED";
	};
} else {
	life_sql_id = uiNamespace getVariable "life_sql_id";
	__CONST__(life_sql_id,life_sql_id);
};

["CALL resetLifeVehicles",1] call DB_fnc_asyncCall;
["CALL deleteDeadVehicles",1] call DB_fnc_asyncCall;
["CALL deleteOldGangs",1] call DB_fnc_asyncCall;
["CALL deleteOldMessages",1] call DB_fnc_asyncCall;
["CALL deleteOldHouses",1] call DB_fnc_asyncCall;

life_adminlevel = 0;
life_medicLevel = 0;
life_coplevel = 0;

__CONST__(JxMxE_PublishVehicle,"No");

life_radio_west = radioChannelCreate [[0, 0.95, 1, 0.8], "Side Channel", "%UNIT_NAME", []];
life_radio_indep = radioChannelCreate [[0, 0.95, 1, 0.8], "Side Channel", "%UNIT_NAME", []];
life_radio_civ = radioChannelCreate [[0, 0.95, 1, 0.8], "Side Channel", "%UNIT_NAME", []];

serv_sv_use = [];

fed_bank setVariable["safe",(count allPlayers),true];

addMissionEventHandler ["HandleDisconnect",{_this call TON_fnc_clientDisconnect;false}];

[] spawn TON_fnc_cleanup;
life_gang_list = [];
publicVariable "life_gang_list";
life_wanted_list = [];
client_session_list = [];

[] spawn
{
	private["_logic","_queue"];
	while {true} do
	{
		uiSleep (30 * 60);
		_logic = missionnamespace getvariable ["bis_functions_mainscope",objnull];
		_queue = _logic getvariable "BIS_fnc_MP_queue";
		_logic setVariable["BIS_fnc_MP_queue",[],TRUE];
	};
};

[] spawn TON_fnc_federalUpdate;

[] spawn
{
	while {true} do
	{
		uiSleep (30 * 60);
		{
			_x setVariable["sellers",[],true];
		} foreach [Dealer_1,Dealer_2,Dealer_3];
	};
};

{
	if(!isPlayer _x) then {
		_npc = _x;
		{
			if(_x != "") then {
				_npc removeWeapon _x;
			};
		} foreach [primaryWeapon _npc,secondaryWeapon _npc,handgunWeapon _npc];
	};
} foreach allUnits;

[] spawn TON_fnc_initHouses;

private["_dome","_rsb"];
_dome = nearestObject [[16019.5,16952.9,0],"Land_Dome_Big_F"];
_rsb = nearestObject [[16019.5,16952.9,0],"Land_Research_house_V1_F"];

for "_i" from 1 to 3 do {_dome setVariable[format["bis_disabled_Door_%1",_i],1,true]; _dome animate [format["Door_%1_rot",_i],0];};
_rsb setVariable["bis_disabled_Door_1",1,true];
_rsb allowDamage false;
_dome allowDamage false;
life_server_isReady = true;
publicVariable "life_server_isReady";
