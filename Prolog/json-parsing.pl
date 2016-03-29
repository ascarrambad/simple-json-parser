%%%% -*- Mode: Prolog -*-
%%%%
%%%% Yet Another 'From Scratch' JSON Parser
%%%%
%%%%---------------------------------------------------------------------------
%%%% JSON Parser

jsonparse(JSONString, Object) :-
	atom_codes(JSONString, Codes),
	parse_object(Codes, TBD, Object),
	!,
	TBD = [].

jsonparse(JSONString, Object) :-
	atom_codes(JSONString, Codes),
	parse_array(Codes, TBD, Object),
	!,
	TBD = [].

%%%%---------------------------------------------------------------------------
%%%% Object parser

parse_object(List, TBD, Res) :-
	skip_whitespaces(List, [L | Ls]),
	is_lbracket(L),
	skip_whitespaces(Ls, [L2 | L2s]),
	is_rbracket(L2),
	!,
	Res = jsonobj([]),
	TBD = L2s.

parse_object(List, TBD, Res) :-
	skip_whitespaces(List, [L | Ls]),
	is_lbracket(L),
	parse_member(Ls, [L2 | L2s], TmpRes),
	is_rbracket(L2),
	!,
	Res = jsonobj(TmpRes),
	TBD = L2s.

%%%%---------------------------------------------------------------------------
%%%% Array parser

parse_array(List, TBD, Res) :-
	skip_whitespaces(List, [L | Ls]),
	is_lsqbracket(L),
	skip_whitespaces(Ls, [L2 | L2s]),
	is_rsqbracket(L2),
	!,
	Res = jsonarray([]),
	TBD = L2s.

parse_array(List, TBD, Res) :-
	skip_whitespaces(List, [L | Ls]),
	is_lsqbracket(L),
	parse_element(Ls, [L2 | L2s], TmpRes),
	is_rsqbracket(L2),
	!,
	Res = jsonarray(TmpRes),
	TBD = L2s.

%%%%---------------------------------------------------------------------------
%%%% Element parser

parse_element(List, TBD, Res) :-
	parse_element(List, [], TBD, Res).

parse_element(List, Done, TBD, Res) :-
	parse_value(List, TmpTBD, TmpRes),
	append(Done, [TmpRes], TmpDone),
	skip_whitespaces(TmpTBD, [L | Ls]),
	is_comma(L),
	!,
	parse_element(Ls, TmpDone, TBD, Res).

parse_element(List, Done, TBD, Res) :-
	parse_value(List, TmpTBD, TmpRes),
	append(Done, [TmpRes], TmpDone),
	skip_whitespaces(TmpTBD, [L | Ls]),
	\+(is_comma(L)),
	!,
	Res = TmpDone,
	TBD = [L | Ls].

%%%%---------------------------------------------------------------------------
%%%% Member parser

parse_member(List, TBD, Res) :-
	parse_member(List, [], TBD, Res).

parse_member(List, Done, TBD, Res) :-
	parse_pair(List, TmpTBD, TmpRes),
	append(Done, [TmpRes], TmpDone),
	remove_duplicates(TmpDone, TmpRes, Tmp2Done),
	skip_whitespaces(TmpTBD, [L | Ls]),
	is_comma(L),
	!,
	parse_member(Ls, Tmp2Done, TBD, Res).

parse_member(List, Done, TBD, Res) :-
	parse_pair(List, TmpTBD, TmpRes),
	append(Done, [TmpRes], TmpDone),
	remove_duplicates(TmpDone, TmpRes, Tmp2Done),
	skip_whitespaces(TmpTBD, [L | Ls]),
	\+(is_comma(L)),
	!,
	Res = Tmp2Done,
	TBD = [L | Ls].

%%%%---------------------------------------------------------------------------
%%%% Pair parser

parse_pair(List, TBD, Res) :-
	skip_whitespaces(List, Tmp),
	parse_string(Tmp, Tmp2, TmpRes1),
	!,
	skip_whitespaces(Tmp2, [T | Ts]),
	is_colon(T),
	parse_value(Ts, TBD, Res2),
	atom_string(Res1, TmpRes1),
	Res = (Res1, Res2).

parse_pair(List, TBD, Res) :-
	skip_whitespaces(List, Tmp),
	parse_identifier(Tmp, Tmp2, Res1),
	!,
	skip_whitespaces(Tmp2, [T | Ts]),
	is_colon(T),
	parse_value(Ts, TBD, Res2),
	Res = (Res1, Res2).

%%%%---------------------------------------------------------------------------
%%%% Value parser

parse_value(List, TBD, Res) :-
	parse_string(List, TBD, Res),
	!.

