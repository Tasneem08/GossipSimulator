#Genserver Module
defmodule GossipServer do
  use GenServer

  def start_link(nodeId, s, w, count, neighbor) do
    servername = String.to_atom("workerserver"<>Integer.to_string(nodeId))
    GenServer.start_link(GossipServer, [nodeId, s, w, count, neighbor], name: servername)
  end

  # Maintains a state 
  def init(nodeId, s, w, count, neighbor) do
      {:ok, {nodeId, s, w, count, neighbor}}
  end

  # Gossip infection
  def handle_call({:infect}, _from, state) do
  [nodeId, s, w, current_count, neighbor] = IO.inspect state
  new_count = current_count+1

  if new_count == 3 do
    IO.puts "         Dying..."
    GossipNode.informDeath(nodeId, neighbor)
  else
    IO.inspect "Will spread infection"
    spawn(fn -> GossipNode.spreadInfection(neighbor) end)
  end
    {:reply, state, [nodeId, s, w, new_count, neighbor]}
  end

  # PushSum infection
  # def handle_cast({:infect, s, w}, state) do
  # {nodeId, s, w, current_count, neighbor}
  #     case Map.get(map, inputStr) do
  #     nil ->
  #       Bitcoinminer.printBitcoins(inputStr, hashValue)
  #       {:noreply, {k, Map.put(map, inputStr, hashValue)}}
  #     _ ->
  #       {:noreply, state}
  #    end
  # end

  def handle_cast({:removeNeighbor, nodeId}, state) do
      [nodeId, s, w, current_count, neighbor] = state
      neighbor = List.delete(neighbor, nodeId)
      {:noreply, [nodeId, s, w, current_count, neighbor]}
  end

  def handle_cast({:kill_self}, state) do
      {:stop, :normal, state}
  end

  def terminate(_, state) do
    IO.inspect "Look! I'm dead."
  end

end

# The main module
defmodule GossipNode do

  def informDeath(nodeId, neighbor) do
     nodeIP = findIP()
     for x <- neighbor do
        selectedNeighborNode = String.to_atom("workernode"<>Integer.to_string(x)<>"@"<>nodeIP)
        selectedNeighborServer = String.to_atom("workerserver"<>Integer.to_string(x))
        GenServer.cast(selectedNeighborServer, {:removeNeighbor, nodeId})
     end
     GenServer.cast(self(), {:kill_self})
  end

  # Entry point to the code. 
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

          if topology == "imp2D" do
             nodeList=Enum.to_list(1..numNodes)
              nodeList = List.delete(nodeList,nodeId)
              nodeList = removeCurrentNeighbors(nodeList, neighbor)
            probableNeighborCount = Enum.count(nodeList)
            rand_neighborIndex = Enum.random(1..probableNeighborCount)
            selectedRandNeighbor = Enum.at(nodeList, rand_neighborIndex - 1)
            neighbor = List.insert_at(neighbor, 0, selectedRandNeighbor)
          end

  end
   #Node.start(worker_name)
   pid = IO.inspect GossipServer.start_link(nodeId, nodeId, w, 0 , neighbor)
  end

def removeCurrentNeighbors(nodeList, [head | tail]) do
    nodeList = List.delete(nodeList, head)
    removeCurrentNeighbors(nodeList, tail)
end

def removeCurrentNeighbors(nodeList , []) do
    nodeList
end

  # Gossip
  def spreadInfection(neighbor) do
      neighborName = getNextNeighbor(neighbor)
      IO.inspect GenServer.call(neighborName, {:infect})
  end

  def getNextNeighbor(neighbors) do
     index = Enum.count(neighbors)
     rand_index = Enum.random(1..index)
     selectedNeighbor = Enum.at(neighbors, rand_index - 1)
     IO.inspect String.to_atom("workerserver"<>Integer.to_string(selectedNeighbor))
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