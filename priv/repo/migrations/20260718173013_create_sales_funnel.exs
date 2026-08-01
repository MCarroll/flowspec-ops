defmodule FlowspecOps.Repo.Migrations.CreateSalesFunnel do
  use Ecto.Migration

  def change do
    create table(:clients) do
      add :name, :string, null: false
      add :short_name, :string, null: false
      add :slug, :string, null: false
      add :stage, :string, null: false
      add :source, :text
      add :aka, :text

      timestamps()
    end

    create unique_index(:clients, [:slug])

    create table(:contacts) do
      add :client_id, references(:clients, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :role, :string, null: false
      add :email, :string
      add :phone, :string

      timestamps()
    end

    create index(:contacts, [:client_id])

    create table(:offers) do
      add :client_id, references(:clients, on_delete: :delete_all), null: false
      add :title, :string, null: false
      add :amount_cents, :integer, null: false
      add :unit, :string, null: false
      add :description, :text

      timestamps()
    end

    create index(:offers, [:client_id])

    create table(:tasks) do
      add :client_id, references(:clients, on_delete: :delete_all), null: false
      add :contact_id, references(:contacts, on_delete: :nilify_all)
      add :title, :string, null: false
      add :commentary, :text
      add :next_action, :text
      add :due_on, :date
      add :status, :string, null: false
      add :block_category, :string
      add :block_detail, :text
      add :blocked_since, :utc_datetime
      add :estimated_minutes, :integer
      add :remaining_estimate_minutes, :integer
      add :priority, :integer, null: false

      timestamps()
    end

    create index(:tasks, [:client_id])
    create index(:tasks, [:contact_id])
    create unique_index(:tasks, [:priority])

    create table(:time_entries) do
      add :task_id, references(:tasks, on_delete: :delete_all), null: false
      add :started_at, :utc_datetime, null: false
      add :ended_at, :utc_datetime, null: false
      add :note, :text
      add :billable, :boolean, null: false, default: false

      timestamps()
    end

    create index(:time_entries, [:task_id])

    create table(:activity_log_entries) do
      add :client_id, references(:clients, on_delete: :delete_all), null: false
      add :contact_id, references(:contacts, on_delete: :nilify_all)
      add :kind, :string, null: false
      add :author, :string, null: false
      add :body, :text, null: false
      add :occurred_at, :utc_datetime, null: false

      timestamps(updated_at: false)
    end

    create index(:activity_log_entries, [:client_id])
    create index(:activity_log_entries, [:contact_id])
    create index(:activity_log_entries, [:kind])

  end
end
