%%% sentence parsing

getsentence(Words, In, Out) :-
   get0(C),
%split on periods
   ((C = 46, name(W, In), append(Words,[W],Out), !); 
%break on spaces
    (C = 32, name(W, In), append(Words,[W],Words1), getsentence(Words1, [], Out), !);
%break on newlines
    (C = 10, name(W, In), append(Words,[W],Words2), getsentence(Words2, [], Out), !);
    append(In,[C],In1), getsentence(Words, In1,Out)).

getsentence(Words) :-
   getsentence([],[],Words).

% Read sentence and map chars to atoms.
readsentence(S1) :-
   getsentence(R),
   mapwords(R, S),
   strip(S, S1).

% Strip blanks
strip_initial([],[]).
strip_initial([blank|S],R) :-
   !, strip_initial(S,R).
strip_initial(S,S).

strip_final(S,R) :-
   reverse(S,S1),
   strip_initial(S1,S2),
   reverse(S2,R).

strip_inside([],[]).
strip_inside([blank,blank|S],R) :-
   !, strip_inside([blank|S],R).
strip_inside([blank|S],[blank|R]) :-
   !, strip_inside(S,R).
strip_inside([C|S],[C|R]) :-
   strip_inside(S,R).

strip(S,R):-
   strip_initial(S,S1),
   strip_inside(S1,S2),
   strip_final(S2, R).

% Split words into letters.
mapwords([W|WL],S) :-
   name(W, N),
   mapchars(N, S1),
   mapwords(WL, S2),
   append(S1,[blank|S2], S).
mapwords([],[]).

mapchars([C|N], [C1|S]) :-
   mapchar([C], C1),
   mapchars(N, S).
mapchars([],[]).

mapchar("A",a). mapchar("B",b). mapchar("C",c). mapchar("D",d). mapchar("E",e).
mapchar("F",f). mapchar("G",g). mapchar("H",h). mapchar("I",i). mapchar("J",j).
mapchar("K",k). mapchar("L",l). mapchar("M",m). mapchar("N",n). mapchar("O",o).
mapchar("P",p). mapchar("Q",q). mapchar("R",r). mapchar("S",s). mapchar("T",t).
mapchar("U",u). mapchar("V",v). mapchar("W",w). mapchar("X",x). mapchar("Y",y).
mapchar("Z",z).

mapchar("a",a). mapchar("b",b). mapchar("c",c). mapchar("d",d). mapchar("e",e).
mapchar("f",f). mapchar("g",g). mapchar("h",h). mapchar("i",i). mapchar("j",j).
mapchar("k",k). mapchar("l",l). mapchar("m",m). mapchar("n",n). mapchar("o",o).
mapchar("p",p). mapchar("q",q). mapchar("r",r). mapchar("s",s). mapchar("t",t).
mapchar("u",u). mapchar("v",v). mapchar("w",w). mapchar("x",x). mapchar("y",y).
mapchar("z",z).

mapchar("!", excl_mark).  mapchar("?", quest_mark).
mapchar(".", full_stop).  mapchar(",", comma).
mapchar("-", hyphen).     mapchar(";", semicolon).
mapchar("$", dollar).     mapchar("'",apostrophe).

mapchar("0", 0). mapchar("1", 1). mapchar("2", 2). mapchar("3", 3). 
mapchar("4", 4). mapchar("5", 5). mapchar("6", 6). mapchar("7", 7). 
mapchar("8", 8). mapchar("9", 9). 

mapchar(X, X).



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
% ** to make a two-way path, an exit in one room should lead to the other and vice versa
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
%keep track of santa part progress
:- dynamic progress/1.


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
	format('You pick up ~s.~n', [ObjNm]),
	% cut so we only pick up one item at a time if there are duplicates
	!,
	etick, !.
% "get" with target that isn't an item
printget(ShortName) :-
	% check that this is some non-item object
	object(Obj,ShortNames,ObjNm,_),
	member(ShortName,ShortNames),
	location(player,Rm),
	location(Obj,Rm),
	%retract(progress(X)),
	%assert(progress(Y)),
	%Y is X + 20,
	!,
	format('~s isn\'t something you can carry.~n', [ObjNm]).
