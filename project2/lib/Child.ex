defmodule Child do
use Agent

  def start_link(nodeId, topology, numNodes, algorithm) do

   nodeIP = findIP() 
   worker_name = String.to_atom("workernode"<>Integer.to_string(nodeId)<>"@"<>nodeIP)

   if topology == "line" or topology == "full" do
      if algorithm == "pushsum" do
         pid = IO.inspect Agent.start_link(fn -> %{:s => nodeId, :w => 1, :count => 0} end, name: worker_name)
      else 
         pid = IO.inspect Agent.start_link(fn -> %{:s => nodeId, :w => 0, :count => 0} end, name: worker_name)
      end
   else 
      IO.puts "Found Topo as #{topology}. UNHANDLED!!"
   end
  end
  
  def infect(pid) do
  IO.inspect "Printing the state of this agent!!!!"
  IO.inspect Agent.get(pid, fn state -> state end)
  end

  def loop(0), do: :ok
  def loop(n) when n > 0 do
    IO.puts "Process #{inspect self()} counter #{n}"
    loop(n-1)
  end

  # Returns the IP address of the machine the code is being run on.
  def findIP do
    {ops_sys, extra } = :os.type
    ip = 
    case ops_sys do
      :unix -> 
            if extra == :linux do
              {:ok, [addr: ip]} = :inet.ifget('ens3', [:addr])
              to_string(:inet.ntoa(ip))
            else
              {:ok, [addr: ip]} = :inet.ifget('en0', [:addr])
              to_string(:inet.ntoa(ip))
            end
      :win32 -> {:ok, [ip, _]} = :inet.getiflist
               to_string(ip)
    end
  (ip)
  end

end