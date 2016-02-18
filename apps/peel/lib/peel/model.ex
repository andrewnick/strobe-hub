defmodule Peel.Model do
  defmacro __using__(_) do
    quote do
      import Ecto.Query
      use    Ecto.Schema

      @primary_key {:id, :binary_id, autogenerate: true}

      alias  Peel.Repo
      alias  __MODULE__, as: M

      def first do
        M |> order_by(:id) |> limit(1) |> Repo.one
      end

      def all do
        M |> Repo.all
      end

      def delete_all do
        M |> Repo.delete_all
      end

      def search(title) do
        match = "%#{title}%"
        query = from(c in M,
        where: like(c.title, ^match))
        query |> Repo.all
        # M |> ilike(:title, "%#{title}%") |> Repo.all
      end
    end
  end
end