% "get" with unknown target
printget(ShortName) :-
	format('There is no ~s here that you can get.~n',[ShortName]).

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
	%retract(progress(X)),
	%assert(progress(Y)),
	%Y is X + 20,

	% cut so we only drop one item at a time if there are duplicates
	!,
	format('You drop ~s.~n',[ObjNm]),
	etick, !.
% "drop" with target that the player isn't carrying
printdrop(ShortName) :-
	format('You aren\'t carrying any ~s.~n',[ShortName]).

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
	format('This is ~s.~n~s~n', [ObjNm, ObjDesc]).
% "look" with unknown target or target not in room
printlook(Obj) :-
	format('You can\'t see any ~s.~n', [Obj]).

% "wait" - spend a turn doing nothing.
printwait :-
	writeln('You wait around.'),
	etick, !.
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
	partcount(P),
	format('You have taken ~d turns and collected ~d/5 of santa\'s parts.~n', [T,P]).
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

%Check if the player has won the game
printwin :-
	location(santaHead,inventory),
	location(santaLegs,inventory),
	location(santaArms,inventory),
	location(santaBody,inventory),
	location(santaOutfit,inventory),!,
	writeln("Congratulations! Santa has been restored and you have saved Christmas!").
printwin :-
	writeln("You do not have all of the components needed to save Christmas.").
printwin(_) :- printwin.

% Quit the game.
quit :- running(true),
	writeln("You quit."),
	retract(running(true)).
quit(_) :- quit.

%%% Helper Predicates

% Get the first element in a list. Used to truncate user input.
first([X|_], X).
first([], []).

% List all available exits from the specified room.
getexits(Rm) :-
	exit(Rm,Ex,ExDir),
	room(Ex,ExDesc),
	format('* ~s to ~s~n',[ExDir,ExDesc]),
	fail.

% List all objects in a room.
getobjects(Rm) :-
	object(Obj,_,ObjName,_),
	location(Obj,Rm),
	format('* ~s~n',[ObjName]),
	fail.
getobjects(_).

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
	% if
	(running(true) ->
	% then
		getsentence(Line),
		parse(Line),
		% loop back to main1
		fail;
	% else
		% cut and don't loop
		!
	).

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

% Generate a call to one of the defined verbs, depending on whether a target was given.
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

partcount(Ct) :-
	% create a list L of all santa parts the player has
	findall(P, havepart(P),L),
	% get its length
	length(L,Ct).

% Check whether P is a santa part and in the player's inventory.
havepart(P) :-
	santapart(P),
	location(P,inventory).

% The player runs this to start the game, printing introductory stuff and starting the main loop.
start :-
	assert(running(true)),
	assert(progress(0)),
	writeln("It is Christmas Eve, 2017. The boys and girls of planet Earth sleep soundly in their homes, unaware of the trajedy that has occured. Santa Claus has been in a terrible sleigh accident. So bad, in fact, that the very body parts that compose him have been scattered across New York City. Hurry. Find Santa's parts. Once you have them, quickly rebuild him so that he can finish delivering presents. Should you fail to complete this task in 2 hours (20 turns), Christmas will be ruined. Make haste."),
	writeln('Type commands as "verb target." (including period) and type "help." for help.'),
	printlook;
	main1.



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

object(fossil,['fossil','dinosaur','skeleton','trex','t-rex'],"a giant fossil","The skeleton of a massive T-Rex stands before you.").
object(tiger,['tiger'],"a fierce tiger","You see a tiger eating something. You look in closer. Oh no...not Prancer!").
object(painting,['art','painting'],"a painting","This painting is of a man riding a unicorn.").
object(sleigh,['sleigh','santas sleigh'],"a mangled sleigh", "This must be where the crash occured. Ironic.").
object(performers,['performers','dancers'],"a group of performers", "A group of people dressed as elves sing Jingle Bells.").
object(bum,['bum','homeless man'],"a bum", "A bum lies on the street in tears. Only the revival of Santa can cheer him up.").
object(tree,['christmas tree','tree'],"a christmas tree","Ah, the famous Rockefeller Center Christmas Tree. You have a hard time enjoying it, knowing that this may be the last time it is ever erected...").
object(deer,['deer','reindeer','Cupid'], "an injured reindeer", "You see a reindeer limping across an intersection. ").
object(elves,['elves','elf'], "frantic elves", "A group of elves scurry around the sidewalk, gathering presents that were scattered during the crash.").



