-module(gossipActorTwo).
-export([gossipSend/2, spreadGossip/3]).

gossipSend(N,M)->
    if
        N==1 ->
            list_to_atom("actor"++integer_to_list(N+1)) ! {check, self()},
            receive
                {y}->
                    list_to_atom("actor"++integer_to_list(N+1)) ! {M,gossip};
                {n}->
                    list_to_atom("actor"++integer_to_list(N)) ! {M,gossip}
            end;

        N==M->
            list_to_atom("actor"++integer_to_list(N-1)) ! {check,self()},
            receive
                {y}->
                    list_to_atom("actor"++integer_to_list(N-1)) ! {M,gossip};
                {n}->
                    list_to_atom("actor"++integer_to_list(N)) ! {M,gossip}
            end;

        true ->
            X=rand:uniform(2),
            if
                X==1 ->
                    list_to_atom("actor"++integer_to_list(N-1)) ! {check,self()},
                    receive
                        {y}->
                            list_to_atom("actor"++integer_to_list(N-1)) ! {M,gossip};
                        {n}->
                            list_to_atom("actor"++integer_to_list(N+1)) ! {check,self()},
                            receive
                                {y}->
                                    list_to_atom("actor"++integer_to_list(N+1)) ! {M,gossip};
                                {n}->
                                    list_to_atom("actor"++integer_to_list(N)) ! {M,gossip}
                            end
                    end;
                X==2->
                    list_to_atom("actor"++integer_to_list(N+1)) ! {check,self()},
                    receive
                        {y}->
                            list_to_atom("actor"++integer_to_list(N+1)) ! {M,gossip};
                        {n}->
                            list_to_atom("actor"++integer_to_list(N-1)) ! {check,self()},
                            receive
                                {y}->
                                    list_to_atom("actor"++integer_to_list(N-1)) ! {M,gossip};
                                {n}->
                                    list_to_atom("actor"++integer_to_list(N)) ! {M,gossip}
                            end
                    end;
                true ->
                    ok
            end
    end,
    gossipSend(N,M).

spreadGossip(N,C,Pid)->
    receive
        {M,gossip}->
                if
                    C==100 ->
                        timeKeeper ! {gossip},
                        exit(Pid,ok),
                        spreadGossip(N,C+1,Pid);
                    C==0 ->
                        Pid1=spawn(gossipActorTwo,gossipSend,[N,M]),
                        spreadGossip(N,C+1,Pid1);
                    true ->
                        spreadGossip(N,C+1,Pid)
                end;
        {check, P}-> 
            if
                C<10 ->
                    P!{y},
                    spreadGossip(N,C,Pid);
                true ->
                    P!{n},
                    spreadGossip(N,C,Pid)
            end
    end.