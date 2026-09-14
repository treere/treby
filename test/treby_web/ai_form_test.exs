defmodule TrebyWeb.AIFormTest do
  use ExUnit.Case, async: true
  import Phoenix.Component, only: [to_form: 1]

  alias TrebyWeb.AIForm

  defp form_with(_values) do
    %Treby.Jobs.Job{}
    |> Ecto.Changeset.change(%{})
    |> then(&Ecto.Changeset.put_change(&1, :title, "seed"))
    |> to_form()
  end

  defp form_value(socket, field) do
    socket.assigns.form.source |> Ecto.Changeset.get_change(field)
  end

  test "merges known fields into the form changeset" do
    socket = %Phoenix.LiveView.Socket{assigns: %{form: form_with(%{})}}
    updated = AIForm.apply_values(socket, :form, %{"title" => "Senior Elixir", "salary_range" => "60-80k"})

    assert form_value(updated, :title) == "Senior Elixir"
    assert form_value(updated, :salary_range) == "60-80k"
  end

  test "ignores unknown fields and missing forms" do
    socket = %Phoenix.LiveView.Socket{assigns: %{form: form_with(%{})}}
    updated = AIForm.apply_values(socket, :form, %{"title" => "X", "ghost_field" => "y"})

    assert form_value(updated, :title) == "X"
    assert form_value(updated, :ghost_field) == nil

    no_form = AIForm.apply_values(%Phoenix.LiveView.Socket{assigns: %{}}, :form, %{"title" => "X"})
    assert no_form.assigns == %{}
  end
end
