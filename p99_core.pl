% -*- mode: prolog; -*-

/** <module> P-99: Ninety-Nine Prolog Problems

This file contains the predicate definitions for the Ninety-Nine Prolog Problems,
a collection of problems designed to test and improve Prolog programming skills.

This file has no module declarations so it can be included by systems that
don't support modules (like GNU Prolog) or included by module wrappers.

@see https://www.ic.unicamp.br/~meidanis/courses/mc336/2009s2/prolog/problemas/
*/

%%  my_last(?X, +List) is semidet.
%
%   P01: Find the last element of a list.

my_last(X, [X]).
my_last(X, [_|Y]) :- my_last(X, Y).

%%  penultimate(?X, +List) is semidet.
%
%   P02: Find the last but one element of a list.

penultimate(X, [X,_]).
penultimate(X, [_|Y]) :- penultimate(X, Y).

%%  element_at(?X, +List, +K) is semidet.
%
%   P03: Find the K'th element of a list (1-based index).

element_at(X, [X|_], 1).
element_at(X, [_|Y], K) :-
    K > 1,
    J is K - 1,
    element_at(X, Y, J).

%%  my_length(?Count, +List) is det.
%
%   P04: Find the number of elements in a list.

my_length(0, []).
my_length(Count, [_|Tail]) :-
    my_length(TailCount, Tail),
    Count is TailCount + 1.

%%  my_reverse(+List, -Reversed) is det.
%
%   P05: Reverse a list.

my_reverse(List, Reversed) :- my_reverse_acc(List, [], Reversed).

my_reverse_acc([], Acc, Acc).
my_reverse_acc([Head|Tail], Acc, Result) :- my_reverse_acc(Tail, [Head|Acc], Result).

%%  is_palindrome(+List) is semidet.
%
%   P06: Find out whether a list is a palindrome.

is_palindrome(List) :- my_reverse(List, List).

%%  my_flatten(+NestedList, -FlatList) is det.
%
%   P07: Flatten a nested list structure.

my_flatten([], []).
my_flatten([X|Xs], [X|Zs]) :-
    \+ is_list(X),
    my_flatten(Xs, Zs).
my_flatten([X|Xs], Zs) :-
    is_list(X),
    my_flatten(X, FlatX),
    my_flatten(Xs, FlatXs),
    my_append(FlatX, FlatXs, Zs).

%%  my_append(+List1, +List2, -Result) is det.

my_append([], Ys, Ys).
my_append([X|Xs], Ys, [X|Zs]) :- my_append(Xs, Ys, Zs).

%%  compress(+Uncompressed, -Compressed) is det.
%
%   P08: Eliminate consecutive duplicates of list elements.

compress([], []).
compress([X|Xs], [X|Ys]) :- compress_skip_dups(X, Xs, Rest), compress(Rest, Ys).

compress_skip_dups(_, [], []).
compress_skip_dups(X, [X|Xs], Rest) :- compress_skip_dups(X, Xs, Rest).
compress_skip_dups(X, [Y|Xs], [Y|Xs]) :- X \== Y.
