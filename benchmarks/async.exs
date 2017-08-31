defmodule Benchmarks.Async do

  require Logger

  alias :timer, as: Timer

  defmodule MC do

    use SMPPEX.Session

    alias SMPPEX.Pdu
    alias SMPPEX.Pdu.Factory, as: PduFactory

    def start(port) do
      SMPPEX.MC.start({__MODULE__, []}, [transport_opts: [port: port]])
    end

    def init(_socket, _transport, []) do
      {:ok, 0}
    end

    def handle_pdu(pdu, last_id) do
      case Pdu.command_name(pdu) do
        :submit_sm ->
          {:ok, [PduFactory.submit_sm_resp(0, to_string(last_id)) |> Pdu.as_reply_to(pdu)], last_id + 1}
        :bind_transmitter ->
          {:ok, [PduFactory.bind_transmitter_resp(0) |> Pdu.as_reply_to(pdu)], last_id}
        :enquire_link ->
          {:ok, [PduFactory.enquire_link_resp |> Pdu.as_reply_to(pdu)], last_id}
        _ ->
          {:ok, last_id}
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
    {:ok, esme} = SMPPBenchmarks.ESME.start_link(port, self(), pdu_count, window)

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
