#!/usr/bin/env escript
%% -*- erlang -*-
%%! -pa ./ebin -boot start_sasl -sasl sasl_error_logger false

main(_) ->
    etap:plan(unknown),
    crypto:start(),
    {Host, User, Pass, Name} = {"localhost", "test", "test", "testdatabase"},
    {ok, Pid} = mysql:start_link(test1, "localhost", 3306, User, Pass, Name, 'utf8'),

    mysql:prepare(delete_foo, <<"DELETE FROM foo WHERE id = ?">>),
    mysql:prepare(select_foo, <<"SELECT * FROM foo WHERE id = ?">>),
    mysql:prepare(drop_foo, <<"DROP TABLE foo">>),

    (fun() ->
        {updated, MySQLRes} = mysql:execute(test1, <<"CREATE TABLE foo (id int(11));">>, [], 8000),
        etap:is(mysql:get_result_affected_rows(MySQLRes), 0, "Creating table"),
        ok
    end)(),
    
    (fun() ->
        lists:foreach(
            fun(Data) ->
                {updated, MySQLRes} = mysql:execute(test1, <<"INSERT INTO foo SET id = ?">>, [Data], 8000),
                etap:is(mysql:get_result_affected_rows(MySQLRes), 1, "Creating row"),
                ok
            end,
            lists:seq(1, 3)
        ),
        ok
    end)(),
    
    (fun() ->
        {data, MySQLRes} = mysql:fetch(test1, <<"SELECT * FROM foo WHERE id = 1">>),
        etap:is(mysql:get_result_rows(MySQLRes), [[1]], "Selecting row"),
        ok
    end)(),

    (fun() ->
        {updated, MySQLRes} = mysql:execute(test1, drop_foo, [], 8000),
        etap:is(mysql:get_result_affected_rows(MySQLRes), 0, "Dropping table"),
        ok
    end)(),

    etap:end_tests().
