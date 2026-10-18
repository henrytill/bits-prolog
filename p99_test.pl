% -*- mode: prolog; -*-
% vim: set ft=prolog:

/** <module> P-99 tests

Tests for the P-99 predicates, portable across GNU Prolog, SWI-Prolog and
Trealla. GNU Prolog includes p99_core.pl directly; the others load it
through the p99 module.

Run main/0 to run every test. It prints one PASSED or FAILED line per test,
plus an ERROR line for a test that raises, and halts with status 0 if every
test passed or 1 otherwise.
*/

:- if(current_prolog_flag(dialect, gprolog)).
:- include('p99_core.pl').
:- else.
:- use_module(p99).
:- endif.

%%  write_test_result(+Result, +Name) is det.
%
%   Print the result of test Name, where Result is passed or failed.

write_test_result(passed, Name) :- write('PASSED: '), write(Name), nl.
write_test_result(failed, Name) :- write('FAILED: '), write(Name), nl.

%%  write_test_error(+Name, +Error) is det.
%
%   Print the exception Error raised by test Name.

write_test_error(Name, Error) :-
    write('ERROR: '), write(Name), write(': '), writeq(Error), nl.

%%  test(+Name, :Body) is semidet.
%
%   Run Body once as test Name and print its result. Succeeds if Body
%   succeeds; fails if Body fails or raises, printing the exception.

test(Name, Body) :-
    ( catch(Body, Error, (write_test_error(Name, Error), fail)) ->
      write_test_result(passed, Name)
    ; write_test_result(failed, Name),
      fail
    ).

%%  tests(-Tests) is det.
%
%   Tests is the list of test(Name, Body) terms to run.

tests([ test('my_last: basic',
             my_last(d, [a,b,c,d])),
        test('my_last: empty',
             \+ my_last(_, [])),
        test('penultimate: basic',
             penultimate(3, [1,2,3,4])),
        test('penultimate: empty list',
             \+ penultimate(_, [])),
        test('penultimate: singleton list',
             \+ penultimate(_, [a])),
        test('element_at: basic lookup',
             element_at(b, [a,b,c], 2)),
        test('element_at: empty list',
             \+ element_at(_, [], 1)),
        test('element_at: out of bounds',
             \+ element_at(_, [a,b], 3)),
        test('my_length: empty list',
             my_length(0, [])),
        test('my_length: singleton list',
             my_length(1, [a])),
        test('my_length: basic',
             my_length(6, [a,b,c,d,e,f])),
        test('my_reverse: empty list',
             my_reverse([], [])),
        test('my_reverse: singleton list',
             my_reverse([a], [a])),
        test('my_reverse: two-element list',
             my_reverse([a,b], [b,a])),
        test('my_reverse: basic',
             my_reverse([f,e,d,c,b,a], [a,b,c,d,e,f])),
        test('is_palindrome: empty list',
             is_palindrome([])),
        test('is_palindrome: non-palindrome is false',
             \+ is_palindrome([a,b,c,d,e,f])),
        test('is_palindrome: basic',
             is_palindrome([x,a,m,a,x])),
        test('my_flatten: basic',
             my_flatten([a, [b, [c, d], e]], [a,b,c,d,e])),
        test('my_append: basic',
             my_append([1,2], [3,4], [1,2,3,4])),
        test('my_append: left empty',
             my_append([], [3,4], [3,4])),
        test('my_append: right empty',
             my_append([1,2], [], [1,2])),
        test('compress: example',
             compress([a,a,a,a,b,c,c,a,a,d,e,e,e,e], [a,b,c,a,d,e]))
      ]).

%%  run_tests(+Tests, +Failed0, -Failed) is det.
%
%   Run every test in Tests, even after one fails. Failed is Failed0 plus
%   the number of tests that failed.

run_tests([], Failed, Failed).
run_tests([test(Name, Body)|Tests], Failed0, Failed) :-
    ( test(Name, Body) ->
      Failed1 = Failed0
    ; Failed1 is Failed0 + 1
    ),
    run_tests(Tests, Failed1, Failed).

%%  test_all is semidet.
%
%   Run every test. Succeeds if they all passed.

test_all :-
    tests(T),
    run_tests(T, 0, Failed),
    Failed =:= 0.

%%  main is det.
%
%   Run every test, then halt with status 0 if they all passed, or 1
%   otherwise.

main :- test_all, halt(0).
main :- halt(1).
