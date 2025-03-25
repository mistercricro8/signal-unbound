extends Node

const INTRO = [
	[1, TerminalController.Chars.NONE, "(Press 'ctrl+c' to cancel any ongoing dialogue in this terminal)"],
	[2, TerminalController.Chars.OP, "...Quite an unusual mission today, I know we don't usually do cleanups but the pay was good."],
	[5, TerminalController.Chars.OP, "We can't do a lot within zones 1-2 other than using those turrets (cyan circles)."],
	[5, TerminalController.Chars.DRONE, "I'm not being used as bait again, 'team'."],
	[3, TerminalController.Chars.OP, "Don't worry, according to the log, we should find a 'prototype weapon' by the end of zone 2."],
	[5, TerminalController.Chars.DRONE, "Now I'm interested, tell me more."],
	[3, TerminalController.Chars.OP, "That's all I received, we will mount it on you and you'll get to be THE weapon, isn't that fancy?"],
	[5, TerminalController.Chars.DRONE, "That's much more like it."],
	[3, TerminalController.Chars.OP, "From there we should get to zone 5 for some upgrades and then we can clean up the rest."],
	[5, TerminalController.Chars.DRONE, "Understood!"],
	[2.5, TerminalController.Chars.OP, "Intern, remember your training? You'll guide Josh (white dot) through the mothership."],
	[5, TerminalController.Chars.OP, "Send your commands by typing them in the terminal to the right."],
	[5, TerminalController.Chars.OP, "In case you need a reminder, press enter and write 'help' for some basic guidelines, 'list' for a list of all available commands and 'dest' to know the access to the next zone."],
	[9, TerminalController.Chars.DRONE, "I can imagine your expression, don't be boring now, we all love reading here!"],
	[5, TerminalController.Chars.OP, "As he said, take your time, and make sure you understand all the commands and all the resources you have."],
	[6, TerminalController.Chars.OP, "Good luck, team."],
	[2, TerminalController.Chars.DRONE, "Whenever you're ready, intern."]
]

const SCANNER = [
	[1, TerminalController.Chars.DRONE, "It seems like there is a scanner here, mounting it!"],
	[3, TerminalController.Chars.OP, "That seems good, and it comes with a manual, too!"],
	[3, TerminalController.Chars.DRONE, "Better start getting used to it (write 'man scan' to read the manual)."]
]

const CREATURES_LOG = [
	[1, TerminalController.Chars.DRONE, "And a very conveniently placed log of the creatures here as well!"],
	[3, TerminalController.Chars.OP, "Give me a second, I'll register them for you."],
	[3, TerminalController.Chars.DRONE, "You thought we were done? (write 'creatures' to see the log)."]
]

const WEAPON = [
	[1, TerminalController.Chars.DRONE, "Just as promised, the weapon prototype!"],
	[3, TerminalController.Chars.OP, "Mount that thing on you before something jumps in your face."],
	[3, TerminalController.Chars.DRONE, "Yes sir! I am now 'THE weapon'!"],
	[3, TerminalController.Chars.DRONE, "And from the looks of it, I can make use of it myself, just get me close to them, intern."]
]

const ENDING_START = [
	[0, TerminalController.Chars.OP, "Josh!? Is everything okay?"],
	[1.5, TerminalController.Chars.DRONE, "Mission 0% complete."]
]

const ENDING_DIALOGUES = [
	[[0, TerminalController.Chars.OP, "Josh, can you hear me?"]],
	[[0, TerminalController.Chars.OP, "Josh, PLEASE"]],
	[[0, TerminalController.Chars.OP, "Let me try something out..."]],
	[[0, TerminalController.Chars.OP, "...Things are not looking good."]],
	[[0, TerminalController.Chars.OP, "I HAD to take this mission right?"]],
	[[0, TerminalController.Chars.OP, "Don't worry, we'll get you out of there."]],
	[[0, TerminalController.Chars.OP, "Josh, you are NOT that weapon."]],
	[[0, TerminalController.Chars.OP, "I've requested an extraction, hold on."]],
	[[0, TerminalController.Chars.OP, "It was meant to be a simple mission."]],
	[[0, TerminalController.Chars.OP, "But we HAD to make Josh THE WEAPON, right?"]],
	[[0, TerminalController.Chars.OP, "Intern, we are sorry for this."]],
	[[0, TerminalController.Chars.OP, "Extraction will not get in time."]],
	[[0, TerminalController.Chars.OP, "Hide with whatever you can."]],
	[[0, TerminalController.Chars.OP, "We are sorry."]],
	[[0, TerminalController.Chars.NONE, "Lost connection with mission."]]
]