parse_value(List, TBD, Res) :-
	parse_number(List, TBD, Res),
	!.

parse_value(List, TBD, Res) :-
	parse_object(List, TBD, Res),
	!.

parse_value(List, TBD, Res) :-
	parse_array(List, TBD, Res),
	!.

%%%%---------------------------------------------------------------------------
%%%% String parser

parse_string(List, TBD, Res) :-
	skip_whitespaces(List, [L | Ls]),
	is_quote(L),
	parse_string(Ls, [], L, TBD, Res).

parse_string([L1, L2 | Ls], Done, End, TBD, Res) :-
	is_backslash(L1),
	is_quote(L2),
	!,
	append(Done, [L2], TmpDone),
	parse_string(Ls, TmpDone, End, TBD, Res).

parse_string([L | TBD], Done, L, TBD, Res) :-
	is_quote(L),
	!,
	string_codes(Res, Done).

parse_string([L | Ls], Done, End, TBD, Res) :-
	!,
	append(Done, [L], TmpDone),
	parse_string(Ls, TmpDone, End, TBD, Res).

%%%%---------------------------------------------------------------------------
%%%% Identifier parser

parse_identifier(List, TBD, Res) :-
	skip_whitespaces(List, [L | Ls]),
	is_alpha(L),
	parse_identifier(Ls, [L], TBD, Res).

parse_identifier([L | Ls], Done, TBD, Res) :-
	is_alnum(L),
	!,
	append(Done, [L], TmpDone),
	parse_identifier(Ls, TmpDone, TBD, Res).

parse_identifier(List, Done, TBD, Res) :-
	skip_whitespaces(List, [L | Ls]),
	\+(is_alnum(L)),
	!,
	atom_codes(Res, Done),
	TBD = [L | Ls].

parse_identifier([], Done, [], Res) :-
	!,
	atom_codes(Res, Done).

%%%%---------------------------------------------------------------------------
%%%% Number parser

parse_number(List, TBD, Res) :-
	skip_whitespaces(List, [L | Ls]),
	is_digit(L),
	!,
	parse_number(Ls, [L], TBD, Res).

parse_number(List, TBD, Res) :-
	skip_whitespaces(List, [L | Ls]),
	is_signum(L),
	!,
	parse_number(Ls, [L], TBD, Res).

parse_number([L | Ls], Done, TBD, Res) :-
	is_digit(L),
	!,
	append(Done, [L], TmpDone),
	parse_number(Ls, TmpDone, TBD, Res).

parse_number([L | Ls], Done, TBD, Res) :-
	is_dot(L),
	Ls \= [],
	last(Done, Last),
	is_digit(Last),
	!,
	append(Done, [L], TmpDone),
	parse_float(Ls, TmpDone, TBD, Res).

parse_number([L | Ls], Done, TBD, Res) :-
	\+(is_digit(L)),
	last(Done, Last),
	is_digit(Last),
	!,
	number_codes(Res, Done),
	TBD = [L | Ls].

parse_number([], Done, [], Res) :-
	!,
	number_codes(Res, Done).

parse_float([L | Ls], Done, TBD, Res) :-
	is_digit(L),
	!,
	append(Done, [L], TmpDone),
	parse_float(Ls, TmpDone, TBD, Res).

parse_float([L | Ls], Done, TBD, Res) :-
	\+(is_digit(L)),
	last(Done, Last),
	is_digit(Last),
	!,
	number_codes(Res, Done),
	TBD = [L | Ls].

parse_float([], Done, [], Res) :-
	last(Done, Last),
	is_digit(Last),
	!,
	number_codes(Res, Done).


%%%%---------------------------------------------------------------------------
%%%% JSON Consult

jsonget(Result, [], Result) :- !.

jsonget(JSON_obj, Field, Result) :-
	Field \= [_ | _],
	!,
	jsonget(JSON_obj, [Field], Result).

jsonget(jsonobj(List), [Field | Fields], Result) :-
	!,
	find_pair(List, Field, Tmp),
	jsonget(Tmp, Fields, Result).

jsonget(jsonarray(List), [Field | Fields], Result) :-
	!,
	nth0(Field, List, Tmp),
	jsonget(Tmp, Fields, Result).

%%%%---------------------------------------------------------------------------
%%%% Read from file

jsonload(FileName, JSON) :-
	read_file_to_string(FileName, String),
	atom_string(Atom, String),
	jsonparse(Atom, JSON).

read_file_to_string(FileName, Result) :-
	open(FileName, read, In),
	read_string(In, _, Result),
	close(In).

%%%%---------------------------------------------------------------------------
%%%% Write object on file

