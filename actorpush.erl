-module(actorpush).

-import(lists,[nth/2]). 

-export([spreadGossip/9,sendGossip/4,sendGossipIn2DWay/5,sendGossipIn3DWay/6,checkForConvergence/5,sendGossipLine/5,checkConvergenceLine/5]).



spreadGossip(N,Task,ActorCount,Pid,S,W,SelfID,ThreeIte,Topology)->
    if
        Task=="recieve message"->
            receive
                {_,Rs,Rw,_}->
                  if  
                    Topology=="Full" ->
                        Pid1=spawn(actorpush,sendGossip,[ActorCount,S+Rs,W+Rw,SelfID]),
                        spreadGossip(N+1,"send and recieve message",ActorCount,Pid1,S+Rs,W+Rw,SelfID,[0,0,S+Rs/W+Rw],Topology);
                    Topology=="2D"->
                        Pid1=spawn(actorpush,sendGossipIn2DWay,[ActorCount,S+Rs,W+Rw,SelfID,0]),
                        spreadGossip(N+1,"send and recieve message",ActorCount,Pid1,S+Rs,W+Rw,SelfID,[0,0,S+Rs/W+Rw],Topology);
                    Topology=="3D"->
                        X=rand:uniform(ActorCount),
                        X1=X rem ActorCount,
                        Pid1=spawn(actorpush,sendGossipIn3DWay,[ActorCount,S+Rs,W+Rw,SelfID,0,X1]),
                        spreadGossip(N+1,"send and recieve message",ActorCount,Pid1,S+Rs,W+Rw,SelfID,[0,0,S+Rs/W+Rw],Topology);
                    % io:format("The message reached actor~p  ~p ~p ~p ~n",[ActorID,Rs,Rw,SelfID1]),
                    true->
                        Pid1=spawn(actorpush,sendGossipLine,[ActorCount,S+Rs,W+Rw,SelfID,0]),
                        spreadGossip(N+1,"send and recieve message",ActorCount,Pid1,S+Rs,W+Rw,SelfID,[0,0,S+Rs/W+Rw],Topology)
                   end      
            end;  
       Task=="send and recieve message"->
            receive
                {_,Rs,Rw,_}->
                    X=S+Rs,
                    Y=W+Rw,
                    A=list_to_float(float_to_list(X,[{decimals,12}])),
                    B=list_to_float(float_to_list(Y,[{decimals,12}])),
                    % io:format("The message reached actor~p ~p ~p ~p ~p from ~p ~n",[ActorID,Rs,Rw,X,Y,SelfID1]),
                    NewRatio=A/B,
                    L2=lists:nth(2,ThreeIte),
                    L3=lists:nth(3,ThreeIte),
                    NewThreeIt=[L2,L3,NewRatio],
                    SortedNewThreeIt=lists:sort(NewThreeIt),
                    Diff=lists:nth(3,SortedNewThreeIt)-lists:nth(1,SortedNewThreeIt),
                    if
                        Diff<0.001->
                            % io:format("The actor~p stopped propagating the rumour~n amd s=~p and w=~p ",[ActorID,S,W]),
                            exit(Pid,ok),
                            timeTrackerProcess ! {},
                            spreadGossip(N+1,"Just Recieve",ActorCount,Pid,A,B,SelfID,NewThreeIt,Topology); 
                        true ->
                            spreadGossip(N+1,"send and recieve message",ActorCount,Pid,A,B,SelfID,NewThreeIt,Topology)   
                    end;
                {ConvergeId}->
                    ConvergeId ! {0},
                    % io:format("in cycle ~p~n",[SelfID]),
                    spreadGossip(N,Task,ActorCount,Pid,S,W,SelfID,ThreeIte,Topology);
                {}->
                    Pid !{S,W},
                    spreadGossip(N,"send and recieve message",ActorCount,Pid,
                    list_to_float(float_to_list(S/2,[{decimals,10}])),list_to_float(float_to_list(W/2,[{decimals,10}])),
                    SelfID,ThreeIte,Topology)
            end;   
           true->
            receive
                {_,_,_,_}->
                    spreadGossip(N,Task,ActorCount,Pid,S,W,SelfID,ThreeIte,Topology);
                {ConvergeId}->
                    ConvergeId ! {1},
                    % io:format("in cycle ~p~n",[SelfID]),
                    spreadGossip(N,Task,ActorCount,Pid,S,W,SelfID,ThreeIte,Topology)     
            end
    end.  

