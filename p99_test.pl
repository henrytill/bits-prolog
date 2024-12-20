:- use_module(p99).

test(Name, Body) :-
    format('Running test: ~w~n', [Name]),
    ( call(Body) ->
      format('✓ ~w passed~n', [Name])
    ; format('✗ ~w failed~n', [Name]),
      fail
    ).

run_tests(Tests) :-
    ( foreach(member(Test, Tests), call(Test)) ->
      halt(0)
    ; halt(1)
    ).

test_my_last_basic :-
    test("my_last: basic",
         (my_last(d, [a,b,c,d]))).

test_my_last_empty :-
    test("my_last: empty",
         (\+ my_last(_, []))).

test_penultimate_basic :-
    test("penultimate: basic",
         (penultimate(3, [1,2,3,4]))).

test_penultimate_empty :-
    test("penultimate: empty list",
         (\+ penultimate(_, []))).

test_penultimate_singleton :-
    test("penultimate: singleton list",
         (\+ penultimate(_, [a]))).

test_element_at_basic_lookup :-
    test("element_at: basic lookup",
         (element_at(b, [a,b,c], 2))).

test_element_at_empty :-
    test("element_at: empty list",
         (\+ element_at(_, [], 1))).

test_element_at_bounds :-
    test("element_at: out of bounds",
         (\+ element_at(_, [a,b], 3))).

main :-
    run_tests([ test_my_last_basic,
                test_my_last_empty,
                test_penultimate_basic,
                test_penultimate_empty,
                test_penultimate_singleton,
                test_element_at_basic_lookup,
                test_element_at_empty,
                test_element_at_bounds ]).

:- initialization(main).
