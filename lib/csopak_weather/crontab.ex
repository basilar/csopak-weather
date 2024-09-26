defmodule Crontab do
  use GenServer
  require Logger
  import Utilities, only: [log_fn_start: 0]

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    log_fn_start()

    # schedule work to be performed at some point, make it recurring
    schedule_work(0)

    {:ok, state}
  end

  def handle_info(:work, state) do
    log_fn_start()

    # heartbeat to healthchecks.io
    api = Application.get_env(:csopak_weather, :healthcheck_api)
    healthcheck_api_present = api != nil
    if healthcheck_api_present do
      url = "https://hc-ping.com/0c773244-86bb-4fe9-be9a-1565aead212b"
      Logger.info("sending heartbeats to #{url}")
      _ = api.raw_html(url)
    else
      Logger.warning("heart beats will not be sent to a health check api")      
    end


    Processor.event_loop()

    # Reschedule once more
    schedule_work(1)
    {:noreply, state}
  end

  # if instantenous is zero then do not delay the trigger
  defp schedule_work(instantenous) do
    # trigger again in 1 minutes
    Process.send_after(self(), :work, instantenous * 60 * 1000)
  end
end
