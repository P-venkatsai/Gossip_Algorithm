-module(mainProcess).

-import(lists,[nth/2]). 


-export([startGossip/2,registerActors/3,timeTracker/2,startProcess/0]).

startGossip(N,Topology)->
    io:format("N=~p~n",[N]),
    registerActors(N-1,N,Topology),
    statistics(wall_clock),
    register(timeTrackerProcess,spawn(mainProcess,timeTracker,[N-1,N])),
    X=rand:uniform(N),
    X1=X rem N,
    list_to_atom("actor"++integer_to_list(X1)) ! {X1}.

registerActors(N,ActorCount,Topology)->
    if 
        N<0->
            ok;
        true->
            CurrentID=integer_to_list(N),
            register(list_to_atom("actor"++CurrentID),spawn(actor,spreadGossip,[0,"recieve message",ActorCount,"",N,Topology])),
            registerActors(N-1,ActorCount,Topology)

    end.

timeTracker(CurrentActiveNodes,N)->
    receive
     {}->
        if
            CurrentActiveNodes==0->
                {_, _} = statistics(wall_clock),
                io:format("Process Completed"),
                timeTracker(CurrentActiveNodes-1,N);
            true->
                % io:format("Remaning nodes are ~p ~n",[CurrentActiveNodes]),
                timeTracker(CurrentActiveNodes-1,N)
       end    
    end.  
startProcess()->
    {ok, N}=io:read("Please give input as \"project2 numNodes topology algorithm\" "),
    Inputs=string:split(N," ",all),
    Algorithm=lists:nth(4,Inputs),
    Topo=lists:nth(3,Inputs),
    if
        Algorithm=="PushSum"->
            spawn(mainactor,startGossip,[list_to_integer(lists:nth(2,Inputs)),lists:nth(3,Inputs)]);
        true->
            if 
                Topo=="Line"->
                spawn(gossipMainTwo,startGossip,[list_to_integer(lists:nth(2,Inputs))]);
                true->            
                spawn(mainProcess,startGossip,[list_to_integer(lists:nth(2,Inputs)),lists:nth(3,Inputs)])
            end    
    end.             

    



