:- ['sentence.pl'].

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
% verb(VbName,VbHelp,VbWords)
:- dynamic verb/3.

% functions

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
% TODO: adapt to match alternate object names
printlook(Obj) :-
	% make sure object is in same room as player
	location(player,Rm),
	location(Obj,Rm),
	!,
	object(Obj,_,ObjNm,ObjDesc),
	format('This is ~s.~n~s', [ObjNm, ObjDesc]).
% "look" with unknown target or target not in room
printlook(Obj) :-
	format('You can\'t see any ~s.', [Obj]).

% "help" with no target - general help/commands
printhelp :-
	format('Here are commands you can use. Type "help <command>" for more on a command.~n'),
	getverbs.
% "help" with target - get help on a verb
printhelp(Vb) :-
	verb(_,VbHelp,VbNames),
	% check all alternate verb names for a match
	name(Vb,StrVb),
	member(StrVb,VbNames),
	% list help text and alternate verb names
	format('~s~nTo use this command, you can type:~n', [VbHelp]),
	printlist(VbNames), !.
% "help" with unknown target
printhelp(_) :-
	writeln('I don\'t know that command.').

% List all objects in a room.
getobjects(Rm) :-
	object(Obj,_,ObjName,_),
	location(Obj,Rm),
	format('* ~s~n',[ObjName]),
	fail.

% List all verbs.
getverbs :-
	verb(_,_,[VbName|_]),
	format('* ~s~n',[VbName]),
	fail.

% Helper function to print all items in a list - can be either strings or atoms.
printlist([]).
printlist([H|T]) :-
	format('* ~s~n', [H]),
	printlist(T).

% an example

room(streetCorner, "a street corner").

object(player,["you"], "you", "").
object(streetlamp,["streetlamp","streetlight","lamp","light","lamppost"],
"a street lamp", "An old-timey street lamp, little more than a wrought-iron lantern on a post. The light flickers a little.").
object(jacketMan,["man"],
"a man in a black jacket","A shady-looking guy wearing a black leather jacket and dark sunglasses. Because you can't tell where he's looking, you can't help but feel like he's watching you.").
object(paperFolded,["paper"],
"a folded scrap of paper", "A tattered piece of paper. It is hastily folded up, but there seems to be writing on it.").
object(paperUnfolded,["paper"],
"a scrap of paper", "A tattered piece of paper. It reads, \"the quick brown fox.\"").

item(paperFolded).
item(paperUnfolded).

location(streetlamp,streetCorner).
location(jacketMan,streetCorner).
location(paperFolded,streetCorner).

exit(streetCorner,bealeSt,east).
exit(streetCorner,parkAve,south).
exit(streetCorner,sewer,down).
exit(streetCorner,office,in).

verb(go,"Move to a different room or area. Use without a direction to see all the places you can go and how to get to them.",["go","walk","g"]).
verb(get,"Pick something up. Use without a target to see everything you can pick up.",["get","pick up","take"]).
verb(look,"Examine something in more detail. Use without a target to size up everything in the area.",["look","look at","examine","describe","l"]).
verb(talk,"Have a conversation with someone or something. Use without a target to see everyone and everything you can talk to.",["talk","speak","talk to","speak to","t"]).

% vim:ft=prolog
