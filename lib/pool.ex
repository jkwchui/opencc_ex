defmodule OpenCC.Pool do
  @moduledoc """
  A NimblePool for concurrent OpenCC conversions.
  """
  @behaviour NimblePool

  # --- Client API ---

  def child_spec(opts) do
    %{
      id: Keyword.get(opts, :name, __MODULE__),
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    pool_size = Keyword.get(opts, :pool_size, System.schedulers_online())

    # pass opts down as worker config
    NimblePool.start_link(
      worker: {__MODULE__, opts},
      pool_size: pool_size,
      name: name
    )
  end

  def convert(pool_name, text) when is_binary(text) do
    # checkout a Rust ref from the pool
    # doing the work in the CALLER's process
    NimblePool.checkout!(pool_name, :checkout, fn _pool_pid, ref ->
      result = OpenCC.Native.convert(ref, text)
      {result, ref}
    end)
  end

  # --- NimblePool callbacks ---

  @impl NimblePool
  def init_worker(pool_state) do
    opts = pool_state

    # initialize the Rust NIF instance
    result = cond do
      Keyword.has_key?(opts, :built_in) ->
        OpenCC.Native.new_builtin(Atom.to_string(opts[:built_in]))
      Keyword.has_key?(opts, :custom) ->
        OpenCC.Native.new_custom(opts[:custom])
    end

    case result do
      {:ok, ref} -> {:ok, ref, pool_state}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl NimblePool
  def handle_checkout(:checkout, _from, ref, pool_state) do
    # give the ref to the caller
    {:ok, ref, ref, pool_state}
  end

  @impl NimblePool
  def handle_checkin(_result, _from, ref, pool_state) do
    # take the ref back into the pool
    {:ok, ref, pool_state}
  end

  @impl NimblePool
  def terminate_worker(_reason, _ref, _pool_state) do
    # rust NIF memory drops automatically on GC
    :ok
  end
end
