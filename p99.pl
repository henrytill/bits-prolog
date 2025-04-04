%! P-99: Ninety-Nine Prolog Problems
%  @see https://www.ic.unicamp.br/~meidanis/courses/mc336/2009s2/prolog/problemas/

:- module(p99, [my_last/2, penultimate/2, element_at/3, my_length/2]).

%% P01: Find the last element of a list.
my_last(X, [X]).
my_last(X, [_|Y]) :- my_last(X, Y).

%% P02: Find the last but one element of a list.
penultimate(X, [X,_]).
penultimate(X, [_|Y]) :- penultimate(X, Y).

%% P03: Find the K'th element of a list.
element_at(X, [X|_], 1).
element_at(X, [_|Y], K) :-
    K > 1,
    J is K - 1,
    element_at(X, Y, J).

%% P04: Find the number of elements of a list.
my_length(0, []).
my_length(Count, [_|Tail]) :-
    my_length(TailCount, Tail),
    Count is TailCount + 1.
