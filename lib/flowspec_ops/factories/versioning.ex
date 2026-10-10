defmodule FlowspecOps.Factories.Versioning do
  @moduledoc """
  Named factory milestones via table-copy (not JSON).

  Working copy = live factory_* tables.
  Save version / Create milestone = parity check + INSERT…SELECT into factory_version_*.
  Restore = safety auto-milestone + replace working copy from a version.
  """

  import Ecto.Query

  alias FlowspecOps.Repo
  alias FlowspecOps.Factories.Factory

  @actor_default "michael"

  # {primary_table, version_table}
  # Keep in sync with migrations. Parity + Save both use this list.
  @version_pairs [
    {"factory_lines", "factory_version_lines"},
    {"skus", "factory_version_skus"},
    {"factory_nodes", "factory_version_nodes"},
    {"factory_links", "factory_version_links"},
    {"factory_node_steps", "factory_version_node_steps"},
    {"factory_node_step_items", "factory_version_node_step_items"}
  ]

  @version_meta_cols MapSet.new(["id", "version_id", "source_id"])

  def version_pairs, do: @version_pairs

  # --- Parity ---------------------------------------------------------------

  @doc """
  Compare primary vs version twin columns.
  Returns `:ok` or `{:error, [message]}`.
  """
  def assert_schema_parity do
    case schema_parity_errors() do
      [] -> :ok
      errors -> {:error, errors}
    end
  end

  def schema_parity_errors do
    Enum.flat_map(@version_pairs, fn {primary, version} ->
      primary_cols = MapSet.new(table_columns(primary))
      version_cols = MapSet.new(table_columns(version))

      if MapSet.size(primary_cols) == 0 do
        ["primary table missing: #{primary}"]
      else
        if MapSet.size(version_cols) == 0 do
          ["version table missing: #{version}"]
        else
          expected_data = MapSet.delete(primary_cols, "id")
          actual_data = MapSet.difference(version_cols, @version_meta_cols)

          missing =
            expected_data
            |> MapSet.difference(actual_data)
            |> Enum.sort()
            |> Enum.map(fn col ->
              "#{primary}.#{col} missing on #{version}"
            end)

          meta_missing =
            ["version_id", "source_id"]
            |> Enum.reject(&MapSet.member?(version_cols, &1))
            |> Enum.map(fn col -> "#{version} missing meta column #{col}" end)

          missing ++ meta_missing
        end
      end
    end)
  end

  defp table_columns(table) do
    rows =
      Repo.query!(
        """
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = $1
        ORDER BY ordinal_position
        """,
        [table]
      )

    Enum.map(rows.rows, fn [name] -> name end)
  end

  # --- List -----------------------------------------------------------------

  def list_versions(factory_id) do
    Repo.all(
      from v in "factory_versions",
        where: v.factory_id == ^factory_id,
        order_by: [desc: v.inserted_at, desc: v.id],
        select: %{
          id: v.id,
          factory_id: v.factory_id,
          name: v.name,
          note: v.note,
          kind: v.kind,
          created_by: v.created_by,
          inserted_at: v.inserted_at
        }
    )
  end

  def get_version!(version_id) do
    Repo.one!(
      from v in "factory_versions",
        where: v.id == ^version_id,
        select: %{
          id: v.id,
          factory_id: v.factory_id,
          name: v.name,
          note: v.note,
          kind: v.kind,
          created_by: v.created_by,
          factory_name: v.factory_name,
          factory_slug: v.factory_slug,
          client_id: v.client_id,
          inserted_at: v.inserted_at
        }
    )
  end

  # --- Save -----------------------------------------------------------------

  @doc """
  Create a named milestone of the current working copy.
  Fails closed if schema parity is broken.
  """
