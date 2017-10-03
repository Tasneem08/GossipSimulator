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
  def handle_cast({:infect}, state) do
  {nodeId, s, w, current_count, neighbor} = state
  new_count = current_count+1

  if new_count == 3 do
    IO.puts "         Dying..."
    {return_value} = GossipNode.informDeath(nodeId, neighbor)
    if return_value == :ok do
       # kill genserver
    else
       Child.spreadInfection(pid)
    end
        {:noreply, state}
     end
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
      {nodeId, s, w, current_count, neighbor} = state
      neighbor = List.delete(neighbor, nodeId)
      {:noreply, {nodeId, s, w, current_count, neighbor}}
     end

end

# The main module
defmodule GossipNode do

  def informDeath(nodeId, neighbor) do
     nodeIP = findIP()
     for x <- neighbors do
        selectedNeighborNode = String.to_atom("workernode"<>Integer.to_string(x)<>"@"<>nodeIP)
        selectedNeighborServer = String.to_atom("workerserver"<>Integer.to_string(x))
        GenServer.cast({selectedNeighborServer, selectedNeighborNode}, {:removeNeighbor, nodeId})
     end
     {:ok}
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
       
   pid = IO.inspect GossipServer.start_link(nodeId,nodeId, w, 0 , neighbor, worker_name)
  # IO.inspect spawn(Child, :loop, [nodeId, nodeId, w, 0, neighbor])
  end

def removeCurrentNeighbors(nodeList, [head | tail]) do
    nodeList = List.delete(nodeList, head)
    removeCurrentNeighbors(nodeList, tail)
end

def removeCurrentNeighbors(nodeList , []) do
    nodeList
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

  def spreadInfection() do
    Enum.random(min_val..max_val) |>validateHash(k, server_name)
    spreadInfection(k, max_val, min_val, server_name)
  end

  # Starts a server node, initiates the GenServer and starts the mining on the server side.
  def start_link(k) do
    serverIP = findIP() 
    server_name = String.to_atom("muginu@"<>serverIP)
    Node.start(server_name)
    cookie_name = String.to_atom("monster")
    Node.set_cookie(cookie_name)
    BitcoinServer.start_link(k)
    String.duplicate("0", k) |> BitcoinLogic.spawnMultipleThreads(server_name)
    :timer.sleep(:infinity)
  end


  # the recurrsive method that handles mining at client
  def clientMainMethod(k, max_val, min_val, ipAddr) do
    getRandomStrClient(max_val,min_val) |> validateHashClient(k, ipAddr)
    clientMainMethod(k, max_val, min_val, ipAddr)
  end

  def validateHashClient(inputStr, comparator, ipAddr) do
    hashVal=:crypto.hash(:sha256,inputStr) |> Base.encode16(case: :lower)
    bool = String.starts_with?(hashVal, comparator)
    if bool == true do
      print_coin(inputStr,hashVal, ipAddr)
    end
  end
end

defmodule BitcoinLogic do

  def spawnMultipleThreads(k, server_name) do
  for _ <- 1..512 do
        spawn(fn -> mainMethod(k, 40, 1, server_name) end)
        end
  end

  def mainMethod(k, max_val, min_val, server_name) do
    Enum.random(min_val..max_val) |>validateHash(k, server_name)
    mainMethod(k, max_val, min_val, server_name)
  end

  def validateHash(size, comparator, server_name) do
    inputStr = "mmathkar" <> (:crypto.strong_rand_bytes(size) |> Base.encode64 |> binary_part(0, size))
    hashVal=:crypto.hash(:sha256,inputStr) |> Base.encode16(case: :lower)
    if String.starts_with?(hashVal, comparator) == true do
      GenServer.cast({:TM, server_name}, {:print_coin, inputStr, hashVal})
    end
  end

end