-module(failureActorGossip).
-export([spreadGossip/4, gossipSend/1]).

gossipSend(N)->
    X=rand:uniform(N),
            list_to_atom("actor"++integer_to_list(X)) ! {N,gossip},
            gossipSend(N).

spreadGossip(N,C,Pid,Y)->
            receive 
                {M,gossip}->
                            if
                                C==10,Y==1->
                                    timekeeper ! {N,gossip},
                                    exit(Pid,ok),
                                    spreadGossip(N,C+1,Pid,Y);
                                C==0, Y==1->
                                    Pid1=spawn(failureActorGossip,gossipSend,[M]),
                                    spreadGossip(N,C+1,Pid1,Y);
                                true->
                                    spreadGossip(N,C+1,Pid,Y)
                            end
                end.