defmodule Worker do
use Agent

  def start_link(nodeId,topology,algorithm) do
    IO.inspect Agent.start_link(fn -> createWorker(nodeId,topology,algorithm) end)
  end


def createWorker(nodeId,topology,algorithm) do
s = nodeId
w = 1
[s,w,0]
end

def init([nNodes,topology,algorithm]) do
IO.puts("Reached here..")
end

def topology(topo) do
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