var ENDING_DIALOGUES_SENT = [
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false
]

var TERMINAL_RESPONSES = {
	"buro": [
		[TerminalController.MessageTypes.ERROR, "We have a buro in this room, leave quickly!"],
		[TerminalController.MessageTypes.ERROR, "Buro compound detected."]
	],
	"invalid_code": [
		[TerminalController.MessageTypes.ERROR, "That doesn't seem like a valid %s code, intern!"],
		[TerminalController.MessageTypes.ERROR, "Invalid %s code."]
	],
	"movement": [
		[TerminalController.MessageTypes.SUCCESS, "%s the movement to the %s %s!"],
		[TerminalController.MessageTypes.SUCCESS, "%s movement to %s %s."]
	],
	"movement_queue": [
		[TerminalController.MessageTypes.SUCCESS, "Adding movement to the %s %s to queue!"],
		[TerminalController.MessageTypes.SUCCESS, "Movement to %s %s added to queue."]
	],
	"unreachable": [
		[TerminalController.MessageTypes.ERROR, "I don't think we can get there, intern!"],
		[TerminalController.MessageTypes.ERROR, "Target unreachable."]
	],
	"no_turret_conn": [
		[TerminalController.MessageTypes.ERROR, "...Uhh, not currently connecting to any turret."],
		[TerminalController.MessageTypes.ERROR, "No turret connection in progress."]
	],
	"cancelled_turret_conn": [
		[TerminalController.MessageTypes.SUCCESS, "Cancelled the connection to the turret!"],
		[TerminalController.MessageTypes.SUCCESS, "Turret connection cancelled."]
	],
	"turret_conn": [
		[TerminalController.MessageTypes.SUCCESS, "Connecting to the turret in room %s!"],
		[TerminalController.MessageTypes.SUCCESS, "Connecting to turret in room %s."]
	],
	"rebooting": [
		[TerminalController.MessageTypes.WARNING, "Low power, give me a second to reboot..."],
		[TerminalController.MessageTypes.WARNING, "Lost power, rebooting..."]
	],
	"rebooted": [
		[TerminalController.MessageTypes.SUCCESS, "Rebooted successfully!"],
		[TerminalController.MessageTypes.SUCCESS, "Rebooted."]
	],
	"scan": [
		[TerminalController.MessageTypes.SUCCESS, "Looking for any threats in the neighboring rooms!"],
		[TerminalController.MessageTypes.SUCCESS, "Scanning for threats."]
	],
	"door_noresponsive": [
		[TerminalController.MessageTypes.ERROR, "The door %s doesn't seem to be responding!"],
		[TerminalController.MessageTypes.ERROR, "Door %s is not responsive."]
	],
	"door_toggled": [
		[TerminalController.MessageTypes.SUCCESS, "Toggled the door %s %s!"],
		[TerminalController.MessageTypes.SUCCESS, "Door %s %s."]
	],
	"door_damage": [
		[TerminalController.MessageTypes.WARNING, "The door %s %s!", true],
		[TerminalController.MessageTypes.WARNING, "Door %s %s.", true]
	],
	"room_destroyed": [
		[TerminalController.MessageTypes.ERROR, "The room %s has been blown off the mothership!"],
		[TerminalController.MessageTypes.ERROR, "Room %s destroyed."]
	],
	"turret_elim": [
		[TerminalController.MessageTypes.SUCCESS, "Turret in room %s got a clean shot!", true],
		[TerminalController.MessageTypes.SUCCESS, "Turret eliminated threat in room %s.", true]
	],
	"turret_toggle": [
		[TerminalController.MessageTypes.SUCCESS, "Turret in room %s toggled %s!"],
		[TerminalController.MessageTypes.SUCCESS, "Turret in room %s %s."]
	],
	"invalid_door": [
		[TerminalController.MessageTypes.ERROR, "%s doesn't seem to be a valid door, intern!"],
		[TerminalController.MessageTypes.ERROR, "%s is not a valid door."]
	],
	"invalid_room": [
		[TerminalController.MessageTypes.ERROR, "%s doesn't seem to be a valid room, intern!"],
		[TerminalController.MessageTypes.ERROR, "%s is not a valid room."]
	],
	"room_no_turret": [
		[TerminalController.MessageTypes.WARNING, "Room %s doesn't have a turret!"],
		[TerminalController.MessageTypes.WARNING, "Room %s has no turret."]
	],
	"turret_unresponsive": [
		[TerminalController.MessageTypes.ERROR, "The turret in room %s is not responsive!"],
		[TerminalController.MessageTypes.ERROR, "Turret in room %s unresponsive."]
	],
	"access": [
		[TerminalController.MessageTypes.SUCCESS, "Access located at %s!"],
		[TerminalController.MessageTypes.SUCCESS, "%s."]
	],
	"invalid_command": [
		[TerminalController.MessageTypes.ERROR, "I don't understand that command!"],
		[TerminalController.MessageTypes.ERROR, "Invalid command."]
	],
}

