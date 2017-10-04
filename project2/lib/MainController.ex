defmodule MainController do
use GenServer
# entry point to the code. Read command line arguments and invoke the right things here.
  # Entry point to the code. 
  def main(args) do
   IO.inspect(args)
   [nNodes,topology,algorithm] = args
   numNodes=nNodes|>String.to_integer()

   if topology == "2D" or topology == "imp2D" do
       #Readjust the number of nodes.
       sqrt = :math.sqrt(numNodes)|> Float.ceil|> round
       numNodes = sqrt*sqrt
   end
 
   map=%{}
   nodeList=Enum.to_list(1..numNodes)
   map = loadGenservers(nodeList, topology, numNodes, algorithm, %{})

   IO.inspect map
   {{_, pid}, firstNode} = IO.inspect Enum.at(map, Enum.random(0..(numNodes-1)))
   selectedNeighborNode = String.to_atom("workernode"<>Integer.to_string(firstNode)<>"@"<>GossipNode.findIP())
   selectedNeighborServer = String.to_atom("workerserver"<>Integer.to_string(firstNode))
   
    if algorithm == "pushsum" do
      GenServer.cast(selectedNeighborServer, {:infectPushSum, 0, 0})
    else
      GenServer.cast(selectedNeighborServer, {:infect})
    end
   :timer.sleep(:infinity)


   #Gossip.Supervisor.start_link(numNodes,topology,algorithm)
  end
  def loadGenservers([nodeId|nodeList], topology, numNodes, algorithm, map) do
   pid = GossipNode.start_link(nodeId, topology, numNodes, algorithm)
   map = Map.put(map,pid,nodeId)
   loadGenservers(nodeList, topology, numNodes, algorithm, map)
  end

def loadGenservers([], topology, numNodes, algorithm, map) do
map
end
  def addNode(map,pid,nodeId,numNodes) do
   if nodeId==numNodes do
    map
   else
   Map.put(map,pid,nodeId)
   addNode(map,pid,nodeId,numNodes)
   end
  end
  
end

# defmodule Gossip.Supervisor do
#     use Supervisor

#     def start_link(numNodes,topology,algorithm) do

#     if topology == "2D" or topology == "imp2D" do
#        #Readjust the number of nodes.
#        sqrt = :math.sqrt(numNodes)|> Float.ceil|> round
#        numNodes = sqrt*sqrt
#     end
#     children = Enum.map(Enum.to_list(1..numNodes), fn(nodeId) ->
#       worker(GossipNode, [nodeId, topology, numNodes, algorithm], [id: nodeId, restart: :permanent])
#     end)

#     Supervisor.start_link(children,strategy: :one_for_one, name: :super)
#     IO.puts "Done creating agents. Infecting a random node..."

#     childList = Supervisor.which_children(:super)
#     {firstNode, pid, _, _} = IO.inspect Enum.at(childList, Enum.random(0..(numNodes-1)))
#     selectedNeighborNode = String.to_atom("workernode"<>Integer.to_string(firstNode)<>"@"<>GossipNode.findIP())
#     selectedNeighborServer = String.to_atom("workerserver"<>Integer.to_string(firstNode))

#     # if algorithm == "pushsum" do
#     #   GenServer.cast({selectedNeighborServer, selectedNeighborNode}, {:infect, nodeId, 1})
#     # else
#     GenServer.call(selectedNeighborServer, {:infect})
#     :timer.sleep(:infinity)
#     # end
#   end
# end
