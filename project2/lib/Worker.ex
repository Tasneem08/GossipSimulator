defmodule Worker do


def topology(topo) do
case topo do
    :line -> IO.puts "Found line"
    :full ->IO.puts "Found full"
    :2D ->IO.puts "Found 2D"
    :imp2D ->IO.puts "Found imp2D"
end
end

def receive(algo) do
case algo do
    :gossip -> "Use Gossip algo"
    :push-sum -> "Use Push sum algo"


end
end