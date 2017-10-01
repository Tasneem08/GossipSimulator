defmodule Child do
use Agent

  def start_link(nodeId, topology, numNodes, algorithm) do

   nodeIP = findIP() 
   worker_name = String.to_atom("workernode"<>Integer.to_string(nodeId)<>"@"<>nodeIP)
   
   if algorithm == "pushsum" do
         w = 1
   else 
         w = 0  
   end
   
   case topology do  
          "line"->
          if nodeId == 1 do
            neighbor=[nodeId+1]
          end
          if nodeId == numNodes do
            neighbor=[nodeId-1]
          end
          if nodeId != 1 and nodeId != numNodes do
            neighbor=[nodeId+1,nodeId-1]
          end 

      #send to random neighbor

          "full" ->
          nodeList=Enum.to_list(1..numNodes)
          neighbor=List.delete(nodeList,nodeId)

          _ ->
          # 1	 2	3	 4
          # 5	 6	7	 8
          # 9	 10 11 12
          # 13 14	15 16

          sqrt = :math.sqrt(numNodes)|> Float.ceil |> round
          row = (nodeId-1)/sqrt |> Float.floor |> round
          column = :math.fmod((nodeId-1), sqrt) |> round
          done = false
          if column == 0 and done == false do
              neighbor = [nodeId+1]
              if nodeId - sqrt > 0 do
              neighbor = List.insert_at(neighbor, 0, nodeId - sqrt)
              end
              if nodeId + sqrt < numNodes do
              neighbor = List.insert_at(neighbor, 0, nodeId + sqrt)
              end
              done = true
          end

          if column == sqrt-1 and done == false do
              neighbor = [nodeId-1]
              if nodeId - sqrt > 0 do
              neighbor = List.insert_at(neighbor, 0, nodeId - sqrt)
              end
              if nodeId + sqrt < numNodes do
              neighbor = List.insert_at(neighbor, 0, nodeId + sqrt)
              end
              done = true
          end

          if row == 0 and done == false do
              neighbor = [nodeId-1, nodeId+sqrt, nodeId+1]
              done = true
          end

          if row == sqrt-1 and done == false do
              neighbor = [nodeId-1, nodeId-sqrt, nodeId+1]
              done = true
          end

          if done == false do
             neighbor = [nodeId-1, nodeId-sqrt, nodeId+1, nodeId+sqrt]
             done = true
          end

          IO.inspect nodeId 
          IO.inspect neighbor
          
 # UNIMPLEMENTED
          if topology == "imp2D" do
             nodeList=Enum.to_list(1..numNodes)
             for x<- neighbor do
                 nodeList = List.delete(nodeList,x)
             end
            List.insert_at(neighbor, 0, )
          end

  end
   pid = IO.inspect Agent.start_link(fn -> %{:nodeId => nodeId, :s => nodeId, :w => w, :count => 0 , :neighbors => neighbor} end, name: worker_name)

  end

# For Gossip
  def infect(pid) do
  IO.puts "Found Gossip"
    if pid != nil and Process.alive?(pid) do
    IO.inspect "            Infecting "
    IO.inspect pid
    new_count = Agent.get(pid, &Map.get(&1,:count)+1)
    Agent.update(pid,&Map.put(&1,:count, new_count))
    if new_count == 3 do
       IO.puts "         Dying..."
       {return_value} = informDeath(pid)
       if return_value == :ok do
         IO.puts "Killed!!!!"
         Agent.stop(pid, :normal)
       end
    else
       IO.inspect "          Sender is "
       IO.inspect pid
       Child.spreadInfection(pid)
    end
    end
  end

 # For Push Sum algo
  def infect(pid, {s,w}) do
    IO.puts "Found Push Sum"
    if pid != nil and Process.alive?(pid) do
      IO.inspect "Infecting "
      IO.inspect pid
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
      IO.puts "           Dying..."
      {return_value} = informDeath(pid)
      if return_value == :ok do
         IO.puts "Killed!!!!"
         Agent.stop(pid, :normal)
      end
    else
      Agent.update(pid, &Map.put(&1,:s, new_s/2))
      Agent.update(pid, &Map.put(&1,:w, new_w/2))
      Agent.update(pid, &Map.put(&1,:count, count))
      IO.inspect "           Sender is "
      IO.inspect pid
      Child.spreadInfection(pid, new_s/2, new_w/2)
    end
    end
  end

  def informDeath(pid) do
     neighbors = Agent.get(pid, &Map.get(&1,:neighbors))
     nodeId = Agent.get(pid, &Map.get(&1,:nodeId))
     nodeIP = findIP()
     for x <- neighbors do
        neighbor = String.to_atom("workernode"<>Integer.to_string(x)<>"@"<>nodeIP)
        list = Agent.get(Process.whereis(neighbor), &Map.get(&1,:neighbors))
        list = List.delete(list,nodeId)
        Agent.update(Process.whereis(neighbor), &Map.put(&1,:neighbors, list))
     end
     {:ok}
  end
  # Push sum
  def spreadInfection(sender_pid, s , w) do
     neighborName = getNextNeighbor(sender_pid)
     infect(Process.whereis(neighborName),{s,w})
  end

  # Gossip
  def spreadInfection(sender_pid) do
      neighborName = getNextNeighbor(sender_pid)
      infect(Process.whereis(neighborName))
  end

  def getNextNeighbor(sender_pid) do
      neighbors = Agent.get(sender_pid, &Map.get(&1,:neighbors))

      #Check TOPO here. find neighbors according to the topology, push the neighbors into a list.
      # Do Enum.random to get a random neighbor to infect. Call infect with s,w
     index = Enum.count(neighbors)
     rand_index = Enum.random(1..index)
     selectedNeighbor = Enum.at(neighbors, rand_index - 1)

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