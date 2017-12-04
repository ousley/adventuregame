:- ['sentence.pl'].

% TODO: generalized name matching that almost everything will need

%%% Definitions

% a room definition
% room(RmName,ShortDesc))
:- dynamic room/2.

% objects in room - observable, collectable, interactable
% ShortNames is a list of strings that the player can name the object with,
% while ShortDesc is a string the game would use e.g. when listing surroundings
% object(Name,ShortNames,ShortDesc,LongDesc)
:- dynamic object/4.

% location of an object in the world, if it is in the world
% location(ObjName,RmName).
:- dynamic location/2.

% exits, their destinations, and how to get to them
% would they be defined as objects? e.g. you could have an exit door close off
% but the doorway remain in the world
% exit(From,To,Direction)
:- dynamic exit/3.

% a type category for an object - is this necessary?
:- dynamic item/1.
:- dynamic scenery/1.
:- dynamic talker/1.

% a verb the player can use and words that invoke it
% verb(VbName,VbWords,VbHelp)
:- dynamic verb/3.

% something that ticks once for every turn the player takes.
% timer(Name,Count)
:- dynamic timer/2.
%keep track of whether or not the game is still running
:- dynamic running/1.

%%% Primary verb actions

% "go" with no target - list all exits in the same room as the player.
printgo :-
	% get player's current room
	location(player,Rm),
	!,
	writeln('Go where? From here, you can go:'),
	getexits(Rm).
% "go" with a direction - try to take a specified direction as an exit.
printgo(ExDir) :-
	location(player,Rm),
	exit(Rm,Ex,ExDir),
	room(Ex,ExName),
	!,
	retract(location(player,Rm)),
	assert(location(player,Ex)),
	format('You are now at ~s. You see:~n', [ExName]),
	getobjects(Ex),
	etick.
% "go" with unknown/unsuccessful exit direction
printgo(_) :-
	writeln('You can\'t go that way.').

% "get" with no target - list gettable items in same room as player.
printget :-
	location(player,Rm),
	!,
	writeln('Get what? You can try to get:'),
	getobjects(Rm,item).
% "get" with target - move an item to inventory, if it's in the player's current room.
printget(ShortName) :-
	% check that this is the name of an item
	object(Item,ShortNames,ObjNm,_),
	member(ShortName,ShortNames),
	item(Item),
	% make sure item is in same room as player
	location(player,Rm),
	location(Item, Rm),
	!,
	% move item to inventory
	retract(location(Item,Rm)),
	assert(location(Item,inventory)),
	format('You pick up ~s.', [ObjNm]),
	etick.
% "get" with target that isn't an item
printget(ShortName) :-
	% check that this is some non-item object
	object(Obj,ShortNames,ObjNm,_),
	member(ShortName,ShortNames),
	location(player,Rm),
	location(Obj,Rm),
	!,
	format('~s isn\'t something you can carry.', [ObjNm]).
% "get" with unknown target
printget(ShortName) :-
	format('There is no ~s here that you can get.',[ShortName]).

% "drop" with no target
printdrop :-
	writeln('What will you drop?').
% "drop" with target - move item from inventory to the room the player is in.
printdrop(ShortName) :-
	object(Item,ShortNames,ObjNm,_),
	member(ShortName,ShortNames),
	location(Item, inventory),
	location(player,Rm),
	!,
	retract(location(Item,inventory)),
	assert(location(Item,Rm)),
	format('You drop ~s.',[ObjNm]),
	etick.
% "drop" with target that the player isn't carrying
printdrop(ShortName) :-
	format('You aren\'t carrying any ~s.',[ShortName]).

% "look" with no target - list all objects in the same room as the player.
printlook :-
	% get player's current room
	location(player,Rm),
	!,
	room(Rm,RmName),
	format('You are at ~s. You see:~n', [RmName]),
	getobjects(Rm).
% "look" with no target and player somehow not in a room
printlook :-
	writeln('You can\'t see anything.').
% "look" with target - Print an object's short name and description.
printlook(ShortName) :-
	% check all alternate object names
	object(Obj,ShortNames,ObjNm,ObjDesc),
	member(ShortName,ShortNames),
	% make sure object is in inventory or same room as player
	location(player,Rm),
	(location(Obj,Rm); location(Obj,inventory)),
	!,
	format('This is ~s.~n~s', [ObjNm, ObjDesc]).