def save_version(%Factory{} = factory, attrs) when is_map(attrs) do
    name =
      attrs
      |> pick(:name)
      |> to_string()
      |> String.trim()

    note = attrs |> pick(:note) |> blank_to_nil()
    kind = attrs |> pick(:kind) || "milestone"
    actor = attrs |> pick(:created_by) || @actor_default

    cond do
      name == "" ->
        {:error, :name_required}

      true ->
        case assert_schema_parity() do
          {:error, errors} ->
            {:error, {:schema_parity, errors}}

          :ok ->
            Repo.transaction(fn -> save_version_in_tx!(factory, name, note, kind, actor) end)
        end
    end
  end

  defp pick(attrs, key) do
    Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))
  end

  # Assumes caller already opened a transaction when needed for nesting.
  defp save_version_in_tx!(factory, name, note, kind, actor) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    {:ok, %{rows: [[version_id]]}} =
      Repo.query(
        """
        INSERT INTO factory_versions
          (factory_id, name, note, kind, created_by,
           factory_name, factory_slug, client_id,
           inserted_at)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
        RETURNING id
        """,
        [
          factory.id,
          name,
          note,
          kind,
          actor,
          factory.name,
          factory.slug,
          factory.client_id,
          now
        ]
      )

    copy_lines!(version_id, factory.id)
    copy_skus!(version_id, factory.id)
    copy_nodes!(version_id, factory.id)
    copy_links!(version_id, factory.id)
    copy_steps!(version_id, factory.id)
    copy_step_items!(version_id, factory.id)

    log!(factory.id, actor, "Saved milestone “#{name}”", "factory_version", version_id, version_id)

    get_version!(version_id)
  end

  defp copy_lines!(version_id, factory_id) do
    Repo.query!(
      """
      INSERT INTO factory_version_lines
        (version_id, source_id, factory_id, name, position, master_production_line_id, inserted_at, updated_at)
      SELECT $1, id, factory_id, name, position, master_production_line_id, inserted_at, updated_at
      FROM factory_lines WHERE factory_id = $2
      """,
      [version_id, factory_id]
    )
  end

  defp copy_skus!(version_id, factory_id) do
    Repo.query!(
      """
      INSERT INTO factory_version_skus
        (version_id, source_id, factory_id, name, code, inserted_at, updated_at)
      SELECT $1, id, factory_id, name, code, inserted_at, updated_at
      FROM skus WHERE factory_id = $2
      """,
      [version_id, factory_id]
    )
  end

  defp copy_nodes!(version_id, factory_id) do
    Repo.query!(
      """
      INSERT INTO factory_version_nodes
        (version_id, source_id, factory_id, line_id, kind, name, position,
         bypass_allowed, note, queue_role, slots, storage_group, crew_size,
         standup_weeks, standup_people, standup_source, standup_note,
         inspection_point, gate, product_ready, method_instruction, location_note,
         lead_time_days, supply_cadence, supply_batch, supply_frequency_days, setup_days, first_batch_days, first_batch_qty,
                 production_batch_slots, transport_duration_minutes, from_location, to_location,
                 vendor_name, batch_size, ship_weekday, transit_days, inserted_at, updated_at)
               SELECT $1, id, factory_id, line_id, kind, name, position,
                 bypass_allowed, note, queue_role, slots, storage_group, crew_size,
                 standup_weeks, standup_people, standup_source, standup_note,
                 inspection_point, gate, product_ready, method_instruction, location_note,
                 lead_time_days, supply_cadence, supply_batch, supply_frequency_days, setup_days, first_batch_days, first_batch_qty,
                 production_batch_slots, transport_duration_minutes, from_location, to_location,
                 vendor_name, batch_size, ship_weekday, transit_days, inserted_at, updated_at
               FROM factory_nodes WHERE factory_id = $2
      """,
      [version_id, factory_id]
    )
  end

  defp copy_links!(version_id, factory_id) do
    Repo.query!(
      """
      INSERT INTO factory_version_links
        (version_id, source_id, factory_id, from_node_id, to_node_id, label, sku_filter,
         inserted_at, updated_at)
      SELECT $1, id, factory_id, from_node_id, to_node_id, label, sku_filter,
         inserted_at, updated_at
      FROM factory_links WHERE factory_id = $2
      """,
      [version_id, factory_id]
    )
  end

  defp copy_steps!(version_id, factory_id) do
    Repo.query!(
      """
      INSERT INTO factory_version_node_steps
        (version_id, source_id, factory_node_id, name, position, estimated_minutes,
         minutes_each, qty_per_unit, people, specs, shared, parallel_with_step_id,
         duration_days, inserted_at, updated_at)
      SELECT $1, s.id, s.factory_node_id, s.name, s.position, s.estimated_minutes,
         s.minutes_each, s.qty_per_unit, s.people, s.specs, s.shared, s.parallel_with_step_id,
         s.duration_days, s.inserted_at, s.updated_at
      FROM factory_node_steps s
      INNER JOIN factory_nodes n ON n.id = s.factory_node_id
      WHERE n.factory_id = $2
      """,
      [version_id, factory_id]
    )
  end

  defp copy_step_items!(version_id, factory_id) do
    Repo.query!(
      """
      INSERT INTO factory_version_node_step_items
        (version_id, source_id, factory_node_step_id, kind, name, qty, unit_cost_cents,
         pack_qty, position, note, inserted_at, updated_at)
      SELECT $1, i.id, i.factory_node_step_id, i.kind, i.name, i.qty, i.unit_cost_cents,
         i.pack_qty, i.position, i.note, i.inserted_at, i.updated_at
      FROM factory_node_step_items i
      INNER JOIN factory_node_steps s ON s.id = i.factory_node_step_id
      INNER JOIN factory_nodes n ON n.id = s.factory_node_id
      WHERE n.factory_id = $2
      """,
      [version_id, factory_id]
    )
  end

  # --- Restore --------------------------------------------------------------

  @doc """
  Replace working copy with a version. Auto-saves current state first.
  """
  def restore_version(%Factory{} = factory, version_id, opts \\ []) do
    actor = Keyword.get(opts, :created_by, @actor_default)
    version = get_version!(version_id)

    if version.factory_id != factory.id do
      {:error, :version_factory_mismatch}
    else
      case assert_schema_parity() do
        {:error, errors} ->
          {:error, {:schema_parity, errors}}

