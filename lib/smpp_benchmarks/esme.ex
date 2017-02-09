defmodule SMPPBenchmarks.ESME do

  use SMPPEX.ESME
  require Logger

  @from {"from", 1, 1}
  @to {"to", 1, 1}
  @message "hello"

  @system_id "system_id"
  @password "password"

  def start_link(port, waiting_pid, count, window) do
    SMPPEX.ESME.start_link("127.0.0.1", port, {__MODULE__, [waiting_pid, count, window]})
  end

  def init([waiting_pid, count, window]) do
    SMPPEX.ESME.send_pdu(self(), SMPPEX.Pdu.Factory.bind_transmitter(@system_id, @password))
    {:ok, %{waiting_pid: waiting_pid, count_to_send: count, count_waiting_resp: 0, window: window}}
  end

  def handle_resp(pdu, _original_pdu, st) do
    case pdu |> SMPPEX.Pdu.command_id |> SMPPEX.Protocol.CommandNames.name_by_id do
      {:ok, :submit_sm_resp} ->
        new_st = %{ st | count_waiting_resp: st.count_waiting_resp - 1 }
        send_pdus(new_st)
      {:ok, :bind_transmitter_resp} ->
        send_pdus(st)
      _ ->
        st
    end
  end

  def handle_resp_timeout(pdu, st) do
    Logger.error("PDU timeout: #{inspect pdu}, terminating")
    SMPPEX.ESME.stop(self())
    st
  end

  def handle_stop(st) do
    Logger.info("ESME stopped")
    Kernel.send(st.waiting_pid, {self(), :done})
    st
  end

  defp send_pdus(st) do
    cond do
      st.count_to_send > 0 ->
        count_to_send = min(st.window - st.count_waiting_resp, st.count_to_send)
        :ok = do_send(self(), count_to_send)
        %{ st | count_waiting_resp: st.window, count_to_send: st.count_to_send - count_to_send }
      st.count_waiting_resp > 0 ->
        st
      true ->
        Logger.info("All PDUs sent, all resps received, terminating")
        SMPPEX.ESME.stop(self())
        st
    end
  end

  defp do_send(_esme, n) when n <= 0, do: :ok
  defp do_send(esme, n) do
    submit_sm = SMPPEX.Pdu.Factory.submit_sm(@from, @to, @message)
    :ok = SMPPEX.ESME.send_pdu(esme, submit_sm)
    do_send(esme, n - 1)
  end

end

