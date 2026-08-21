defmodule Mix.Tasks.Flowspec.Versions.Parity do
  use Mix.Task

  @shortdoc "Fail hard if factory version twin tables drift from primaries"

  @moduledoc """
  VERSION SCHEMA PARITY gate for factory milestones.

  Run after any factory schema migration:

      mix flowspec.versions.parity

  Exit non-zero with explicit missing-column messages when twins drift.
  Milestone Save also runs this check and blocks on failure.
  """

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")

    case FlowspecOps.Factories.Versioning.assert_schema_parity() do
      :ok ->
        Mix.shell().info("VERSION SCHEMA PARITY OK")
        Mix.shell().info("Pairs checked: #{length(FlowspecOps.Factories.Versioning.version_pairs())}")

      {:error, errors} ->
        Mix.shell().error("VERSION SCHEMA PARITY FAILED")
        Mix.shell().error("Milestone Save is blocked until fixed.")
        Mix.shell().error("Add the same column in this migration to the factory_version_* twin.")
        Enum.each(errors, fn msg -> Mix.shell().error("  • #{msg}") end)
        System.halt(1)
    end
  end
end
