%! P-99: Ninety-Nine Prolog Problems
%  @see https://www.ic.unicamp.br/~meidanis/courses/mc336/2009s2/prolog/problemas/

%% P01: Find the last element of a list.
my_last(X,[Y])   :- X = Y.
my_last(X,[_|Y]) :- my_last(X,Y).

%?- my_last(X,[1,2,3,4]).
%@ X = 4 .

%?- my_last(X,[a,b,c,d]).
%@ X = d .