% "look" with unknown target or target not in room
printlook(Obj) :-
	format('You can\'t see any ~s.', [Obj]).

% "wait" - spend a turn doing nothing.
printwait :-
	writeln('You wait around.'),
	etick.
printwait(_) :- printwait.

% "inventory" - list all items in your inventory.
printinv :-
	% player has at least one item
	location(_,inventory),
	!,
	writeln('You are carrying:'),
	getobjects(inventory).
printinv :-
	writeln('You are not carrying anything.').
printinv(_) :- printinv.

% "status" - show turn count and score (santa part totals)
printstatus :-
	timer(global,T),
	format('You have taken ~d turns and collected [SANTACOUNT] santa parts.', [T]).
printstatus(_) :- printstatus.

% "help" with no target - general help/commands
printhelp :-
	format('Here are commands you can use. Type "help <command>" for more on a command.~n'),
	getverbs.
% "help" with target - get help on a verb
printhelp(Vb) :-
	% check all alternate verb names for a match
	verb(_,VbNames,VbHelp),
	member(Vb,VbNames),
	!,
	% list help text and alternate verb names
	format('~s~nTo use this command, you can type:~n', [VbHelp]),
	printlist(VbNames).
% "help" with unknown target
printhelp(_) :-
	writeln('I don\'t know that command.').

%Check if the player has once the game

%%% Helper Predicates
printwin :-
	location(santaHead,inventory),
	location(santaLegs,inventory),
	location(santaArms,inventory),
	location(santaBody,inventory),
	location(santaOutfit,inventory),
	write("Congratulations! Santa has been restored and you have saved Christmas!").
printwin :-
	write("You do not have all of the components needed to save Christmas.").
printwin(_) :- printwin.
quit :- running(true),
	write("You quit."),
	retract(running(true)).
quit(_) :- quit.

% List all available exits from the specified room.
getexits(Rm) :-
	exit(Rm,Ex,ExDir),
	room(Ex,ExDesc),
	format('* ~s to ~s',[ExDir,ExDesc]).

% List all objects in a room.
getobjects(Rm) :-
	object(Obj,_,ObjName,_),
	location(Obj,Rm),
	format('* ~s~n',[ObjName]),
	fail.

% ... of a particular type (e.g. item).
getobjects(Rm,Type) :-
	object(Obj,_,ObjName,_),
	location(Obj,Rm),
	% "Type(Obj)"
	call(Type,Obj),
	format('* ~s~n',[ObjName]),
	fail.

% List all verbs.
getverbs :-
	verb(_,[VbName|_],_),
	format('* ~s~n',[VbName]),
	fail.

% Helper function to print all items in a list - can be either strings or atoms.
printlist([]).
printlist([H|T]) :-
	format('* ~s~n', [H]),
	printlist(T).

%%% Main parsing stuff

% Main loop - read user input, parse it into a verb and target, run the command.
main1 :-
	repeat,
	running(true),
	getsentence(Line),
	%writeln(Line),
	parse(Line),
	fail.

% hack to trim leading empty atoms
parse([H|T]) :-
	H = '',
	parse(T).
parse([LVb|LTgt]) :-
	% try to match a verb
	verb(Vb,VbNames,_),
	member(LVb,VbNames),
	!,
	first(LTgt,Tgt),
	buildcall(Vb,Tgt).
% no verb matches - interpret this as a "go"
% TODO: can be done better
parse([LTgt]) :-
	printgo(LTgt).

buildcall(Vb,Tgt) :-
	Tgt = [],
	!,
	call(Vb).
buildcall(Vb,Tgt) :-
	call(Vb,Tgt).

% Increment all active timers. Every verb that would take time to perform should call this.
% TODO: anything that acts autonomously should act here;
% e.g. actors moving around, objects changing attributes when you pick them up
etick :-
	timer(N,T),
	Tn is T+1,
	retract(timer(N,T)),
	assert(timer(N,Tn)).

