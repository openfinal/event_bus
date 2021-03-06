defmodule EventBus.Support.Helper do

  defmodule InputLogger do
    require Logger

    def process({event_type, event_key}) do
      inputs = EventBus.fetch_event_data({event_type, event_key})
      Logger.info(fn -> "Event log '#{event_type}' for #{inspect(inputs)}" end)
      EventBus.mark_as_completed({__MODULE__, event_type, event_key})
    end
  end

  defmodule Calculator do
    require Logger

    def process({:metrics_received, event_key}) do
      inputs = EventBus.fetch_event_data({:metrics_received, event_key})
      # handle an event
      sum = Enum.reduce(inputs, 0, &(&1 + &2))
      # create a new event if necessary
      EventBus.notify({:metrics_summed, {sum, inputs}})
      EventBus.mark_as_completed({__MODULE__, :metrics_received, event_key})
    end
    def process({event_type, event_key}) do
      EventBus.mark_as_skipped({__MODULE__, event_type, event_key})
    end
  end

  defmodule MemoryLeakerOne do
    @moduledoc """
    Adds all sums to a list without caring memory
    """

    use GenServer

    @doc false
    def start_link do
      GenServer.start_link(__MODULE__, [], name: __MODULE__)
    end

    def process({:metrics_summed, event_key}) do
      GenServer.cast(__MODULE__, {:metrics_summed, event_key})
    end
    def process({event_type, event_key}) do
      EventBus.mark_as_skipped({__MODULE__, event_type, event_key})
    end

    def handle_cast({:metrics_summed, event_key}, state) do
      inputs = EventBus.fetch_event_data({:metrics_summed, event_key})
      new_state = [inputs | state]
      EventBus.mark_as_completed({__MODULE__, :metrics_summed, inputs})
      {:noreply, new_state}
    end
  end

  defmodule BadOne do
    def process(_, _) do
      throw "bad"
    end
  end
end