sendGossip(ActorCount,S,W,SelfID)->
    X=rand:uniform(ActorCount),
    X1=X rem ActorCount,
    list_to_atom("actor"++integer_to_list(X1)) ! {ActorCount,S/2,W/2,SelfID},
    X2=rand:uniform(ActorCount),
    X3=X2 rem ActorCount,
    list_to_atom("actor"++integer_to_list(X3)) ! {ActorCount,S/2,W/2,SelfID},
    list_to_atom("actor"++integer_to_list(SelfID)) ! {},
    receive
        {Rs,RW}->
            sendGossip(ActorCount,Rs,RW,SelfID)
    end.  
sendGossipIn2DWay(ActorCount,S,W,SelfID,Count)->
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
            ActorID=round((Row-1)*FloorOfSqrt+Col),
            list_to_atom("actor"++integer_to_list(ActorID)) ! {ActorCount,list_to_float(float_to_list(S/2,[{decimals,12}])),list_to_float(float_to_list(W/2,[{decimals,12}])),ActorID},
            if
                (Col-1>=0) ->
                    ActorID1=round((Row-1)*FloorOfSqrt+Col-1),
                    list_to_atom("actor"++integer_to_list(ActorID1)) ! {ActorID1,list_to_float(float_to_list(S/2,[{decimals,12}])),list_to_float(float_to_list(W/2,[{decimals,12}])),SelfID};
                true->
                    ok         
            end,
            if
               Col<FloorOfSqrt  ->
                    ActorID2=round((Row-1)*FloorOfSqrt+Col+1),
                    list_to_atom("actor"++integer_to_list(ActorID2)) ! {ActorID2,list_to_float(float_to_list(S/2,[{decimals,12}])),list_to_float(float_to_list(W/2,[{decimals,12}])),SelfID};
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
                    list_to_atom("actor"++integer_to_list(ActorID3)) ! {ActorID3,list_to_float(float_to_list(S/2,[{decimals,10}])),list_to_float(float_to_list(W/2,[{decimals,10}])),SelfID};
                true ->
                   ok 
            end,
            if
                (ActorID4<ActorCount) and (Col>0) ->
                    list_to_atom("actor"++integer_to_list(ActorID4)) ! {ActorID4,list_to_float(float_to_list(S/2,[{decimals,10}])),list_to_float(float_to_list(W/2,[{decimals,10}])),SelfID};
                true->
                    ok         
            end,
            if
                ActorID5<ActorCount and (Col<FloorOfSqrt-1)  ->
                    list_to_atom("actor"++integer_to_list(ActorID5)) ! {ActorID5,list_to_float(float_to_list(S/2,[{decimals,10}])),list_to_float(float_to_list(W/2,[{decimals,10}])),SelfID};
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
            list_to_atom("actor"++integer_to_list(ActorID6)) ! {ActorID6,list_to_float(float_to_list(S/2,[{decimals,10}])),list_to_float(float_to_list(W/2,[{decimals,10}])),SelfID};
        true->
            ok
    end,
    if
        ActorID7<ActorCount and (Col<FloorOfSqrt-1)->
            list_to_atom("actor"++integer_to_list(ActorID7)) ! {ActorID7,list_to_float(float_to_list(S/2,[{decimals,10}])),list_to_float(float_to_list(W/2,[{decimals,10}])),SelfID}; 
        true->
            ok
    end,
    % coveregence check
    if 
        Count>100->  
         CovergePid=spawn(actorpush,checkForConvergence,[ActorCount,SelfID,
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
                    % sendGossipIn2DWay(ActorCount,S,W,SelfID,0) 
             end
         end;
        true->
            ok
    end,
    list_to_atom("actor"++integer_to_list(SelfID)) ! {},
    receive
        {Rs,RW}->
            if
                (Rs==S) and (RW==W)->
                    sendGossipIn2DWay(ActorCount,Rs,RW,SelfID,Count+1);
                 true->
                    sendGossipIn2DWay(ActorCount,Rs,RW,SelfID,0)
            end      
    end.
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
            list_to_atom("actor"++integer_to_list(CurrentActorID)) ! {self()},
            receive
                {Convereged}->
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
    
sendGossipLine(ActorCount,S,W,SelfID,Count)->
   PrecActor=SelfID-1,
   SucActor=SelfID+1,
   if
    (PrecActor>-1) and (PrecActor<ActorCount)->
        list_to_atom("actor"++integer_to_list(PrecActor)) ! {ActorCount,S/2,W/2,SelfID};
     true->
        ok
   end,
   if
    (SucActor>-1) and (SucActor<ActorCount)->
        list_to_atom("actor"++integer_to_list(SucActor)) ! {ActorCount,S/2,W/2,SelfID};
     true->
        ok
   end,
   if 
        Count>0->  
         CovergePid=spawn(actorpush,checkConvergenceLine,[ActorCount,SelfID,
         [-1,1],1,self()]),
         receive
          {Converged}->
            % io:format("Self ~p Coverged~p~n",[SelfID,Converged]),
            if
                Converged==1 ->
                    exit(CovergePid,ok),
                    timeTrackerProcess ! {},
                    exit(self(),ok);
                true ->
                    sendGossipLine(ActorCount,S,W,SelfID,0) 
             end
         end;
        true->
            ok
    end,
   list_to_atom("actor"++integer_to_list(SelfID)) ! {},
   receive
            {Rs,RW}->
            if
                (Rs==S) and (RW==W)->
                    sendGossipLine(ActorCount,Rs,Rs,SelfID,Count+1);
                 true->
                    sendGossipLine(ActorCount,Rs,Rs,SelfID,Count)
            end
    end. 

checkConvergenceLine(Actorcount,SelfID,List,Counter,Pid)->
    CurrentID=SelfID+lists:nth(Counter,List),
    if
        (CurrentID>-1) and (CurrentID<Actorcount) ->
            list_to_atom("actor"++integer_to_list(CurrentID)) ! {self()},
            receive
                {Convereged}->
                    if
                        Convereged==0 ->
                            Pid !{0};
                        Counter==2->
                            Pid !{1};
                        true ->
                            checkConvergenceLine(Actorcount,SelfID,List,Counter+1,Pid)
                    end
            end; 
        true ->
            if
            Counter==2->
                % io:format("counter reached 8 ~w~n",[Pid]),
                Pid !{1};
            true ->
                checkConvergenceLine(Actorcount,SelfID,List,Counter+1,Pid) 
        end
    end.
    
  
sendGossipIn3DWay(ActorCount,S,W,SelfID,Count,RandomNeighbour)->
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
                        list_to_atom("actor"++integer_to_list(ActorID1)) ! {ActorID1,S/2,W/2,SelfID};
                    true->
                        ok         
                end,
                if
                   Col<FloorOfSqrt  ->
                        ActorID2=round((Row-1)*FloorOfSqrt+Col+1),
                        list_to_atom("actor"++integer_to_list(ActorID2)) ! {ActorID2,S/2,W/2,SelfID};
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
                        list_to_atom("actor"++integer_to_list(ActorID3)) ! {ActorID3,S/2,W/2,SelfID};
                    true ->
                       ok 
                end,
                if
                    ActorID4<ActorCount ->
                        list_to_atom("actor"++integer_to_list(ActorID4)) ! {ActorID4,S/2,W/2,SelfID};
                    true->
                        ok         
                end,
                if
                    ActorID5<ActorCount  ->
                        list_to_atom("actor"++integer_to_list(ActorID5)) ! {ActorID5,S/2,W/2,SelfID};
                    true ->
                        ok
                end; 
             true->
                ok   
        end,
        ActorID6=round((Row)*FloorOfSqrt+Col-1),
        ActorID7=round((Row)*FloorOfSqrt+Col+1),
        if
            Col>0 ->
                list_to_atom("actor"++integer_to_list(ActorID6)) ! {ActorID6,S/2,W/2,SelfID};
            true->
                ok
        end,
        if
            ActorID7<ActorCount->
                list_to_atom("actor"++integer_to_list(ActorID7)) ! {ActorID7,S/2,W/2,SelfID}; 
            true->
                ok
        end,
        if 
        Count>1000->  
         CovergePid=spawn(actorpush,checkForConvergence,[ActorCount,SelfID,
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
                    sendGossipIn3DWay(ActorCount,S,W,SelfID,0,RandomNeighbour) 
             end
         end;
        true->
            ok
       end,
        list_to_atom("actor"++integer_to_list(RandomNeighbour)) ! {ActorCount,S/2,W/2,SelfID},
        list_to_atom("actor"++integer_to_list(SelfID)) ! {},
        receive
            {Rs,RW}->
            if
                (Rs==S) and (RW==W)->
                    sendGossipIn3DWay(ActorCount,Rs,RW,SelfID,Count+1,RandomNeighbour);
                 true->
                    sendGossipIn3DWay(ActorCount,Rs,RW,SelfID,0,RandomNeighbour)
            end
        end.    
                








