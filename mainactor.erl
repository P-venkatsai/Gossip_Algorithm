-module(mainactor).

-export([startGossip/2,registerActors/3,timeTracker/2,stopActors/2]).

startGossip(N,Topology)->
    registerActors(N-1,N,Topology),
    X=rand:uniform(N),
    X1=X rem N,
    statistics(wall_clock),
    register(timeTrackerProcess,spawn(mainactor,timeTracker,[N-1,N])),
    list_to_atom("actor"++integer_to_list(X1)) ! {X1,0,0,-1}.

stopActors(N,ActorCount)->
    if
         N<0->
            exit(whereis(timeTrackerProcess),ok);
         true->
            CurrentID=integer_to_list(N),
            exit(whereis(list_to_atom("actor"++CurrentID)),ok),
            stopActors(N-1,ActorCount)
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



registerActors(N,ActorCount,Topology)->
    if 
        N<0->
            ok;
        true->
            CurrentID=integer_to_list(N),
            register(list_to_atom("actor"++CurrentID),spawn(actorpush,spreadGossip,[0,"recieve message",ActorCount,"",N,1,N,[100,10,1],Topology])),
            registerActors(N-1,ActorCount,Topology)
    end.