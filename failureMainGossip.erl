-module(failureMainGossip).
-export([startGossip/0, registerActors/2, timer/1]).

startGossip()->
    {ok, N}=io:read("Enter number of actors you want in the network"),
    registerActors(N,N),
    X=rand:uniform(N),
    statistics(wall_clock),
    register(timekeeper,spawn(failureMainGossip,timer,[N-(N/5)])),
    list_to_atom("actor"++integer_to_list(X)) ! {N,gossip}.

timer(N)->
    receive 
        {M,gossip}->
            if
                N==1 ->
                    {_, Time2} = statistics(wall_clock),
                    io:format("Time = ~p~n",[Time2]);
                true ->
                    io:format("recieved ~p ~p ~n",[N,M]),
                    timer(N-1)
            end
    end.

registerActors(N,M)->
    if
        N==0->
            ok;
        N=<(M/5)->
            Id=integer_to_list(N),
            register(list_to_atom("actor"++Id),spawn(failureActorGossip,spreadGossip,[N,0,0,0])),
            registerActors(N-1,M);
        true ->
            Id=integer_to_list(N),
            register(list_to_atom("actor"++Id),spawn(failureActorGossip,spreadGossip,[N,0,0,1])),
            registerActors(N-1,M)
    end.