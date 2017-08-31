defmodule SMPPBenchmarks.ESME do

  use SMPPEX.Session
  require Logger

  @from {"from", 1, 1}
  @to {"to", 1, 1}
  @message "hello"

  @system_id "system_id"
  @password "password"

  def start_link(port, waiting_pid, count, window) do
    SMPPEX.ESME.start_link("127.0.0.1", port, {__MODULE__, [waiting_pid, count, window]})
  end

  def init(_, _, [waiting_pid, count, window]) do
    Kernel.send(self(), :bind)
    {:ok, %{waiting_pid: waiting_pid, count_to_send: count, count_waiting_resp: 0, window: window}}
  end

  def handle_resp(pdu, _original_pdu, st) do
    case SMPPEX.Pdu.command_name(pdu) do
      :submit_sm_resp ->
        new_st = %{ st | count_waiting_resp: st.count_waiting_resp - 1 }
        send_pdus(new_st)
      :bind_transmitter_resp ->
        send_pdus(st)
      _ ->
        {:ok, st}
    end
  end

  def handle_resp_timeout(pdu, st) do
    Logger.error("PDU timeout: #{inspect pdu}, terminating")
    {:stop, :resp_timeout, st}

  end

  def terminate(reason, _, st) do
    Logger.info("ESME stopped with reason #{inspect reason}")
    Kernel.send(st.waiting_pid, {self(), :done})
    st
  end

  def handle_info(:bind, st) do
    {:noreply, [SMPPEX.Pdu.Factory.bind_transmitter(@system_id, @password)], st}
  end

  defp send_pdus(st) do
    cond do
      st.count_to_send > 0 ->
        count_to_send = min(st.window - st.count_waiting_resp, st.count_to_send)
        new_st = %{ st | count_waiting_resp: st.window, count_to_send: st.count_to_send - count_to_send }
        {:ok, make_pdus(count_to_send), new_st}
      st.count_waiting_resp > 0 ->
        {:ok, st}
      true ->
        Logger.info("All PDUs sent, all resps received, terminating")
        {:stop, :normal, st}
    end
  end

  defp make_pdus(0), do: []
  defp make_pdus(n) do
    for _ <- 1..n, do: SMPPEX.Pdu.Factory.submit_sm(@from, @to, @message)
  end

end
