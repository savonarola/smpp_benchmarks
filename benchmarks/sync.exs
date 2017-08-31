defmodule Benchmarks.Sync do

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

  @from {"from", 1, 1}
  @to {"to", 1, 1}
  @message "hello"

  @default_port 33333
  @default_pdu_count 100000

  def run([]), do: run([@default_port, @default_pdu_count])
  def run([port, pdu_count]) do

    Logger.info("Starting MC on port #{port}")
    {:ok, _} = MC.start(port)
    Timer.sleep(50)

    Logger.info("Starting synchronous ESME")
    {:ok, esme} = SMPPEX.ESME.Sync.start_link("127.0.0.1", port)
    {:ok, _} = SMPPEX.ESME.Sync.request(esme, SMPPEX.Pdu.Factory.bind_transmitter("system_id", "password"))

    Logger.info("Sending #{pdu_count} PDUs...")
    {time, _} = Timer.tc(fn() ->
      :ok = loop(esme, pdu_count)
    end)

    time_ms = div(time, 1000)
    pdu_rate = if time_ms > 0 do
      pdu_count * 1000 / time_ms
    else
      "undifined"
    end

    Logger.info("Completed in #{time_ms}ms with avg rate #{pdu_rate} pdu/s")
  end

  defp loop(_esme, pdu_count) when pdu_count <= 0, do: :ok
  defp loop(esme, pdu_count) do
    submit_sm = SMPPEX.Pdu.Factory.submit_sm(@from, @to, @message)
    {:ok, _} = SMPPEX.ESME.Sync.request(esme, submit_sm)
    loop(esme, pdu_count - 1)
  end
end

System.argv |> Enum.map(&String.to_integer/1) |> Benchmarks.Sync.run
