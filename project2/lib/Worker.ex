defmodule Worker do
use Agent

  def start_link([numNodes,topology,algorithm]) do
   for x <- 1..numNodes do
    IO.inspect spawn(fn -> createWorker(x,topology,algorithm) end)

  end
  {:ok}
  end


def createWorker(nodeId,topology,algorithm) do
    s = nodeId
    neighbor = {}
    w = 1
    [s,w,0]
    networkTopology(String.to_atom(topology))
    loop(nodeId)
# connections to be established.
end

def loop(nodeId) do
    IO.puts("#{nodeId}")
    loop(nodeId)
end

def init([nNodes,topology,algorithm]) do
    IO.puts("Reached here..")
end

def networkTopology(topo) do
case topo do
    :line -> IO.puts "Found line"
    :full ->IO.puts "Found full"
    :twoD ->IO.puts "Found 2D"
    :imp2D ->IO.puts "Found imp2D"
end
end

def receive(algo) do
case algo do
    :gossip -> "Use Gossip algo"
    :pushsum -> "Use Push sum algo"


end
end
end