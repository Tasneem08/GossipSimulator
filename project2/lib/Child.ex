defmodule Child do
use Agent

 


    def loop(nodeId, s, w, count, neighbor) do
        receive do
            {new_s, new_w} ->
                IO.inspect "Received new s and w..."
            _ ->
                IO.inspect "Received something..."
        end
    IO.inspect nodeId
    IO.inspect "Waiting..."
    loop(nodeId, s, w, count, neighbor)
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

     index = Enum.count(neighbors)
     rand_index = Enum.random(1..index)
     selectedNeighbor = Enum.at(neighbors, rand_index - 1)

      nodeIP = findIP() 
      String.to_atom("workernode"<>Integer.to_string(selectedNeighbor)<>"@"<>nodeIP)
  end 

  # Returns the IP address of the machine the code is being run on.

end