% The player runs this to start the game, printing introductory stuff and starting the main loop.
start :-
	assert(running(true)),
	writeln("It is Christmas Eve, 2017. The boys and girls of planet Earth sleep soundly in their homes, unaware of the trajedy that has occured. Santa Claus has been in a terrible sleigh accident. So bad, in fact, that the very body parts that compose him have been scattered across New York City. Hurry. Find Santa's parts. Once you have them, quickly rebuild him so that he can finish delivering presents. Should you fail to complete this task in 2 hours (20 turns), Christmas will be ruined. Make haste."),
	writeln('Type commands as "verb target." (including period) and type "help." for help.'),
	printlook;
	main1.

first([X|_], X).
first([], []).

% an example

room(streetCorner, "a street corner").
room(office, "a dingy office").

object(player,['you','yourself','me','myself','self'], "you",
"You turn your gaze inward and do a little soul searching.").
object(streetlamp,['streetlamp','streetlight','lamp','light','lamppost'],"a street lamp",
"An old-timey street lamp, little more than a wrought-iron lantern on a post. The light flickers a little.").
object(jacketMan,['man'],"a man in a black jacket",
"A shady-looking guy wearing a black leather jacket and dark sunglasses. Because you can't tell where he's looking, you can't help but feel like he's watching you.").
object(paperFolded,['paper'],"a folded scrap of paper",
"A tattered piece of paper. It is hastily folded up, but there seems to be writing on it.").
object(paperUnfolded,['paper'],"a scrap of paper",
"A tattered piece of paper. It reads, \"the quick brown fox.\"").
object(statue,['statue','sculpture'],"a marble statue",
"A large marble statue of...something. From one angle it looks like a woman, but from another it looks more like an elephant. Pondering this gives you a headache.").

%SANTA CLAUS OBJECTS
object(santaHead,['head','santahead'], "Santa...does not look well...").
object(santaLegs,['legs','leg','santalegs', 'santaleg'],"the legs of Santa himself...").
object(santaArms,['arms','santaarms','santaarm','arm'],"Santa needs these to deliver his presents...").
object(santaBody,['body', 'torso', 'santabody', 'santatorso'], "this must be where he keeps his cookies...").
object(santaOutfit,['coat','santacoat','pants','santapants'],"without his uniform, Santa is just a big jolly creep...").
object(rudolph,['reindeer','rudolph'],"Rudolph lies on the asphault. He is not breathing.").

item(paperFolded).
item(paperUnfolded).
item(santaHead).
item(santaLegs).
item(santaArms).
item(santaBody).
item(santaOutfit).

talker(player).
talker(jacketMan).

location(player,streetCorner).
location(streetlamp,streetCorner).
location(jacketMan,streetCorner).
location(paperFolded,streetCorner).
location(statue,office).

exit(streetCorner,bealeSt,east).
exit(streetCorner,parkAve,south).
exit(streetCorner,sewer,down).
exit(streetCorner,office,in).
exit(office,streetCorner,out).

verb(printgo,['go','walk',"move",'g'],
"Move to a different room or area. Use without a direction to see all the places you can go and how to get to them.").
verb(printget,['get','pickup','take'],
"Pick something up. Use without a target to see everything you can pick up.").
verb(printdrop,['drop','putdown'],
"Put something down.").
verb(printhelp,['help','?'],
"Get basic help on how to use a command. Use without any commands to get a list of all available commands.").
verb(printlook,['look','lookat','examine','describe','l'],
"Examine something in more detail. Use without a target to size up everything in the area.").
verb(printwin,['rebuild', 'heal', 'fix','restore'],"Once you have collected all of Santa's components, you will win the game!").
verb(printwait,['wait','z'],
"Do nothing for a moment.").
verb(printinv,['inventory','items','i'],
"See what items you are carrying.").
verb(printstatus,['status','stat','diagnose'],
"See how you're doing so far.").
verb(quit,['quit', 'stop', 'end'],
"End the game.").


%UNIMPLEMENTED
verb(printwear,['wear','equip','puton'],
"Put on a piece of clothing, jewelry, or other wearable item. Use without a target to see everything you can wear.").
verb(printremove,['remove','takeoff','unwear'],
"Remove an article you are wearing. Use without a target to see everything you are wearing.").
verb(printtalk,['talk','speak','talkto','speakto','t'],
"Have a conversation with someone or something. Use without a target to see everyone and everything you can talk to.").

timer(global,0).

% vim:ft=prolog
