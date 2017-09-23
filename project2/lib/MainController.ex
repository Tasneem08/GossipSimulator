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
    Supervisor.start_link(__MODULE__, [numNodes])
    end

    # def init([numNodes,topology,algorithm]) do
    #     # children = [
    #     #     worker(Worker, [numNodes,topology,algorithm])
    #     # ]

    #     #IO.inspect Supervisor.init(children,strategy: :one_for_one)
    #     IO.inspect Supervisor.init([{Worker, [numNodes,topology,algorithm]}], strategy: :one_for_one)
    # end

    def init(limits) do
    children = Enum.map(limits, fn(limit_num) ->
      worker(Child, [limit_num], [id: limit_num, restart: :permanent])
    end)

    IO.inspect supervise(children, strategy: :one_for_one)
    IO.inpect supervisor()
  end
end
