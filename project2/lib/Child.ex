defmodule Child do
use Agent

  def start_link(nodeId, topology, numNodes, algorithm) do

   nodeIP = findIP() 
   worker_name = String.to_atom("workernode"<>Integer.to_string(nodeId)<>"@"<>nodeIP)

   if topology == "line" or topology == "full" do
      if algorithm == "pushsum" do
         pid = IO.inspect Agent.start_link(fn -> %{:s => nodeId, :w => 1, :count => 0, :numNodes => numNodes, :topology => topology} end, name: worker_name)
      else 
         pid = IO.inspect Agent.start_link(fn -> %{:s => nodeId, :w => 0, :count => 0, :numNodes => numNodes, :topology => topology} end, name: worker_name)
      end
   else 
      IO.puts "Found Topo as #{topology}. UNHANDLED!!"
   end
  end

# For Gossip
  def infect(pid) do
    IO.puts "Found Gossip"
    new_count = Agent.get(pid, &Map.get(&1,:count)+1)
    Agent.update(pid,&Map.put(&1,:count, new_count))
    if new_count == 10 do
       Agent.stop(pid, :normal)
    else
       Child.spreadInfection(pid, 0, 0)
    end
  end

 # For Push Sum algo
  def infect(pid, {s,w}) do
    IO.puts "Found Push Sum"
    old_s = Agent.get(pid, &Map.get(&1,:s))
    old_w = Agent.get(pid, &Map.get(&1,:w))
    count = Agent.get(pid, &Map.get(&1,:count))
    new_s = s + old_s
    new_w = w + old_w

    if abs(old_s/old_w - new_s/new_w) < :math.pow(10, -10) do
       count = count + 1
    else 
       count = 0
    end

    # Agent.update(pid, &Map.put(&1,:s, new_s))
    # Agent.update(pid, &Map.put(&1,:w, new_w))
    # Agent.update(pid, &Map.put(&1,:count, count))
   
    if(count ==3) do
      Agent.update(pid, &Map.put(&1,:s, new_s))
      Agent.update(pid, &Map.put(&1,:w, new_w))
      Agent.update(pid, &Map.put(&1,:count, count))
      Agent.stop(pid, :normal)
    else
      Agent.update(pid, &Map.put(&1,:s, new_s/2))
      Agent.update(pid, &Map.put(&1,:w, new_w/2))
      Agent.update(pid, &Map.put(&1,:count, count))
      Child.spreadInfection(pid, new_s/2, new_w/2)
    end
  end

  # Push sum
  def spreadInfection(sender_pid, s , w) do
     neighborName = getNextNeighbor(sender_pid)
     infect(neighborName,{s,w})
  end

  # Gossip
  def spreadInfection(sender_pid) do
      neighborName = getNextNeighbor(sender_pid)
      infect(neighborName)
  end

  def getNextNeighbor(sender_pid) do
      sender = Agent.get(sender_pid, fn -> Agent.name() end)
      nodeId = getNodeId(sender)
      topology = Agent.get(sender_pid, &Map.get(&1,:topology))
      numNodes = Agent.get(sender_pid, &Map.get(&1,:numNodes))
      #Check TOPO here. find neighbors according to the topology, push the neighbors into a list.
      # Do Enum.random to get a random neighbor to infect. Call infect with s,w
      case topology do  

          "line"->
          case nodeId do
          0 -> 
                neighbor=[nodeId+1]
                selectedNeighbor=Enum.random(neighbor)
          numNodes ->
                neighbor=[nodeId-1]
                selectedNeighbor=Enum.random(neighbor)
          _ ->
                neighbor=[nodeId+1,nodeId-1]
                selectedNeighbor=Enum.random(neighbor)
          end
      #send to random neighbor

       "full" ->
        nodes=[0..numNodes]
        nodeList=Enum.to_list(nodes)
        neighbor=List.delete(nodeList,nodeId)
        selectedNeighbor=Enum.random(neighbor)
      end
    
     # else if(topology=="twoD")  
    nodeIP = findIP() 
    String.to_atom("workernode"<>Integer.to_string(selectedNeighbor)<>"@"<>nodeIP)
  end 

  def getNodeId(sender) do
      str = Atom.to_string(sender)
      [first, _] = String.split(str, "@")
      "workernode"<>num = first
      String.to_integer(num)
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