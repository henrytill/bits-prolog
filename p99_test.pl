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
             my_length(6, [a,b,c,d,e,f]))
      ]).

main :-
    tests(T),
    run_tests(T).

:- initialization(main).
