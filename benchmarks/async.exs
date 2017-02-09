defmodule Benchmarks.Async do

  require Logger

  alias :timer, as: Timer
  alias SMPPBenchmarks.ESME, as: ESME

  defmodule MC do

    use SMPPEX.MC

    def start(port) do
      SMPPEX.MC.start({__MODULE__, []}, [transport_opts: [port: port]])
    end

    def init(_socket, _transport, []) do
      {:ok, 0}
    end

    def handle_pdu(pdu, last_id) do
      case pdu |> SMPPEX.Pdu.command_id |> SMPPEX.Protocol.CommandNames.name_by_id do
        {:ok, :submit_sm} ->
          SMPPEX.MC.reply(self(), pdu, SMPPEX.Pdu.Factory.submit_sm_resp(0, to_string(last_id)))
          last_id + 1
        {:ok, :bind_transmitter} ->
          SMPPEX.MC.reply(self(), pdu, SMPPEX.Pdu.Factory.bind_transmitter_resp(0))
          last_id
        {:ok, :enquire_link} ->
          SMPPEX.MC.reply(self(), pdu, SMPPEX.Pdu.Factory.enquire_link_resp)
          last_id
        _ -> last_id
      end
    end
  end

  @default_port 33333
  @default_pdu_count 100000
  @default_window 5000

  def run([]), do: run([@default_port, @default_pdu_count, @default_window])
  def run([port, pdu_count, window]) do

    Logger.info("Starting MC on port #{port}")
    {:ok, _} = MC.start(port)
    Timer.sleep(50)

    Logger.info("Starting ESME with window #{window}")
    {:ok, esme} = ESME.start_link(port, self(), pdu_count, window)

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

