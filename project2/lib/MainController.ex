defmodule MainController do

# entry point to the code. Read command line arguments and invoke the right things here.
  # Entry point to the code. 
  def main(args) do
   IO.inspect(args)
   [nNodes,topology,algorithm] = args
   numNodes=nNodes|>String.to_integer()
   Gossip.Supervisor.start_link(nNodes,topology,algorithm)
  end
end

defmodule Gossip.Supervisor do
    use Supervisor

    def start_link(nNodes,topology,algorithm) do
    Supervisor.start_link(__MODULE__, [nNodes,topology,algorithm])
    end

    def init([nNodes,topology,algorithm]) do
        children = [
            worker(Worker, [nNodes,topology,algorithm])
        ]

        IO.inspect Supervisor.start_child(children,strategy: :one_for_one)
    end
end
