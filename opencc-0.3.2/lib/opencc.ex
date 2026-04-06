defmodule OpenCC do
  @moduledoc """
  Converts between Simplified and Traditional Chinese.  Elixir wrapper around Rust `ferrous-opencc` crate.
  """
  use GenServer

  # --- public API ---

  @doc """
  Creates a new OpenCC GenServer linked to a built-in configuration.

  Example usage: `OpenCC.new(:s2hk)`
  """
  def new(built_in) when is_atom(built_in) do
    GenServer.start_link(__MODULE__, {:built_in, built_in})
  end

  @doc """
  Creates a new OpenCC GenServer usinga custom config JSON file.

  Example usage: `OpenCC.new(:custom, "path/to/custom.json")`
  """
  def new(:custom, path) do
    # using `JSON` module to validate config file before Rust initialization
    with  {:ok, content} <- File.read(path),
          {:ok, _parsed} <- JSON.decode(content)
    do
      GenServer.start_link(__MODULE__, {:custom, path})
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Converts a string of text. Returns `{:ok, converted_text}`.
  """
  def convert(pid, text) when is_binary(text) do
    GenServer.call(pid, {:convert, text})
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