jsonwrite(JSON, FileName) :-
	write_object(JSON, [], Codes),
	!,
	string_codes(Res, Codes),
	write_string_to_file(FileName, Res).

jsonwrite(JSON, FileName) :-
	write_array(JSON, [], Codes),
	!,
	string_codes(Res, Codes),
	write_string_to_file(FileName, Res).

write_array(jsonarray(Lista), Done, Res) :-
	append(Done, [91], TmpDone),
	write_values(Lista, TmpDone, TmpRes),
	append(TmpRes, [93], Res).

write_values([], Done, Res) :-
	!,
	remove_last(Done, Res).

write_values([L | Ls], Done, Res) :-
	!,
	write_value(L, Done, TmpDone),
	append(TmpDone, [44], TmpRes),
	write_values(Ls, TmpRes, Res).

write_object(jsonobj(Lista), Done, Res) :-
	append(Done, [123], TmpDone),
	write_pairs(Lista, TmpDone, TmpRes),
	append(TmpRes, [125], Res).

write_pairs([], Done, Res) :-
	!,
	remove_last(Done, Res).

write_pairs([(Str, Val) | Ls], Done, Res) :-
	atom_codes(Str, TmpCodes),
	!,
	write_companion(TmpCodes, [], Codes),
	append([34 | Codes], [34], Tmp2Codes),
	append(Done, Tmp2Codes, TmpDone),
	append(TmpDone, [58], Tmp2Done),
	write_value(Val, Tmp2Done, TmpRes),
	append(TmpRes, [44], Tmp2Res),
	write_pairs(Ls, Tmp2Res, Res).

write_value(jsonobj(List), Done, Res) :-
	!,
	write_object(jsonobj(List), Done, Res).

write_value(jsonarray(List), Done, Res) :-
	!,
	write_array(jsonarray(List), Done, Res).

write_value(Str, Done, Res) :-
	string(Str),
	!,
	string_codes(Str, TmpCodes),
	write_companion(TmpCodes, [], Codes),
	append([34 | Codes], [34], Tmp2Codes),
	append(Done, Tmp2Codes, Res).

write_value(Num, Done, Res) :-
	number_string(Num, Str),
	!,
	string_codes(Str, Codes),
	append(Done, Codes, Res).

write_string_to_file(Filename, Term) :-
	open(Filename, write, Out),
	write(Out, Term),
	close(Out).

%%%%---------------------------------------------------------------------------
%%%% Companion predicates

find_pair([L | _], Term, Res) :-
	L = (Term, Res),
	!.

find_pair([L | Ls], Term, Res) :-
	L \= (Term, Res),
	!,
	find_pair(Ls, Term, Res).

remove_duplicates(List, Pair, Res) :-
	reverse(List, [L | Ls]),
	remove_duplicates(Ls, Pair, [], TmpRes),
	append([L], TmpRes, Tmp2Res),
	reverse(Tmp2Res, Res).

remove_duplicates([], (_, _), Res, Res) :- !.

remove_duplicates([(I, _) | Ls], (I, _), Done, Res) :-
	!,
	remove_duplicates(Ls, (I, _), Done, Res).

remove_duplicates([(K, B) | Ls], (I, _), Done, Res) :-
	I \= K,
	!,
	append(Done, [(K, B)], TmpDone),
	remove_duplicates(Ls, (I, _), TmpDone, Res).

skip_whitespaces([W | MoreChars], RestChars) :-
	is_whitespace(W),
	!,
	skip_whitespaces(MoreChars, RestChars).

skip_whitespaces([C | Chars], [C | Chars]) :- !.

skip_whitespaces([], []) :- !.

is_whitespace(C) :- char_type(C, white), !.
is_whitespace(8232) :- !.
is_whitespace(8233) :- !.
is_whitespace(10) :- !.
is_whitespace(13) :- !.

write_companion([], Res, Res) :- !.

write_companion([L | Ls], Tmp, Res) :-
	is_quote(L),
	!,
	append(Tmp, [92, L], Tmp2),
	write_companion(Ls, Tmp2, Res).

write_companion([L | Ls], Tmp, Res) :-
	!,
	append(Tmp, [L], Tmp2),
	write_companion(Ls, Tmp2, Res).

is_dot(46).

is_lbracket(123).
is_rbracket(125).

is_lsqbracket(91).
is_rsqbracket(93).

is_backslash(92).

is_comma(44).
is_colon(58).

is_signum(45) :- !.
is_signum(43) :- !.

remove_last(In, Out) :-
    append(Out, [_], In),
    !.

%%%% end of file -- json-parsing.pl --
