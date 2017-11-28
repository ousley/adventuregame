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
% verb(VbName,VbWords)
:- dynamic verb/2.

% functions

printobjects(Rm) :-
	room(_,Nm),
	name(RmNm, Nm),
	write('You are at '), write(RmNm), writeln('. You see:'), getobjects(Rm).

% List all objects currently located in a room.
getobjects(Rm) :-
	object(ObjName,_,ObjShortDesc,_),
	location(ObjName,Rm),
	name(N,ObjShortDesc),
	writeln(N),
	fail.

% an example

room(streetCorner, "a street corner").

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

verb(go,["go","walk","g"]).
verb(get,["get","pick up","take"]).
verb(look,["look","look at","examine","describe","l"]).
verb(talk,["talk","speak","talk to","speak to","t"]).

% vim:ft=prolog
