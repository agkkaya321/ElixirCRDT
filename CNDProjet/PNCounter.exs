defmodule PNCounter do
  @moduledoc """
  Implémentation d'un PN-Counter (Positive-Negative Counter).
  """

  def new do
    {%{}, %{}}
  end

  def update({state_p, state_n} = state, id, delta) when delta > 0 do
    updated_state_p = Map.update(state_p, id, delta, &(&1 + delta))
    {updated_state_p, state_n}
  end

  def update({state_p, state_n}, id, delta) when delta < 0 do
    updated_state_n = Map.update(state_n, id, -delta, &(&1 - delta))
    {state_p, updated_state_n}
  end

  def update(state, _id, 0) do
    # On ignore simplement si delta = 0
    state
  end

  def merge({p1, n1}, {p2, n2}) do
    merged_p = Map.merge(p1, p2, fn _key, v1, v2 -> max(v1, v2) end)
    merged_n = Map.merge(n1, n2, fn _key, v1, v2 -> max(v1, v2) end)
    {merged_p, merged_n}
  end

  def value({state_p, state_n}) do
    Enum.sum(Map.values(state_p)) - Enum.sum(Map.values(state_n))
  end

  def detailed_values({state_p, state_n}) do
    keys = (Map.keys(state_p) ++ Map.keys(state_n)) |> Enum.uniq()

    Enum.reduce(keys, %{}, fn key, acc ->
      p_value = Map.get(state_p, key, 0)
      n_value = Map.get(state_n, key, 0)
      Map.put(acc, key, p_value - n_value)
    end)
  end
end