%SANTA CLAUS OBJECTS
object(santaHead,['head','santahead'],"santa's head", "Santa...does not look well...").
object(santaLegs,['legs','leg','santalegs', 'santaleg'],"a pair of Santa legs","the legs of Santa himself...").
object(santaArms,['arms','santaarms','santaarm','arm'],"a pair of Santa arms","Santa needs these to deliver his presents...").
object(santaBody,['body', 'torso', 'santabody', 'santatorso'],"the body of Santa", "this must be where he keeps his cookies...").
object(santaOutfit,['coat','santacoat','pants','santapants','outfit','uniform'],"Santa's uniform and hat","without his uniform, Santa is just a big jolly creep...").
object(rudolph,['reindeer','rudolph'],"Rudolph lies on the asphault. He is not breathing. His noses flickers a few times and then fades to black.").

item(paperFolded).
item(paperUnfolded).
item(santaHead).
item(santaLegs).
item(santaArms).
item(santaBody).
item(santaOutfit).

santapart(santaHead).
santapart(santaLegs).
santapart(santaArms).
santapart(santaBody).
santapart(santaOutfit).

talker(player).
talker(jacketMan).
location(streetlamp,streetCorner).
location(jacketMan,streetCorner).
location(paperFolded,streetCorner).
location(statue,office).



%New York Items
location(player,centralPark).
location(fossil,americanNatHistory).
location(tiger,centralParkZoo).
location(painting,metropolitanMuseum).
location(painting,museumModernArt).
location(performers,timesSquare).
location(sleigh,cathedral).
location(bum,empireState).
location(tree,rockefellerCtr).
location(santaArms,centralPark).
location(santaLegs,empireState).
location(santaBody,cathedral).
location(rudolph,rockefellerCtr).
location(santaOutfit,timesSquare).
location(santaHead,littleItaly).
location(deer, centralPark).
location(elves,timesSquare).


% old example rooms

room(streetCorner, "a street corner").
room(bealeSt, "an east/west street").
room(office, "a dingy office").

%New York City
room(centralPark, "Central Park").
room(americanNatHistory, "the American Natural History Museum").
room(centralParkZoo, "the Central Park Zoo").
room(metropolitanMuseum, "the Metropolitan Museum of Art").
room(museumModernArt, "the Museum of Modern Art").
room(carnegieHall, "Carnegie Hall").
room(cathedral, "St. Patrick's Cathedral").
room(radioCityMH,"Radio City Music Hall").
room(timesSquare, "Times Square").
room(rockefellerCtr, "Rockefeller Center").
room(empireState, "the Empire State Building").
room(unionSquare, "Union Square").
room(littleItaly, "Little Italy").

% old example exits

exit(streetCorner,bealeSt,east).
exit(streetCorner,parkAve,south).
exit(streetCorner,sewer,down).
exit(streetCorner,office,in).
exit(bealeSt, streetCorner, west).
exit(office,streetCorner,out).

%New York Paths
exit(centralPark,americanNatHistory,west).
exit(centralPark,metropolitanMuseum,east).
exit(centralPark,centralParkZoo,south).
exit(centralParkZoo,centralPark,north).
exit(centralParkZoo,museumModernArt,south).
exit(americanNatHistory,centralPark,east).
exit(metropolitanMuseum,centralPark,west).
exit(americanNatHistory,carnegieHall,south).
exit(carnegieHall,americanNatHistory,north).
exit(carnegieHall,museumModernArt,east).
exit(museumModernArt,centralParkZoo,north).
exit(museumModernArt,carnegieHall,west).
exit(museumModernArt,cathedral,south).
exit(cathedral,museumModernArt,north).
exit(cathedral,radioCityMH,west).
exit(radioCityMH,cathedral,east).
exit(radioCityMH,timesSquare,south).
exit(timesSquare,radioCityMH,north).
exit(cathedral,rockefellerCtr,south).
exit(rockefellerCtr,cathedral,north).
exit(rockefellerCtr,empireState,south).
exit(timesSquare,empireState,east).
exit(empireState,timesSquare,west).
exit(empireState,rockefellerCtr,north).
exit(empireState,unionSquare,south).
exit(unionSquare,empireState,north).
exit(unionSquare,littleItaly,east).
exit(littleItaly,unionSquare,west).


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
