-module(gossipMainTwo).
-export([startGossip/1, registerActors/2, timer/1]).

startGossip(N)->
    registerActors(N,N),
    X=rand:uniform(N),
    statistics(wall_clock),
    register(timeKeeper,spawn(gossipMainTwo,timer,[N])),
    list_to_atom("actor"++integer_to_list(X)) ! {N,gossip}.

timer(N)->
    receive
        {gossip}->
            if
                N==1 ->
                    io:format("received in timer ~p~n",[N]),
                    {_, Time2} = statistics(wall_clock),
                    io:format("Time = ~p~n",[Time2]);
                true ->
                    % io:format("received in timer  ~p~n",[N]),
                    timer(N-1)
            end
    end.

registerActors(N,M)->
    if
        N==0 ->
            ok;
        true ->
            Id=integer_to_list(N),
            register(list_to_atom("actor"++Id),spawn(gossipActorTwo,spreadGossip,[N,0,0])),
            registerActors(N-1,M)
    end.