:ok ->
          Repo.transaction(fn ->
            # Safety freeze of current working copy (same transaction)
            _auto =
              save_version_in_tx!(
                factory,
                "Auto before restore · #{version.name}",
                "Safety snapshot before restoring version ##{version.id}",
                "auto",
                actor
              )

            wipe_working_copy!(factory.id)
            maps = reinsert_from_version!(factory.id, version)

            factory
            |> Ecto.Changeset.change(%{
              name: version.factory_name,
              slug: version.factory_slug
            })
            |> Repo.update!()

            log!(
              factory.id,
              actor,
              "Restored milestone “#{version.name}”",
              "factory_version",
              version.id,
              version.id
            )

            %{version: version, id_maps: maps}
          end)
      end
    end
  end

  defp wipe_working_copy!(factory_id) do
    # Order: items → steps → links → nodes → skus → lines
    Repo.query!(
      """
      DELETE FROM factory_node_step_items i
      USING factory_node_steps s, factory_nodes n
      WHERE i.factory_node_step_id = s.id
        AND s.factory_node_id = n.id
        AND n.factory_id = $1
      """,
      [factory_id]
    )

    Repo.query!(
      """
      DELETE FROM factory_node_steps s
      USING factory_nodes n
      WHERE s.factory_node_id = n.id AND n.factory_id = $1
      """,
      [factory_id]
    )

    Repo.query!("DELETE FROM factory_links WHERE factory_id = $1", [factory_id])
    Repo.query!("DELETE FROM factory_nodes WHERE factory_id = $1", [factory_id])
    Repo.query!("DELETE FROM skus WHERE factory_id = $1", [factory_id])
    Repo.query!("DELETE FROM factory_lines WHERE factory_id = $1", [factory_id])
  end

  defp reinsert_from_version!(factory_id, version) do
    version_id = version.id
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    line_map = restore_lines!(version_id, factory_id, now)
    _sku_map = restore_skus!(version_id, factory_id, now)
    node_map = restore_nodes!(version_id, factory_id, line_map, now)
    restore_links!(version_id, factory_id, node_map, now)
    step_map = restore_steps!(version_id, node_map, now)
    restore_step_items!(version_id, step_map, now)

    %{lines: line_map, nodes: node_map, steps: step_map}
  end

  defp restore_lines!(version_id, factory_id, now) do
    %{rows: rows} =
      Repo.query!(
        """
        SELECT source_id, name, position, master_production_line_id, inserted_at, updated_at
        FROM factory_version_lines WHERE version_id = $1 ORDER BY position, source_id
        """,
        [version_id]
      )

    Enum.reduce(rows, %{}, fn [source_id, name, position, mpl_id, ins, upd], acc ->
      {:ok, %{rows: [[new_id]]}} =
        Repo.query(
          """
          INSERT INTO factory_lines (factory_id, name, position, master_production_line_id, inserted_at, updated_at)
          VALUES ($1,$2,$3,$4,$5,$6) RETURNING id
          """,
          [factory_id, name, position, mpl_id, ins || now, upd || now]
        )

      Map.put(acc, source_id, new_id)
    end)
  end

  defp restore_skus!(version_id, factory_id, now) do
    %{rows: rows} =
      Repo.query!(
        "SELECT source_id, name, code, inserted_at, updated_at FROM factory_version_skus WHERE version_id = $1",
        [version_id]
      )

    Enum.reduce(rows, %{}, fn [source_id, name, code, ins, upd], acc ->
      {:ok, %{rows: [[new_id]]}} =
        Repo.query(
          """
          INSERT INTO skus (factory_id, name, code, inserted_at, updated_at)
          VALUES ($1,$2,$3,$4,$5) RETURNING id
          """,
          [factory_id, name, code, ins || now, upd || now]
        )

      Map.put(acc, source_id, new_id)
    end)
  end

  defp restore_nodes!(version_id, factory_id, line_map, now) do
    %{rows: rows} =
      Repo.query!(
        """
        SELECT source_id, line_id, kind, name, position, bypass_allowed, note,
               queue_role, slots, storage_group, crew_size,
               standup_weeks, standup_people, standup_source, standup_note,
               inspection_point, gate,
               product_ready, method_instruction, location_note, lead_time_days,
                              supply_cadence, supply_batch, supply_frequency_days, setup_days, first_batch_days, first_batch_qty,
                              production_batch_slots, transport_duration_minutes, from_location,
                              to_location, vendor_name, batch_size, ship_weekday, transit_days,
                              inserted_at, updated_at
                       FROM factory_version_nodes WHERE version_id = $1 ORDER BY position, source_id
        """,
        [version_id]
      )

    Enum.reduce(rows, %{}, fn row, acc ->
      [
        source_id,
        line_id,
        kind,
        name,
        position,
        bypass_allowed,
        note,
        queue_role,
        slots,
        storage_group,
        crew_size,
        standup_weeks,
        standup_people,
        standup_source,
        standup_note,
        inspection_point,
        gate,
        product_ready,
        method_instruction,
        location_note,
        lead_time_days,
                supply_cadence,
                supply_batch,
                supply_frequency_days,
                setup_days,
                first_batch_days,
                first_batch_qty,
                production_batch_slots,
                transport_duration_minutes,
                from_location,
                to_location,
                vendor_name,
                batch_size,
                ship_weekday,
                transit_days,
                ins,
                upd
              ] = row

      new_line_id = if line_id, do: Map.fetch!(line_map, line_id), else: nil

      {:ok, %{rows: [[new_id]]}} =
        Repo.query(
          """
          INSERT INTO factory_nodes
            (factory_id, line_id, kind, name, position, bypass_allowed, note,
             queue_role, slots, storage_group, crew_size,
             standup_weeks, standup_people, standup_source, standup_note,
             inspection_point, gate,
             product_ready, method_instruction, location_note, lead_time_days,
             supply_cadence, supply_batch, supply_frequency_days, setup_days, first_batch_days, first_batch_qty,
             production_batch_slots, transport_duration_minutes, from_location,
             to_location, vendor_name, batch_size, ship_weekday, transit_days,
             inserted_at, updated_at)
          VALUES
            ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,
             $21,$22,$23,$24,$25,$26,$27,$28,$29,$30,$31,$32,$33,$34,$35,$36,$37)
          RETURNING id
          """,
          [
            factory_id,
            new_line_id,
            kind,
            name,
            position,
            bypass_allowed || false,
            note,
            queue_role,
            slots,
            storage_group,
            crew_size,
            standup_weeks,
            standup_people,
            standup_source,
            standup_note,
            inspection_point || false,
            gate || false,
            product_ready || false,
            method_instruction || false,
            location_note,
            lead_time_days,
            supply_cadence,
            supply_batch,
            supply_frequency_days,
            setup_days,
            first_batch_days,
            first_batch_qty,
            production_batch_slots,
            transport_duration_minutes,
            from_location,
            to_location,
            vendor_name,
            batch_size,
            ship_weekday,
            transit_days,
            ins || now,
            upd || now
          ]
        )

      Map.put(acc, source_id, new_id)
    end)
  end

  defp restore_links!(version_id, factory_id, node_map, now) do
    %{rows: rows} =
      Repo.query!(
        """
        SELECT source_id, from_node_id, to_node_id, label, sku_filter, inserted_at, updated_at
        FROM factory_version_links WHERE version_id = $1
        """,
        [version_id]
      )

    Enum.each(rows, fn [source_id, from_id, to_id, label, sku_filter, ins, upd] ->
      _ = source_id

      Repo.query!(
        """
        INSERT INTO factory_links
          (factory_id, from_node_id, to_node_id, label, sku_filter, inserted_at, updated_at)
        VALUES ($1,$2,$3,$4,$5,$6,$7)
        """,
        [
          factory_id,
          Map.fetch!(node_map, from_id),
          Map.fetch!(node_map, to_id),
          label,
          sku_filter,
          ins || now,
          upd || now
        ]
      )
    end)
  end

  defp restore_steps!(version_id, node_map, now) do
    %{rows: rows} =
      Repo.query!(
        """
        SELECT source_id, factory_node_id, name, position, estimated_minutes,
               minutes_each, qty_per_unit, people, specs, shared, parallel_with_step_id,
               duration_days, inserted_at, updated_at
        FROM factory_version_node_steps WHERE version_id = $1 ORDER BY position, source_id
        """,
        [version_id]
      )

    # Pass 1: insert without parallel_with
    step_map =
      Enum.reduce(rows, %{}, fn row, acc ->
        [
          source_id,
          node_id,
          name,
          position,
          est,
          minutes_each,
          qty_per_unit,
          people,
          specs,
                    shared,
                    _parallel,
                    duration_days,
                    ins,
                    upd
                  ] = row

        {:ok, %{rows: [[new_id]]}} =
          Repo.query(
            """
            INSERT INTO factory_node_steps
              (factory_node_id, name, position, estimated_minutes, minutes_each,
               qty_per_unit, people, specs, shared, parallel_with_step_id,
               duration_days, inserted_at, updated_at)
            VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,NULL,$10,$11,$12)
            RETURNING id
            """,
            [
              Map.fetch!(node_map, node_id),
              name,
              position,
              est,
              minutes_each,
              qty_per_unit,
              people,
              specs,
              if(is_nil(shared), do: true, else: shared),
                            duration_days,
                            ins || now,
                            upd || now
                          ]
          )

        Map.put(acc, source_id, new_id)
      end)

    # Pass 2: parallel_with refs
    Enum.each(rows, fn row ->
      [source_id, _, _, _, _, _, _, _, _, _, parallel, _, _, _] = row

      if parallel do
        Repo.query!(
          "UPDATE factory_node_steps SET parallel_with_step_id = $1 WHERE id = $2",
          [Map.fetch!(step_map, parallel), Map.fetch!(step_map, source_id)]
        )
      end
    end)

    step_map
  end

  defp restore_step_items!(version_id, step_map, now) do
    %{rows: rows} =
      Repo.query!(
        """
        SELECT source_id, factory_node_step_id, kind, name, qty, unit_cost_cents,
               pack_qty, position, note, inserted_at, updated_at
        FROM factory_version_node_step_items WHERE version_id = $1
        """,
        [version_id]
      )

    Enum.each(rows, fn row ->
      [
        _source_id,
        step_id,
        kind,
        name,
        qty,
        unit_cost_cents,
        pack_qty,
        position,
        note,
        ins,
        upd
      ] = row

      Repo.query!(
        """
        INSERT INTO factory_node_step_items
          (factory_node_step_id, kind, name, qty, unit_cost_cents, pack_qty,
           position, note, inserted_at, updated_at)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
        """,
        [
          Map.fetch!(step_map, step_id),
          kind,
          name,
          qty || 1.0,
          unit_cost_cents,
          pack_qty,
          position || 1,
          note,
          ins || now,
          upd || now
        ]
      )
    end)
  end

  defp log!(factory_id, actor, summary, entity_type, entity_id, version_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    Repo.query!(
      """
      INSERT INTO factory_change_log
        (factory_id, actor, summary, entity_type, entity_id, factory_version_id, inserted_at)
      VALUES ($1,$2,$3,$4,$5,$6,$7)
      """,
      [factory_id, actor, summary, entity_type, entity_id, version_id, now]
    )
  end

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(s) when is_binary(s), do: String.trim(s) |> then(fn t -> if t == "", do: nil, else: t end)
  defp blank_to_nil(other), do: other
end
