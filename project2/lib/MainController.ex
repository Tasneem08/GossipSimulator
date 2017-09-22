defmodule MainController do

# entry point to the code. Read command line arguments and invoke the right things here.
  # Entry point to the code. 
  def main(args) do
   IO.inspect(args)
   [nNodes,topology,algorithm] = args
   numNodes=nNodes|>String.to_integer()
  end
end

defmodule Master do

end

defmodule Worker do


end
