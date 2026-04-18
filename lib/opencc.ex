defmodule OpenCC do
  @moduledoc """
  Converts between Simplified and Traditional Chinese.  Elixir wrapper around Rust `ferrous-opencc` crate.
  """
  use GenServer

  # --- public API ---

  @doc """
  Creates a new OpenCC GenServer linked to either a built-in configuration (:s2t, :t2s, :s2hk, :t2hk, :s2tw, :t2tw), or a custom config via a JSON.  Register a name with the optional `:name` parameter.

  Example usage: `OpenCC.start_link(:s2hk, name)`
  """
  def start_link(opts) do
    name = Keyword.get(opts, :name)

    # determine initialization strategy
    init_arg = cond do
      Keyword.has_key?(opts, :built_in) ->
        {:built_in, Keyword.get(opts, :built_in)}
      Keyword.has_key?(opts, :custom) ->
        {:custom, Keyword.get(opts, :custom)}
      true ->
        raise ArgumentError, "Must provide :built_in or :custom config in opts"
    end

    if name do
      GenServer.start_link(__MODULE__, init_arg, name: name)
    else
      GenServer.start_link(__MODULE__, init_arg)
    end
  end

  @doc """
  Generates the child spec using :name as :id, so multiple instances can be started in the supervision tree and independently referred to.
  """
  def child_spec(opts) do
    %{
      id: Keyword.get(opts, :name, __MODULE__),
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  # Keep new/1 and new/2 for backward compatibility or simple scripting
  def new(built_in) when is_atom(built_in), do: start_link(built_in: built_in)

  def new(:custom, path) do
    start_link(custom: path)
  end

  @doc """
  Converts a string of text. Returns `{:ok, converted_text}`.
  """
  def convert(server, text) when is_binary(text) do
    GenServer.call(server, {:convert, text})
  end

  @doc """
  Converts a string of text, raising an error if it fails.
  """
  def convert!(pid, text) do
    case convert(pid, text) do
      {:ok, result} -> result
      {:error, reason} -> raise "OpenCC conversion failed: #{inspect(reason)}"
    end
  end

  @doc """
  Stops the GenServer, safely dropping the Rust resource memory.
  """
  def destroy(pid) do
    GenServer.stop(pid)
  end

  # --- GenServer Callbacks ---

  @impl true
  def init({:built_in, built_in}) do
    # converts Elixir atom to string for matching in Rust
    case OpenCC.Native.new_builtin(Atom.to_string(built_in)) do
      {:ok, ref} -> {:ok, ref}
      {:error, reason} -> {:stop, reason}
    end
  end

  @impl true
  def init({:custom, path}) do
    case OpenCC.Native.new_custom(path) do
      {:ok, ref} -> {:ok, ref}
      {:error, reason} -> {:stop, reason}
    end
  end

  @impl true
  def handle_call({:convert, text}, _from, ref) do
    case OpenCC.Native.convert(ref, text) do
      {:ok, converted_text} -> {:reply, {:ok, converted_text}, ref}
      {:error, reason} -> {:reply, {:error, reason}, ref}
    end
  end

end
