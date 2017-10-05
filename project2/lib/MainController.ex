defmodule MainController do
use GenServer
# entry point to the code. Read command line arguments and invoke the right things here.
  # Entry point to the code. 
  def main(args) do
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

  # Start gen server
   start_link(map, numNodes)

   GenServer.cast(:main_server, {:initiateProtocol, algorithm})

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
  
  def start_link(map, numNodes) do
  GenServer.start_link(MainController, [map, numNodes, 0, DateTime.utc_now], name: :main_server)
  end

    def init(map, numNodes, count, starttime) do
      {:ok, {map, numNodes, count, starttime}}
  end

  def handle_cast({:iDied}, state) do
    [map, numNodes, count, starttime] = state
    count = count + 1
    if count >= Float.floor(0.90*numNodes) do
        diff =  DateTime.diff(DateTime.utc_now, starttime, :millisecond)
        IO.puts "Most nodes have died. Shutting down the protocol.. Convergence took #{diff} milliseconds."
        Process.exit(self(), :shutdown)
    else 
    {:noreply, [map, numNodes, count, starttime]}
    end
  end

    def handle_cast({:initiateProtocol, algorithm}, state) do
      [map, numNodes, count, starttime] = state
      {{_, pid}, firstNode} = Enum.at(map, Enum.random(0..(numNodes-1)))
      #  selectedNeighborNode = String.to_atom("workernode"<>Integer.to_string(firstNode)<>"@"<>GossipNode.findIP())
      selectedNeighborServer = String.to_atom("workerserver"<>Integer.to_string(firstNode))
      a = DateTime.utc_now
      if algorithm == "pushsum" do
      GenServer.cast(selectedNeighborServer, {:infectPushSum, 0, 0})
      else
      GenServer.cast(selectedNeighborServer, {:infect})
      end
      {:noreply, [map, numNodes, count, a]}
  end

  def handle_call({:killMain}, _from, state) do
    IO.puts "Most nodes have died. Shutting down the protocol..."
    {:stop, :normal, state}
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
