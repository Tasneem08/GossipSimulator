defmodule MainController do

# entry point to the code. Read command line arguments and invoke the right things here.
  # Entry point to the code. 
  def main(args) do
   IO.inspect(args)
   [nNodes,topology,algorithm] = args
   numNodes=nNodes|>String.to_integer()

   IO.inspect Enum.to_list(1..numNodes)
   Gossip.Supervisor.start_link(numNodes,topology,algorithm)
  end
end

defmodule Gossip.Supervisor do
    use Supervisor

    def start_link(numNodes,topology,algorithm) do
    Supervisor.start_link(__MODULE__, [numNodes,topology,algorithm])
    end

    # def init([numNodes,topology,algorithm]) do
    #     # children = [
    #     #     worker(Worker, [numNodes,topology,algorithm])
    #     # ]

    #     #IO.inspect Supervisor.init(children,strategy: :one_for_one)
    #     IO.inspect Supervisor.init([{Worker, [numNodes,topology,algorithm]}], strategy: :one_for_one)
    # end

    def init([numNodes,topology,algorithm]) do
    children = Enum.map(Enum.to_list(1..numNodes), fn(nodeId) ->
      worker(Child, [nodeId], [id: nodeId, restart: :permanent])
    end)

    IO.inspect Supervisor.init(children,strategy: :one_for_one)
    IO.inspect supervise(children,strategy: :one_for_one)
  end
end
