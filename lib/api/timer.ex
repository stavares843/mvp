defmodule API.Timer do
  use AppWeb, :controller
  alias App.Timer
  import Ecto.Changeset

  def index(conn, params) do
    item_id = Map.get(params, "item_id")

    timers = Timer.list_timers(item_id)
    json(conn, timers)
  end

  def show(conn, %{"id" => id} = _params) do
    case Integer.parse(id) do
      # ID is an integer
      {id, _float} ->
        case Timer.get_timer(id) do
          nil ->
            errors = %{
              code: 404,
              message: "No timer found with the given \'id\'."
            }

            json(conn |> put_status(404), errors)

          timer ->
            json(conn, timer)
        end

      # ID is not an integer
      :error ->
        errors = %{
          code: 400,
          message: "Timer \'id\' should be an integer."
        }

        json(conn |> put_status(400), errors)
    end
  end

  def create(conn, params) do
    now = NaiveDateTime.to_string(NaiveDateTime.utc_now())

    # Attributes to create timer
    attrs = %{
      item_id: Map.get(params, "item_id"),
      start: Map.get(params, "start", now),
      stop: Map.get(params, "stop")
    }

    case Timer.start(attrs) do
      # Successfully creates item
      {:ok, timer} ->
        id_timer = Map.take(timer, [:id])
        json(conn, id_timer)

      # Error creating item
      {:error, %Ecto.Changeset{} = changeset} ->
        errors = make_changeset_errors_readable(changeset)

        json(
          conn |> put_status(400),
          errors
        )
    end
  end

  def update(conn, params) do
    id = Map.get(params, "id")

    # Attributes to update timer
    attrs_to_update = %{
      start: Map.get(params, "start"),
      stop: Map.get(params, "stop")
    }

    case Timer.get_timer(id) do
      nil ->
        errors = %{
          code: 404,
          message: "No timer found with the given \'id\'."
        }

        json(conn |> put_status(404), errors)

      # If timer is found, try to update it
      timer ->
        case Timer.update_timer(timer, attrs_to_update) do
          # Successfully updates timer
          {:ok, timer} ->
            json(conn, timer)

          # Error creating timer
          {:error, %Ecto.Changeset{} = changeset} ->
            errors = make_changeset_errors_readable(changeset)

            json(
              conn |> put_status(400),
              errors
            )
        end
    end
  end

  defp make_changeset_errors_readable(changeset) do
    errors = %{
      code: 400,
      message: "Malformed request"
    }

    changeset_errors = traverse_errors(changeset, fn {msg, _opts} -> msg end)
    Map.put(errors, :errors, changeset_errors)
  end
end
