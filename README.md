# Distributed Algorithms - Gossip and PushSum

This repository contains the implementation of Gossip and PushSum algorithms using various topologies (Random, 2D, 3D, Line) for a distributed system.

## What is Working

We have successfully implemented all 4 topologies (Random, 2D, 3D, Line) for both PushSum and Gossip algorithms. All of them are working correctly and converging within the expected time scale.

## Gossip Algorithm

A node converges in the Gossip algorithm when it receives the message 10 times. Initially, a node stops spreading the gossip when it reaches convergence. This approach works well for Full Network and 3D topologies. However, in the 2D and Line topologies, when the node count is large enough (>1000), most of the nodes get converged before the message reaches all nodes. This leaves 10-15% of the nodes in a non-converged state.

To solve this problem, we have modified the algorithm to stop spreading gossip only when all nodes have converged. This ensures that all nodes receive the message and converge properly. By using this method, we were able to solve the problem, and the convergence time for Full Network and 3D topologies was not significantly impacted.

### Topology Performance Comparison

- **Full Network**: This topology takes the least amount of time to converge as all the nodes are directly connected.
- **Imperfect 3D Grid**: This topology performs better than 2D as the number of neighboring nodes connected to each current node is higher.
- **2D Grid**: This topology performs better than Line but is not as good as Full Network or 3D Grid, as the number of available nodes is fewer.
- **Line**: This topology takes the most amount of time to converge as the maximum number of connected nodes is only two.

## Convergence Problem in 2D, 3D, Line in Gossip and PushSum

To explain this problem, let's take the example of 2D topologies. Suppose there are 9 nodes arranged in a 3x3 format:
00 01 02
10 11 12
20 21 22

If all the surrounding nodes of node 11 have converged, they stop sending messages. This leaves node 11 unable to converge since it won't receive any more messages. To address this issue, we have implemented a solution where a node checks whether all of its neighboring nodes have converged once every `n` iterations. If all neighbors are converged, the node marks itself as converged since there is no way for it to reach the converged state. Another approach to solve this problem is by sending a message to itself when all neighboring nodes have converged.

## Scale for Gossip

### Normal Scale

![Normal Scale](/path/to/normal_scale_graph.png)

### Log Scale (base 2)

![Log Scale](/path/to/log_scale_graph.png)

Time = 2^(time shown on graph)

## PushSum Algorithm

In the PushSum algorithm, nodes converge when the difference in the S/W ratio doesn't change in three consecutive iterations. When a node receives a message of S and W, it adds S and W to its current S and W values, and then keeps half of the current S and W values while sending the other half as gossip. The main difference between Gossip and PushSum is that Gossip can blindly send messages (spread messages) to all other nodes once it receives the first message, but PushSum cannot do so as the S and W values keep changing. To solve this, we check the S and W values before sending every gossip by exchanging messages with actors.

Unlike Gossip, an actor in PushSum stops spreading the gossip once it converges. This is because in PushSum, the number of received messages required for an actor to converge is much larger compared to Gossip. Additionally, convergence in PushSum depends on the S/W ratio. Therefore, the problem of messages not reaching a small percentage of nodes does not occur.

## Observations

1. As expected, Full Network takes the least time to converge.
2. Line takes the most time.
3. The time taken by 3D is slightly better than 2D.

### Scale Comparison for PushSum

1. Normal Scale

![Normal Scale](/path/to/pushsum_normal_scale_graph.png)

2. Log Scale (base 10)

![Log Scale](/path/to/pushsum_log_scale_graph.png)

Time = 10^(time shown on graph)

## Maximum Network Achieved

### Gossip

1. Line: 10,000 nodes
2. Full Network: 100,000 nodes
3. 3D Grid: 50,000 nodes
4. 2D Grid: 50,000 nodes

### PushSum

1. Line: 1,000 nodes
2. Full Network: 100,000 nodes
3. 3D Grid: 10,000 nodes
4. 2D Grid: 1,000 nodes

*Note: Screenshots of the execution are available in the SS folder for reference.*

## Steps to Execute the Project

1. Compile the following files: actor, mainProcess, mainActor, actorPush, gossipMainTwo, gossipActorTwo.
2. Execute the mainProcess by running the `startProcess()` command.
3. When prompted for input, provide it in the following format: `p numberofnodes topology algorithm`. For example, `"p 1000 3D PushSum"`.

Please refer to the code files for the specific implementations and details of the algorithms and topologies.


