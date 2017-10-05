#Genserver Module
defmodule GossipServer do
  use GenServer

  def start_link(nodeId, s, w, count, firstInfection, neighbor) do
    servername = String.to_atom("workerserver"<>Integer.to_string(nodeId))
    GenServer.start_link(GossipServer, [nodeId, s, w, count, firstInfection, neighbor], name: servername)
  end

  # Maintains a state 
  def init(nodeId, s, w, count, firstInfection, neighbor) do
      {:ok, {nodeId, s, w, count, firstInfection, neighbor}}
  end

  # Gossip infection
  def handle_cast({:infect}, state) do
  [nodeId, s, w, current_count, isFirstInfection, neighbor] = state 
   new_count = current_count+1
  if new_count == 10 do
    GossipNode.informDeath(nodeId, neighbor) 
    end
  if isFirstInfection == false do
    GenServer.cast(self(), {:spreadInfection}) 
    isFirstInfection == true
  end

    {:noreply, [nodeId, s, w, new_count, isFirstInfection, neighbor]}
  end

    # pushsum infection
  def handle_cast({:infectPushSum, s, w}, state) do
  [nodeId, old_s, old_w, current_count, isFirstInfection, neighbor] = state

      new_s = old_s + 0.0
      new_w = old_w + 0.0
    if current_count <5 and s != 0 do
        new_s = s + old_s
        new_w = w + old_w
      #  old_val = Float.round(old_s/old_w,10)
      #  new_val = Float.round(new_s/new_w,10)
        if abs(old_s/old_w - new_s/new_w) < :math.pow(10, -10) do
          current_count = current_count + 1
        else 
          current_count = 0
        end
      end
if current_count == 5 do
    GossipNode.informDeath(nodeId, neighbor)
end
if isFirstInfection == false do
    GenServer.cast(String.to_atom("workerserver"<>Integer.to_string(nodeId)), {:spreadInfectionPushSum})
    isFirstInfection == true
 end
   IO.inspect new_s/new_w
    {:noreply,[nodeId, new_s, new_w, current_count, isFirstInfection, neighbor]}
  end


  def handle_cast({:removeNeighbor, nodeId}, state) do
      [nodeId, s, w, current_count, isFirstInfection, neighbor] = state
      new_neighbor = List.delete(neighbor, nodeId)
      {:noreply, [nodeId, s, w, current_count, isFirstInfection, new_neighbor]}
  end

  def handle_cast({:spreadInfection}, state) do
      [nodeId, s, w, current_count, isFirstInfection, neighbor] = state
      neighborName = GossipNode.getNextNeighbor(neighbor)
      GossipNode.sendGossip(neighborName)
      {:noreply, state}
  end

    def handle_cast({:spreadInfectionPushSum}, state) do
      [nodeId, s, w, current_count, isFirstInfection, neighbor] = state
      neighbor
      neighborName = GossipNode.getNextNeighbor(neighbor)
      spawn(fn-> GossipNode.sendGossip(nodeId, neighborName, s/2, w/2) end)
      {:noreply, [nodeId, s/2, w/2, current_count, isFirstInfection, neighbor]}
  end

  def handle_cast({:kill_self}, state) do
      {:stop, :normal, state}
  end

  def terminate(_, state) do
    GenServer.cast(:main_server, {:iDied})
  end

end

# The main module
defmodule GossipNode do

def sendGossip(neighborName) do
    GenServer.cast(neighborName, {:infect})
    GenServer.cast(self(), {:spreadInfection})
end

def sendGossip(nodeId, neighborName, s, w) do
    GenServer.cast(neighborName, {:infectPushSum, s, w})
    Process.sleep(200)
    GenServer.cast(String.to_atom("workerserver"<>Integer.to_string(nodeId)), {:spreadInfectionPushSum})
end

  def informDeath(nodeId, neighbor) do
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
   pid = GossipServer.start_link(nodeId, nodeId, w, 0 , false, neighbor)
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
     rand_index = Enum.random(1..index)
     selectedNeighbor = Enum.at(neighbors, rand_index - 1)
     String.to_atom("workerserver"<>Integer.to_string(selectedNeighbor))
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