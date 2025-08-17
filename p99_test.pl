%% -*- mode: prolog; -*-

:- use_module(p99).

test(Name, Body) :-
    ( call(Body) ->
      format('✓ PASSED: ~w~n', [Name])
    ; format('✗ FAILED: ~w~n', [Name]),
      fail
    ).

run_tests(Tests) :-
    ( foreach(member(Test, Tests), call(Test)) ->
      halt(0)
    ; halt(1)
    ).

tests([ test("my_last: basic",
             my_last(d, [a,b,c,d])),
        test("my_last: empty",
             \+ my_last(_, [])),
        test("penultimate: basic",
             penultimate(3, [1,2,3,4])),
        test("penultimate: empty list",
             \+ penultimate(_, [])),
        test("penultimate: singleton list",
             \+ penultimate(_, [a])),
        test("element_at: basic lookup",
             element_at(b, [a,b,c], 2)),
        test("element_at: empty list",
             \+ element_at(_, [], 1)),
        test("element_at: out of bounds",
             \+ element_at(_, [a,b], 3)),
        test("my_length: empty list",
             my_length(0, [])),
        test("my_length: singleton list",
             my_length(1, [a])),
        test("my_length: basic",
             my_length(6, [a,b,c,d,e,f])),
        test("my_reverse: empty list",
             my_reverse([], [])),
        test("my_reverse: singleton list",
             my_reverse([a], [a])),
        test("my_reverse: two-element list",
             my_reverse([a,b], [b,a])),
        test("my_reverse: basic",
             my_reverse([f,e,d,c,b,a], [a,b,c,d,e,f])),
        test("is_palindrome: empty list",
             is_palindrome([])),
        test("is_palindrome: non-palindrome is false",
             \+ is_palindrome([a,b,c,d,e,f])),
        test("is_palindrome: basic",
             is_palindrome([x,a,m,a,x])),
        test("my_flatten: basic",
             my_flatten([a, [b, [c, d], e]], [a,b,c,d,e])),
        test("is_list: empty list",
             is_list([])),
        test("is_list: single-element list",
             is_list([a])),
        test("is_list: basic",
             is_list([a,b,c,d,e])),
        test("is_list: non-list",
             \+ is_list(1)),
        test("my_append: basic",
             my_append([1,2], [3,4], [1,2,3,4])),
        test("my_append: left empty",
             my_append([], [3,4], [3,4])),
        test("my_append: right empty",
             my_append([1,2], [], [1,2]))
      ]).

main :-
    tests(T),
    run_tests(T).

:- initialization(main).
