defmodule Child do
  def start_link(limit) do
   IO.puts("reached here")
    pid = IO.inspect spawn_link(__MODULE__, :init, [limit])
    IO.puts("reached here after spawning")
    {:ok, pid}
  end

  def init(limit) do
    IO.puts "Start child with limit #{limit} pid #{inspect self()}"
    loop(1000)
  end

  def loop(0), do: :ok
  def loop(n) when n > 0 do
    IO.puts "Process #{inspect self()} counter #{n}"
    Process.sleep 500
    loop(n-1)
  end
end