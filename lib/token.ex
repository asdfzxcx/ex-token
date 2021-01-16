defmodule Token do
  alias __MODULE__

  defstruct assigns: %{},
            halted: false,
            halt_reason: nil

  def new() do
    %Token{}
  end

  def new(assigns) when is_map(assigns) do
    %Token{assigns: assigns}
  end

  def halt(token, reason \\ nil) do
    %Token{token | halted: true, halt_reason: reason}
  end

  def assign(token, key, value) do
    %Token{token | assigns: Map.put(token.assigns, key, value)}
  end

  def assign_to(value, token, key) do
    assign(token, key, value)
  end

  def validate_assign(token, key, check_fn \\ nil)

  def validate_assign(token = %Token{halted: true}, _key, _check_fn) do
    token
  end

  def validate_assign(token, key, check_fn) do
    if has_assign?(token, key) do
      if check_fn != nil && is_function(check_fn, 1) do
        run_check_function(token, key, check_fn)
      else
        token
      end
    else
      err = Error.new("assign with key #{inspect(key)} not found", Map.keys(token.assigns))
      halt(token, err)
    end
  end

  def fetch_assign(token, key) do
    case has_assign?(token, key) do
      true ->
        {:ok, Map.get(token.assigns, key)}

      false ->
        given_key = inspect(key)
        all_keys = Map.keys(token.assigns)
        error = Error.new("assign with key #{given_key} not found", all_keys)
        {:error, error}
    end
  end

  def has_assign?(token, key) do
    Map.has_key?(token.assigns, key)
  end

  def get_assign(token, key) do
    case has_assign?(token, key) do
      true -> {:ok, Map.get(token.assigns, key)}
      false -> {:error, Error.new("assign with key #{inspect(key)} is not set")}
    end
  end

  def get_assign(token, key, default_value) do
    Map.get(token.assigns, key, default_value)
  end

  def remove_assign(token, key) do
    %Token{token | assigns: Map.delete(token.assigns, key)}
  end

  defp run_check_function(token, key, check_fn) do
    case check_fn.(Map.get(token.assigns, key)) do
      true ->
        token

      false ->
        err = Error.new("assign #{inspect(key)} is invalid", Map.get(token.assigns, key))
        halt(token, err)

      result ->
        err =
          Error.new(
            "failed to ensure validity of assign #{inspect(key)}, " <>
              "check function returned non-boolean result",
            result
          )

        halt(token, err)
    end
  end
end