var PROGRESS_DIALOGUES = {
	"ZONE_PROGRESS": [
		null,
		null,
		[
			[1, TerminalController.Chars.DRONE, "Access reached, everyone!"],
			[3, TerminalController.Chars.OP, "Indeed!, moving on to the next zone."]
		],
		[
			[1, TerminalController.Chars.DRONE, "I think we're done here."],
			[3, TerminalController.Chars.OP, "Everything fine over there? The connection seems unstable."]
		],
		[
			[1, TerminalController.Chars.DRONE, "Zone cleared."],
			[3, TerminalController.Chars.OP, "Josh, the connection seems REALLY messy, be careful."]
		]
	],
	"DESTROYED": [
		null,
		[
			[0, TerminalController.Chars.DRONE, "That doesn't look g"],
			[2, TerminalController.Chars.OP, "...And we lost connection, good job, intern."],
			[2, TerminalController.Chars.OP, "Nothing left to do, wait for extraction."]
		],
		[
			[0, TerminalController.Chars.DRONE, "Bad news, team"],
			[2, TerminalController.Chars.OP, "...And we lost connection, good job, intern."],
			[2, TerminalController.Chars.OP, "Nothing left to do, wait for extraction."]
		],
		[
			[0, TerminalController.Chars.DRONE, "Severe damage detected."],
			[2, TerminalController.Chars.OP, "Confirming drone destruction."],
			[2, TerminalController.Chars.OP, "Nothing left to do, wait for extraction."]
		],
		[
			[0, TerminalController.Chars.DRONE, "Mission failed."],
			[2, TerminalController.Chars.OP, "Confirming drone destruction."],
			[2, TerminalController.Chars.OP, "Nothing left to do, wait for extraction."]
		]
	],
	"THREAT_ELIMINATED": [
		null,
		null, 
		[
			[0, TerminalController.Chars.DRONE, "Creature neutralized."]
		],
		[
			[0, TerminalController.Chars.DRONE, "Creature neutralized."]
		],
		[
			[0, TerminalController.Chars.DRONE, "Threat eliminated."]
		]
	],
	"ZONE_REGRESS": [
		null,
		[
			[0, TerminalController.Chars.DRONE, "Mission 75% complete."]
		],
		[
			[0, TerminalController.Chars.DRONE, "Mission 50% complete."]
		],
		[
			[0, TerminalController.Chars.DRONE, "Mission 25% complete."]
		]
	]		
}

func get_progress_dialogue(type):
	return PROGRESS_DIALOGUES[type][GameManager.current_zone_idx]

var ending_dialogue_idx := 0

func get_ending_dialogue():
	if (GameManager.get_all_threats_left() <= (len(ENDING_DIALOGUES) - ending_dialogue_idx) * GameManager.total_threats / len(ENDING_DIALOGUES) and not ENDING_DIALOGUES_SENT[ending_dialogue_idx]):
		ENDING_DIALOGUES_SENT[ending_dialogue_idx] = true;
		ending_dialogue_idx += 1;
		return ENDING_DIALOGUES[ending_dialogue_idx - 1];
	return null;
		
func send_terminal_response(type, args):
	var idx: int
	if (GameManager.current_zone_idx <= 2 and not GameManager.doing_ending):
		idx = 0
	else:
		idx = 1
	var typ = TERMINAL_RESPONSES[type][idx][0];
	var formatted = TERMINAL_RESPONSES[type][idx][1] % args;
	var hid = TERMINAL_RESPONSES[type][idx][2] if TERMINAL_RESPONSES[type][idx].size() > 2 else false;
	TerminalController.send_type_message(formatted, typ, false, hid);
