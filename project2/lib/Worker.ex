#Genserver Module
defmodule GossipServer do
  use GenServer

  def start_link(nodeId, s, w, count, firstInfection, neighbor, spawnedPid) do
    servername = String.to_atom("workerserver"<>Integer.to_string(nodeId))
    GenServer.start_link(GossipServer, [nodeId, s, w, count, firstInfection, neighbor, spawnedPid], name: servername)
  end

  # Maintains a state 
  def init(nodeId, s, w, count, firstInfection, neighbor, spawnedPid) do
      {:ok, {nodeId, s, w, count, firstInfection, neighbor, spawnedPid}}
  end


  # Gossip infection
  def handle_cast({:infect}, state) do

   [nodeId, s, w, current_count, isFirstInfection, neighbor, spawnedPid] = state 
   new_count = current_count
   if(current_count<10) do
   new_count = current_count+1

  if new_count == 10 do
    GossipNode.informDeathGossip(nodeId, neighbor) 
  end
    end
  if isFirstInfection == false do
    GenServer.cast(String.to_atom("workerserver"<>Integer.to_string(nodeId)), {:spreadInfection}) 
    isFirstInfection == true
  end

  # [nodeId, s, w, new_count, isFirstInfection, neighbor]
  {:noreply, [nodeId, s, w, new_count, isFirstInfection, neighbor, spawnedPid]}

  end

  
  # Pushsum infection
  def handle_cast({:infectPushSum, s, w}, state) do
  [nodeId, old_s, old_w, current_count, isFirstInfection, neighbor, spawnedPid] = state
  # IO.inspect "Reached here"
      # new_s = old_s + 0.0
      # new_w = old_w + 0.0
        new_s = s + old_s
        new_w = w + old_w
    if current_count <3 and s != 0 do
        # new_s = s + old_s
        # new_w = w + old_w
      #  old_val = Float.round(old_s/old_w,10)
      #  new_val = Float.round(new_s/new_w,10)
        if abs(old_s/old_w - new_s/new_w) < :math.pow(10, -10) do
          current_count = current_count + 1
        else 
          current_count = 0
        end
    
if current_count == 3 do
    GossipNode.informDeath(nodeId, neighbor)
  end
end
if isFirstInfection == false do
   isFirstInfection == true
    #GossipNode.sendGossip(nodeId)
    GenServer.cast(String.to_atom("workerserver"<>Integer.to_string(nodeId)), {:spreadInfectionPushSum})
    
 end
    # IO.inspect new_s/new_w
    {:noreply,[nodeId, new_s, new_w, current_count, isFirstInfection, neighbor, spawnedPid]}
  end


  def handle_cast({:removeNeighbor, nodeId}, state) do
      [selfId, s, w, current_count, isFirstInfection, neighbor, spawnedPid] = state
      new_neighbor =  List.delete(neighbor, nodeId)
      {:noreply,  [selfId, s, w, current_count, isFirstInfection, new_neighbor, spawnedPid]}
  end

  def handle_cast({:spreadInfection}, state) do
      [nodeId, s, w, current_count, isFirstInfection, neighbor, spawnedPid] = state
      neighborName = GossipNode.getNextNeighbor(neighbor)
      if neighborName == {:die} do

      GenServer.cast(String.to_atom("workerserver"<>Integer.to_string(nodeId)), {:kill_self})
      else
      GossipNode.sendGossip(nodeId,neighborName)
      end
      {:noreply, state}
  end

  def handle_cast({:spreadInfectionPushSum}, state) do
      [nodeId, s, w, current_count, isFirstInfection, neighbor, spawnedPid] = state
      neighborName = GossipNode.getNextNeighbor(neighbor)
      if neighborName == {:die} do
      
      # GenServer.cast(String.to_atom("workerserver"<>Integer.to_string(nodeId)), {:kill_self})
      GossipNode.informDeath(nodeId, [])
      else
      # IO.inspect "Node #{nodeId} is sending gossip to #{neighborName}"
      GenServer.cast(neighborName, {:infectPushSum, s/2, w/2})
      end
      {:noreply, [nodeId, s/2, w/2, current_count, isFirstInfection, neighbor, spawnedPid]}
  end

  def handle_cast({:kill_self}, state) do
      # [nodeId, s, w, current_count, isFirstInfection, neighbor, spawnedPid] = state
      # Process.exit(spawnedPid, :kill)
      {:stop, :normal, state}
  end

  def terminate(_, state) do
    GenServer.cast(:main_server, {:iDied, self()})
    {:ok}
  end

