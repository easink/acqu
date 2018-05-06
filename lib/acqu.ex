defmodule Acqu do
  @moduledoc """
  Documentation for Acqu.
  """
  use GenServer

  # @type state :: %{queue: list(), in_progress: list(tuple())}

  #
  # API
  #

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def put(item) do
    GenServer.call(__MODULE__, {:put, item})
  end

  def get() do
    GenServer.call(__MODULE__, :get)
  end

  def ack(item) do
    GenServer.call(__MODULE__, {:ack, item})
  end

  #
  # Callbacks
  #

  # @spec init(:ok) :: {:ok, state}
  def init(:ok) do
    {:ok, %{queue: :queue.new(), in_progress: []}}
  end

  # @spec handle_call({:put, any}, any, state) :: {:reply, :ok, state}
  def handle_call({:put, item}, from, state) do
    queue = :queue.in(item, state.queue)
    {:reply, :ok, %{state | queue: queue}}
  end

  def handle_call(:get, {pid, _ref}, state) do
    {item, queue, in_progress} =
      case :queue.out(state.queue) do
        {{:value, item}, queue} ->
          Process.monitor(pid)
          in_progress = state.in_progress ++ [{pid, item}]
          {item, queue, in_progress}

        {:empty, queue} ->
          {nil, queue, state.in_progress}
      end

    {:reply, item, %{state | queue: queue, in_progress: in_progress}}
  end

  def handle_call({:ack, item}, {pid, _ref}, state) do
    unless {pid, item} in state.in_progress do
      raise "Tried to ack item (#{inspect(item)}), doesnt seem to exist."
    end

    in_progress = List.delete(state.in_progress, {pid, item})

    {:reply, :ok, %{state | in_progress: in_progress}}
  end

  def handle_info({:DOWN, _ref, :process, pid, msg}, state) do
    {in_progress, queue} = move_back_to_queue(state.in_progress, state.queue, pid)
    {:noreply, %{state | queue: queue, in_progress: in_progress}}
  end

  # def handle_info({:EXIT, _ref, :process, pid, msg}, state) do
  #   {in_progress, queue} = move_back_to_queue(state.in_progress, state.queue, pid)
  #   {:noreply, %{state | queue: queue, in_progress: in_progress}}
  # end

  #
  # Private
  #

  defp move_back_to_queue(list, queue, pid) do
    list = for {key, value} <- list, pid != key, do: {key, value}
    queue = :queue.filter(fn {key, value} -> pid != key end, queue)
    {list, queue}
  end

  # def test() do
  #   spawn(fn ->
  #     Acqu.put("Banan")
  #     :timer.sleep(1000)
  #     q = Acqu.get()
  #     IO.puts("QQQQ #{inspect(q)}")
  #     :timer.sleep(1000)
  #     raise "dddddd"
  #     IO.puts("QUITING...")
  #   end)
  # end
end
