defmodule Child do
  def start_link(limit) do
    pid = spawn_link(__MODULE__, :init, [limit])
    {:ok, pid}
  end

  def init(limit) do
    IO.puts "Start child with limit #{limit} pid #{inspect self()}"
    loop(limit)
  end

  def loop(0), do: :ok
  def loop(n) when n > 0 do
    IO.puts "Process #{inspect self()} counter #{n}"
    Process.sleep 500
    loop(n-1)
  end
end