end

# The main module
defmodule GossipNode do

def sendGossip(nodeId,neighborName) do
    GenServer.cast(neighborName, {:infect})
     Process.sleep(1)
    GenServer.cast(String.to_atom("workerserver"<>Integer.to_string(nodeId)), {:spreadInfection})
end

def sendGossip(nodeId) do

    Process.sleep(500)
    if Process.whereis(String.to_atom("workerserver"<>Integer.to_string(nodeId))) == nil do 
      IO.inspect "Found a server that is already kills = #{nodeId}"
      
    else

    GenServer.cast(String.to_atom("workerserver"<>Integer.to_string(nodeId)), {:spreadInfectionPushSum})

    end
    sendGossip(nodeId)
    # neighborName = GossipNode.getNextNeighbor(neighbor)
    # GenServer.cast(neighborName, {:infectPushSum, s, w})
    # Process.sleep(1)
    # GenServer.call(String.to_atom("workerserver"<>Integer.to_string(nodeId)), {:spreadInfectionPushSum})
end

  def informDeathGossip(nodeId, neighbor) do
     for x <- neighbor do
        selectedNeighborServer = String.to_atom("workerserver"<>Integer.to_string(x))
        GenServer.cast(selectedNeighborServer, {:removeNeighbor, nodeId})
     end
     GenServer.cast(String.to_atom("workerserver"<>Integer.to_string(nodeId)), {:kill_self})
  end

  def informDeath(nodeId, neighbor) do
      for x <- neighbor do
        selectedNeighborServer = String.to_atom("workerserver"<>Integer.to_string(x))
        GenServer.cast(selectedNeighborServer, {:removeNeighbor, nodeId})
     end
    #  IO.inspect "Node #{nodeId} is dying..."
     GenServer.cast(String.to_atom("workerserver"<>Integer.to_string(nodeId)), {:kill_self})
     
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
              neighbor =  [nodeId+1]
              if nodeId - sqrt > 0 do
              neighbor = List.insert_at(neighbor, 0, nodeId - sqrt)
              end
              if nodeId + sqrt <= numNodes do
              neighbor = List.insert_at(neighbor, 0, nodeId + sqrt)
              end
              done = true
          end

          if column == sqrt-1 and done == false do
              neighbor = [nodeId-1]
              if nodeId - sqrt > 0 do
              neighbor = List.insert_at(neighbor, 0, nodeId - sqrt)
              end
              if nodeId + sqrt <= numNodes do
              neighbor = List.insert_at(neighbor, 0, nodeId + sqrt)
              end
              done = true
          end

          if row == 0 and done == false do
              neighbor = [nodeId - 1, nodeId + sqrt, nodeId + 1]
              done = true
          end

          if row == sqrt-1 and done == false do
              left = nodeId - 1
              right = nodeId + 1
              up = nodeId - sqrt
              neighbor = [left, up, right]
              done = true
          end

          if done == false do
             neighbor = [nodeId - 1, nodeId - sqrt, nodeId + 1, nodeId + sqrt]
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
  # IO.inspect neighbor, charlists: :as_lists
   #Node.start(worker_name)
   pid = GossipServer.start_link(nodeId, nodeId, w, 0 , false, neighbor, self())
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
      GenServer.call(neighborName, {:infect})
      spreadInfection(neighbor)
  end

  # Pushsum
  # def spreadInfection(neighbor, s , w) do
  #    neighborName = getNextNeighbor(sender_pid)
  #    infect(Process.whereis(neighborName),{s,w})
  # end

  def getNextNeighbor(neighbors) do
   
     index = Enum.count(neighbors)
     if index == 0 do
     {:die}
     else
     rand_index = Enum.random(1..index)
     selectedNeighbor = Enum.at(neighbors, rand_index - 1)
     if selectedNeighbor == nil or Process.whereis(String.to_atom("workerserver"<>Integer.to_string(selectedNeighbor))) == nil do
     {:die}
     else
     String.to_atom("workerserver"<>Integer.to_string(selectedNeighbor))
     end
     end
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