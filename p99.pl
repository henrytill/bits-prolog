% -*- mode: prolog; -*-

:- module(p99,
          [ my_last/2,
            penultimate/2,
            element_at/3,
            my_length/2,
            my_reverse/2,
            is_palindrome/1,
            my_flatten/2,
            is_list/1,
            my_append/3,
            compress/2
          ]).

/** <module> P-99: Ninety-Nine Prolog Problems

This module implements solutions to the Ninety-Nine Prolog Problems,
a collection of problems designed to test and improve Prolog programming skills.

@see https://www.ic.unicamp.br/~meidanis/courses/mc336/2009s2/prolog/problemas/
*/

%!  my_last(?X, +List) is semidet.
%
%   P01: Find the last element of a list.

my_last(X, [X]).
my_last(X, [_|Y]) :- my_last(X, Y).

%!  penultimate(?X, +List) is semidet.
%
%   P02: Find the last but one element of a list.

penultimate(X, [X,_]).
penultimate(X, [_|Y]) :- penultimate(X, Y).

%!  element_at(?X, +List, +K) is semidet.
%
%   P03: Find the K'th element of a list (1-based index).

element_at(X, [X|_], 1).
element_at(X, [_|Y], K) :-
    K > 1,
    J is K - 1,
    element_at(X, Y, J).

%!  my_length(?Count, +List) is det.
%
%   P04: Find the number of elements in a list.

my_length(0, []).
my_length(Count, [_|Tail]) :-
    my_length(TailCount, Tail),
    Count is TailCount + 1.

%!  my_reverse(+List, -Reversed) is det.
%
%   P05: Reverse a list.

my_reverse(List, Reversed) :- my_reverse_acc(List, [], Reversed).

my_reverse_acc([], Acc, Acc).
my_reverse_acc([Head|Tail], Acc, Result) :- my_reverse_acc(Tail, [Head|Acc], Result).

%!  is_palindrome(+List) is semidet.
%
%   P06: Find out whether a list is a palindrome.

is_palindrome(List) :- my_reverse(List, List).

%!  my_flatten(+NestedList, -FlatList) is det.
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

%!  is_list(+Term) is semidet.

is_list([]).
is_list([_|_]).

%!  my_append(+List1, +List2, -Result) is det.

my_append([], Ys, Ys).
my_append([X|Xs], Ys, [X|Zs]) :- my_append(Xs, Ys, Zs).

%!  compress(+Uncompressed, -Compressed) is multi.
%
%   P08: Eliminate consecutive duplicates of list elements.

compress(Uncompressed, Compressed) :-
    compress_acc(Uncompressed, [], Acc),
    my_reverse(Acc, Compressed).

compress_acc([], Acc, Acc).
compress_acc([Head|Tail], [Head|Acc], Result) :- compress_acc(Tail, [Head|Acc], Result).
compress_acc([Head|Tail], Acc, Result) :- compress_acc(Tail, [Head|Acc], Result).
