-module(actor).

-export([spreadGossip/6,sendGossip/1,checkForConvergence/5,sendGossipIn2DWay/3,sendGossipIn3DWay/4]).



spreadGossip(N,Task,ActorCount,Pid,SelfID,Topology)->
    if
        Task=="recieve message"->
            receive
                {_}->
                    % io:format("The message reached actor~p~n",[SelfID]),
                    if
                        Topology=="Full" ->
                            Pid1=spawn(actor,sendGossip,[ActorCount]),
                            spreadGossip(N+1,"send and recieve message",ActorCount,Pid1,SelfID,Topology);
                        Topology=="2D"->
                            Pid1=spawn(actor,sendGossipIn2DWay,[ActorCount,SelfID,0]),
                            spreadGossip(N+1,"send and recieve message",ActorCount,Pid1,SelfID,Topology);
                        Topology=="3D"->
                            X=rand:uniform(ActorCount),
                            X1=X rem ActorCount,
                            Pid1=spawn(actor,sendGossipIn3DWay,[ActorCount,SelfID,0,X1]),
                            spreadGossip(N+1,"send and recieve message",ActorCount,Pid1,SelfID,Topology);    
                         true->
                            ok   
                    end
            end;  
       Task=="send and recieve message"->
            receive
                {_}->
                    % io:format("The message reached actor~p~n",[SelfID]),
                    if
                        N==10 ->
                            timeTrackerProcess ! {};
                            %  exit(Pid,ok);
                        true ->
                            ok
                    end,
                    spreadGossip(N+1,"send and recieve message",ActorCount,Pid,SelfID,Topology);
                {ConvergeId,_}->
                    if
                        N<10 ->   
                         ConvergeId ! {0}; 
                        true ->
                          ConvergeId ! {1}
                    end,
                    spreadGossip(N+1,"send and recieve message",ActorCount,Pid,SelfID,Topology)   
            end;           
        true->
            io:format("erripooka~n")
    end.   

sendGossip(ActorCount)->
    X=rand:uniform(ActorCount),
    X1=X rem ActorCount,
    list_to_atom("actor"++integer_to_list(X1)) ! {X1},
    sendGossip(ActorCount). 
sendGossipIn2DWay(ActorCount,SelfID,Count)->
        SquareRoot=math:sqrt(ActorCount),
        FloorOfSqrt=math:floor(SquareRoot),
        IntegerSqrt=round(FloorOfSqrt),
        Row=SelfID div IntegerSqrt,
        Col=SelfID rem IntegerSqrt,
        MaxRows=ActorCount div IntegerSqrt,
        % io:format("SelfId=~p Row=~p Column=~p~n",[SelfID,Row,Col]),
        % Sending message to the nodes present in top row of the current node 
        if
            (Row-1>=0) ->
                % ActorID=round((Row-1)*FloorOfSqrt+Col),
                % list_to_atom("actor"++integer_to_list(ActorID)) ! {ActorCount,S/2,W/2,ActorID},
                if
                    (Col-1>=0) ->
                        ActorID1=round((Row-1)*FloorOfSqrt+Col-1),
                        list_to_atom("actor"++integer_to_list(ActorID1)) ! {ActorID1};
                    true->
                        ok         
                end,
                if
                   Col<FloorOfSqrt  ->
                        ActorID2=round((Row-1)*FloorOfSqrt+Col+1),
                        list_to_atom("actor"++integer_to_list(ActorID2)) ! {ActorID2};
                    true ->
                        ok
                end; 
             true->
                ok   
        end,
        if
            Row<MaxRows ->
                ActorID3=round((Row+1)*FloorOfSqrt+Col),
                ActorID4=round((Row+1)*FloorOfSqrt+Col-1),
                ActorID5=round((Row+1)*FloorOfSqrt+Col+1),
                if
                    ActorID3<ActorCount ->
                        list_to_atom("actor"++integer_to_list(ActorID3)) ! {ActorID3};
                    true ->
                       ok 
                end,
                if
                    (ActorID4<ActorCount) and (Col>0) ->
                        list_to_atom("actor"++integer_to_list(ActorID4)) ! {ActorID4};
                    true->
                        ok         
                end,
                if
                    ActorID5<ActorCount and (Col<FloorOfSqrt-1)  ->
                        list_to_atom("actor"++integer_to_list(ActorID5)) ! {ActorID5};
                    true ->
                        ok
                end; 
             true->
                ok   
        end,
        ActorID6=round((Row)*FloorOfSqrt+Col-1),
        ActorID7=round((Row)*FloorOfSqrt+Col+1),
        if
            Col>0  ->
                list_to_atom("actor"++integer_to_list(ActorID6)) ! {ActorID6};
            true->
                ok
        end,
        if
            ActorID7<ActorCount and (Col<FloorOfSqrt-1)->
                list_to_atom("actor"++integer_to_list(ActorID7)) ! {ActorID7}; 
            true->
                ok
        end,
        % coveregence check
        if 
            Count>0->  
             CovergePid=spawn(actor,checkForConvergence,[ActorCount,SelfID,
             [[-1,-1],[-1,0],[-1,1],[1,-1],[1,0],[1,1],[0,-1],[0,+1]],1,self()]),
             receive
              {Converged}->
                % io:format("Self ~p Coverged~p~n",[SelfID,Converged]),
                if
                    Converged==1 ->
                        exit(CovergePid,ok),
                        timeTrackerProcess ! {},
                        exit(self(),ok);
                    true ->
                        ok
                        % sendGossipIn2DWay(ActorCount,SelfID,0) 
                 end
             end;
            true->
                ok
        end,
        sendGossipIn2DWay(ActorCount,SelfID,Count+1).
