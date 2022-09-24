%% P-99: Ninety-Nine Prolog Problems
%% https://www.ic.unicamp.br/~meidanis/courses/mc336/2009s2/prolog/problemas/

%% P01: Find the last element of a list.
my_last(X,[Y])   :- X = Y.
my_last(X,[_|Y]) :- my_last(X,Y).

%% Local Variables:
%% mode: prolog
%% End:
