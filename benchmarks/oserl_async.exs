defmodule Benchmarks.Async do

  require Logger

  alias :timer, as: Timer
  alias SMPPBenchmarks.OserlMC, as: MC
  alias SMPPBenchmarks.ESME, as: ESME

  @default_port 33333
  @default_pdu_count 100000
  @default_window 5000

  def run([]), do: run([@default_port, @default_pdu_count, @default_window])
  def run([port, pdu_count, window]) do

    Logger.info("Starting MC on port #{port}")
    {:ok, _} = MC.start_link(:oserl_mc, port)
    Timer.sleep(50)

    Logger.info("Starting ESME with window #{window}")
    {:ok, esme} = ESME.start_link(port, self, pdu_count, window)
    SMPPEX.ESME.send_pdu(esme, SMPPEX.Pdu.Factory.bind_transmitter("system_id", "password"))

    Logger.info("Sending #{pdu_count} PDUs...")
    {time, _} = Timer.tc(fn() ->
      receive do
        {^esme, :done} -> :ok
        msg -> Logger.error("Unexpected message received: #{inspect msg}")
      end
    end)

    time_ms = div(time, 1000)
    pdu_rate = if time_ms > 0 do
      pdu_count * 1000 / time_ms
    else
      "undifined"
    end

    Logger.info("Completed in #{time_ms}ms with avg rate #{pdu_rate} pdu/s")
  end

end

System.argv |> Enum.map(&String.to_integer/1) |> Benchmarks.Async.run