sendGossipIn3DWay(ActorCount,SelfID,Count,RandomNeighbour)->
    SquareRoot=math:sqrt(ActorCount),
    FloorOfSqrt=math:floor(SquareRoot),
    IntegerSqrt=round(FloorOfSqrt),
    Row=SelfID div IntegerSqrt,
    Col=SelfID rem IntegerSqrt,
    MaxRows=ActorCount div IntegerSqrt,
    % io:format("SelfId=~p Row=~p Column=~p~n",[SelfID,Row,Col]),
    % Sending message to the nodes present in top row of the current node 
    if
        (Row-1>=0) ->
            % ActorID=round((Row-1)*FloorOfSqrt+Col),
            % list_to_atom("actor"++integer_to_list(ActorID)) ! {ActorCount,S/2,W/2,ActorID},
            if
                (Col-1>=0) ->
                    ActorID1=round((Row-1)*FloorOfSqrt+Col-1),
                    list_to_atom("actor"++integer_to_list(ActorID1)) ! {ActorID1};
                true->
                    ok         
            end,
            if
                Col<FloorOfSqrt  ->
                    ActorID2=round((Row-1)*FloorOfSqrt+Col+1),
                    list_to_atom("actor"++integer_to_list(ActorID2)) ! {ActorID2};
                true ->
                    ok
            end; 
            true->
            ok   
    end,
    if
        Row<MaxRows ->
            ActorID3=round((Row+1)*FloorOfSqrt+Col),
            ActorID4=round((Row+1)*FloorOfSqrt+Col-1),
            ActorID5=round((Row+1)*FloorOfSqrt+Col+1),
            if
                ActorID3<ActorCount ->
                    list_to_atom("actor"++integer_to_list(ActorID3)) ! {ActorID3};
                true ->
                    ok 
            end,
            if
                (ActorID4<ActorCount) and (Col>0) ->
                    list_to_atom("actor"++integer_to_list(ActorID4)) ! {ActorID4};
                true->
                    ok         
            end,
            if
                ActorID5<ActorCount and (Col<FloorOfSqrt-1)  ->
                    list_to_atom("actor"++integer_to_list(ActorID5)) ! {ActorID5};
                true ->
                    ok
            end; 
            true->
            ok   
    end,
    ActorID6=round((Row)*FloorOfSqrt+Col-1),
    ActorID7=round((Row)*FloorOfSqrt+Col+1),
    if
        Col>0  ->
            list_to_atom("actor"++integer_to_list(ActorID6)) ! {ActorID6};
        true->
            ok
    end,
    if
        ActorID7<ActorCount and (Col<FloorOfSqrt-1)->
            list_to_atom("actor"++integer_to_list(ActorID7)) ! {ActorID7}; 
        true->
            ok
    end,
    % X=rand:uniform(ActorCount),
    % X1=X rem ActorCount,
    list_to_atom("actor"++integer_to_list(RandomNeighbour)) ! {RandomNeighbour},
    if 
            Count>0->  
             CovergePid=spawn(actor,checkForConvergence,[ActorCount,SelfID,
             [[-1,-1],[-1,0],[-1,1],[1,-1],[1,0],[1,1],[0,-1],[0,+1]],1,self()]),
             receive
              {Converged}->
                % io:format("Self ~p Coverged~p~n",[SelfID,Converged]),
                if
                    Converged==1 ->
                        exit(CovergePid,ok),
                        timeTrackerProcess ! {},
                        exit(self(),ok);
                    true ->
                        sendGossipIn2DWay(ActorCount,SelfID,0) 
                 end
             end;
            true->
                ok
        end,
    sendGossipIn3DWay(ActorCount,SelfID,Count+1,RandomNeighbour).
        
    
        


checkForConvergence(ActorCount,SelfID,Values,Counter,Pid)->
    SquareRoot=math:sqrt(ActorCount),
    FloorOfSqrt=math:floor(SquareRoot),
    IntegerSqrt=round(FloorOfSqrt),
    Row=SelfID div IntegerSqrt,
    Col=SelfID rem IntegerSqrt,
    MaxRows=ActorCount div IntegerSqrt,
    CurrentValues=lists:nth(Counter,Values),
    CurrentRow=Row+lists:nth(1,CurrentValues),
    CurrentColumn=Col+lists:nth(2,CurrentValues),
    CurrentActorID=round(CurrentRow*FloorOfSqrt+CurrentColumn),
    % io:format("Current=~p and SelfId=~p Row=~p Col=~p Counter~p  ~n",[CurrentActorID,SelfID,CurrentRow,CurrentColumn,Counter]),
    if
            (CurrentRow>=0) and (CurrentRow<MaxRows)
            and (CurrentColumn>=0) and (CurrentColumn<FloorOfSqrt)  ->
            % io:format(list_to_atom("actor"++integer_to_list(CurrentActorID))),    
            list_to_atom("actor"++integer_to_list(CurrentActorID)) ! {self(),"hi"},
            receive
                {Convereged}->
                    % io:format("message came back~n"),
                    if
                        Convereged==0 ->
                            Pid !{0};
                        Counter==8->
                            Pid !{1};
                        true ->
                            checkForConvergence(ActorCount,SelfID,Values,Counter+1,Pid)
                    end
            end;     
        true ->
            if
                Counter==8->
                    % io:format("counter reached 8 ~w~n",[Pid]),
                    Pid !{1};
                true ->
                    checkForConvergence(ActorCount,SelfID,Values,Counter+1,Pid) 
            end
            
    end.
    



    


 