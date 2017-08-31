defmodule SMPPBenchmarks.OserlMC do

  @behaviour :gen_mc

  alias :gen_mc, as: GenMC

  @addr {0, 0, 0, 0}

  def start_link(name, port) do
    opts = [addr: @addr, port: port, rps: false]
    GenMC.start_link({:local, name}, __MODULE__, [{:name, name}], opts)
  end

  def init([{:name, name}]) do
    {:ok, %{
      name: name,
      receiver_session: nil,
      transmitter_session: nil,
      msg_id: 0
    }}
  end

  def terminate(_reason, _st) do
    :ok
  end

  def handle_call(_msg, _from, st) do
    {:reply, [], st}
  end

  def handle_cast(_msg, st) do
    {:noreply, st}
  end

  def handle_info(_info, st) do
    {:noreply, st}
  end

  def code_change(_oldvsn, st, _extra) do
    {:ok, st}
  end


  def handle_accept(_pid, _addr, _from, st) do
    {:reply, {:ok, []}, st}
  end

  @esme_ralybnd 0x0005
  @bind_params [system_id: 'oserl_mc', sc_interface_version: 52]

  def handle_bind_receiver(session, _pdu, _from, %{receiver_session: nil} = st) do
    {:reply, {:ok, @bind_params}, st |> Map.put(:receiver_session, session)}
  end
  def handle_bind_receiver(_session, _pdu, _from, st) do
    {:reply, {:error, @esme_ralybnd}, st}
  end

  def handle_bind_transceiver(session, _pdu, _from, %{receiver_session: nil, transmitter_session: nil} = st) do
    {:reply, {:ok, @bind_params}, st |> Map.put(:receiver_session, session) |> Map.put(:transmitter_session, session)}
  end
  def handle_bind_transceiver(_session, _pdu, _from, st) do
    {:reply, {:error, @esme_ralybnd}, st}
  end

  def handle_bind_transmitter(session, _pdu, _from, %{transmitter_session: nil} = st) do
    {:reply, {:ok, @bind_params}, Map.put(st, :transmitter_session, session)}
  end
  def handle_bind_transmitter(_session, _pdu, _from, st) do
    {:reply, {:error, @esme_ralybnd}, st}
  end

  @esme_rprohibited 0x0101

  def handle_broadcast_sm(_pid, _pdu, _from, st) do
    {:reply, {:error, @esme_rprohibited}, st}
  end

  def handle_cancel_broadcast_sm(_pid, _pdu, _from, st) do
    {:reply, {:error, @esme_rprohibited}, st}
  end

  def handle_cancel_sm(_pid, _pdu, _from, st) do
    {:reply, {:ok, []}, st}
  end

  def handle_query_broadcast_sm(_pid, _pdu, _from, st) do
    {:reply, {:error, @esme_rprohibited}, st}
  end

  def handle_query_sm(_pid, _pdu, _from, st) do
    {:reply, {:ok, []}, st}
  end

  def handle_replace_sm(_pid, _pdu, _from, st) do
    {:reply, {:error, @esme_rprohibited}, st}
  end

  def handle_req(_pid, _req, _args, _ref, st) do
    {:noreply, st}
  end

  def handle_resp(_pid, _resp, _ref, st) do
    {:noreply, st}
  end

  def handle_submit_multi(_pid, _pdu, _from, st) do
    {:reply, {:error, @esme_rprohibited}, st}
  end

  def handle_data_sm(_pid, pdu, _from, st) do
    handle_submit_msg(pdu, st)
  end

  def handle_submit_sm(_pid, pdu, _from, st) do
    handle_submit_msg(pdu, st)
  end

  def handle_submit_msg(_pdu, %{msg_id: msg_id} = st) do
    params = [message_id: to_charlist(msg_id)]
    {:reply, {:ok, params}, st |> Map.put(:msg_id, msg_id + 1)}
  end

  def handle_unbind(_pid, _pdu, _from, st) do
    {:reply, :ok, st |> Map.put(:transmitter_session, nil) |> Map.put(:receiver_session, nil)}
  end

  def handle_closed(_pid, _reason, st) do
    {:noreply, st |> Map.put(:transmitter_session, nil) |> Map.put(:receiver_session, nil)}
  end

end
