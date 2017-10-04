defmodule MainController do

# entry point to the code. Read command line arguments and invoke the right things here.
  # Entry point to the code. 
  def main(args) do
   IO.inspect(args)
   [nNodes,topology,algorithm] = args
   numNodes=nNodes|>String.to_integer()

   Gossip.Supervisor.start_link(numNodes,topology,algorithm)
  end
end

defmodule Gossip.Supervisor do
    use Supervisor

    def start_link(numNodes,topology,algorithm) do

    if topology == "2D" or topology == "imp2D" do
       #Readjust the number of nodes.
       sqrt = :math.sqrt(numNodes)|> Float.ceil|> round
       numNodes = sqrt*sqrt
    end
    children = Enum.map(Enum.to_list(1..numNodes), fn(nodeId) ->
      worker(GossipNode, [nodeId, topology, numNodes, algorithm], [id: nodeId, restart: :permanent])
    end)

    Supervisor.start_link(children,strategy: :one_for_one, name: :super)
    IO.puts "Done creating agents. Infecting a random node..."

    childList = Supervisor.which_children(:super)
    {firstNode, pid, _, _} = IO.inspect Enum.at(childList, Enum.random(0..(numNodes-1)))
    selectedNeighborNode = String.to_atom("workernode"<>Integer.to_string(firstNode)<>"@"<>GossipNode.findIP())
    selectedNeighborServer = String.to_atom("workerserver"<>Integer.to_string(firstNode))

    if algorithm == "pushsum" do
      GenServer.cast(selectedNeighborServer, {:infectPushSum, 0, 0})
    else
      GenServer.cast(selectedNeighborServer, {:infect})
    end
    :timer.sleep(:infinity)
  end
end
