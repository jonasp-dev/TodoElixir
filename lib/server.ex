defmodule Todo.Server do
    use GenServer, restart: :temporary 

 @expiry_idle_timeout :timer.seconds(30)    

    def start_link(name) do
      GenServer.start_link(Todo.Server, name, name: global_name(name))
    end
  
    defp global_name(name) do
      {:global, {__MODULE__, name}}
    end
    def add_entry(todo_server, new_entry) do
      GenServer.call(todo_server, {:add_entry, new_entry})
    end
  
    def entries(todo_server, date) do
      GenServer.call(todo_server, {:entries, date})
    end
  
    @impl GenServer
    def init(name) do
      IO.puts("Starting to-do server #{name}.")
      {:ok, {name, Todo.Database.get(name) || Todo.List.new()}, @expiry_idle_timeout}
    end
  
    @impl GenServer
    def handle_call({:add_entry, new_entry}, _, {name, todo_list}) do
      new_state = Todo.List.add_entry(todo_list, new_entry)
      Todo.Database.store(name, new_state)
      {:reply, :ok, {name, new_state}, @expiry_idle_timeout}
    end
  
    @impl GenServer
    def handle_call({:entries, date}, _, {name, todo_list}) do
      {
        :reply,
        Todo.List.entries(todo_list, date),
        {name, todo_list},
        @expiry_idle_timeout
      }
    end

    def handle_info(:timeout, {name, todo_list}) do
      IO.puts("Stopping to-do server for #{name}")
      {:stop, :normal, {name, todo_list}}    
    end

    def whereis(name) do
      case :global.whereis_name({__MODULE__, name}) do
        :undefined -> nil
        pid -> pid
      end
    end
  end