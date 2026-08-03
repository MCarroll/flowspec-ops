alias FlowspecOps.Repo
alias FlowspecOps.Sales.{ActivityLogEntry, Client, Contact, Offer, Task, TimeEntry}
alias FlowspecOps.Factories.Factory
alias FlowspecOps.Factories.FactoryLine
alias FlowspecOps.Factories.FactoryLink
alias FlowspecOps.Factories.FactorySku
alias FlowspecOps.Factories.FactoryNode
alias FlowspecOps.Factories.FactoryNodeStep

now = DateTime.utc_now() |> DateTime.truncate(:second)

Repo.delete_all(TimeEntry)
Repo.delete_all(Task)
Repo.delete_all(ActivityLogEntry)
Repo.delete_all(Offer)
Repo.delete_all(Contact)
Repo.delete_all(FactoryLink)
Repo.delete_all(FactoryNodeStep)
Repo.delete_all(FactoryNode)
Repo.delete_all(FactoryLine)
Repo.delete_all(FactorySku)
Repo.delete_all(Factory)
Repo.delete_all(Client)

insert_client = fn attrs -> Repo.insert!(Client.changeset(%Client{}, attrs)) end
insert_contact = fn attrs -> Repo.insert!(Contact.changeset(%Contact{}, attrs)) end
insert_factory = fn attrs -> Repo.insert!(Factory.changeset(%Factory{}, attrs)) end
insert_offer = fn attrs -> Repo.insert!(Offer.changeset(%Offer{}, attrs)) end
insert_task = fn attrs -> Repo.insert!(Task.changeset(%Task{}, attrs)) end
insert_log = fn attrs -> Repo.insert!(ActivityLogEntry.changeset(%ActivityLogEntry{}, attrs)) end
insert_time = fn attrs -> Repo.insert!(TimeEntry.changeset(%TimeEntry{}, attrs)) end
insert_line = fn attrs -> Repo.insert!(FactoryLine.changeset(%FactoryLine{}, attrs)) end
insert_sku = fn attrs -> Repo.insert!(FactorySku.changeset(%FactorySku{}, attrs)) end
insert_link = fn attrs -> Repo.insert!(FactoryLink.changeset(%FactoryLink{}, attrs)) end
insert_node = fn attrs -> Repo.insert!(FactoryNode.changeset(%FactoryNode{}, attrs)) end
insert_step = fn attrs -> Repo.insert!(FactoryNodeStep.changeset(%FactoryNodeStep{}, attrs)) end

hhco =
  insert_client.(%{
    name: "Higher Health (HHCO)",
    short_name: "HHCO",
    slug: "hhco",
    stage: :engaged,
    source: "Existing FlowSpec demo",
    aka: nil
  })

hhco_contact =
  insert_contact.(%{
    client_id: hhco.id,
    name: "Max",
    role: "primary_contact",
    email: nil,
    phone: nil
  })

_hhco_task_1 =
  insert_task.(%{
    client_id: hhco.id,
    contact_id: hhco_contact.id,
    title: "Send CaliJane2 invite with visuals",
    commentary: "Invite is blocked pending visuals.",
    next_action: "Attach Graffle diagram and 3D press mold drawing, then send CaliJane2 invite email.",
    status: :blocked,
    block_category: :awaiting_handoff_external,
    block_detail: "Waiting on updated visuals from CAD.",
    blocked_since: DateTime.add(now, -86_400, :second),
    estimated_minutes: 45,
    remaining_estimate_minutes: 45,
    priority: 1
  })

hhco_task_2 =
  insert_task.(%{
    client_id: hhco.id,
    contact_id: hhco_contact.id,
    title: "Create Graffle brand wiring",
    commentary: "Graffle document required to explain company/brand wiring.",
    next_action: "Create and export Graffle document for email attachment.",
    status: :in_progress,
    estimated_minutes: 120,
    remaining_estimate_minutes: 90,
    priority: 2
  })

_hhco_task_3 =
  insert_task.(%{
    client_id: hhco.id,
    contact_id: hhco_contact.id,
    title: "Finalize 3D press mold drawing",
    commentary: "3D press mold drawing needed for client communication packet.",
    next_action: "Finish drawing revision and export shareable file.",
    status: :in_progress,
    estimated_minutes: 180,
    remaining_estimate_minutes: 150,
    priority: 3
  })

insert_time.(%{
  task_id: hhco_task_2.id,
  started_at: DateTime.add(now, -7_200, :second),
  ended_at: DateTime.add(now, -6_300, :second),
  note: "Drafted wireframe layout.",
  billable: true
})

insert_time.(%{
  task_id: hhco_task_2.id,
  started_at: DateTime.add(now, -3_600, :second),
  ended_at: DateTime.add(now, -3_000, :second),
  note: "Refined label system.",
  billable: false
})

s3h =
  insert_client.(%{
    name: "S3H Inc.",
    short_name: "S3H",
    slug: "s3h",
    stage: :prospect,
    source: "Mare Island inbound (iMod visit)",
    aka: nil
  })

_s3h_owner =
  insert_contact.(%{
    client_id: s3h.id,
    name: "Vatche Sarkoyan",
    role: "owner",
    email: nil,
    phone: nil
  })

s3h_contact =
  insert_contact.(%{
    client_id: s3h.id,
    name: "Rick Pomeroy",
    role: "primary_contact",
    email: "rick.pomeroy@s3hinc.com",
    phone: "408-605-3105"
  })

insert_offer.(%{
  client_id: s3h.id,
  title: "Operational Forensics Sprint",
  amount_cents: 1_200_000,
  unit: "flat",
  description: "2-week constraint diagnosis playbook."
})

insert_offer.(%{
  client_id: s3h.id,
  title: "PFEP + Fractional Ops",
  amount_cents: 1_800_000,
  unit: "monthly",
  description: "Embedded ops support, 3-month minimum."
})

insert_offer.(%{
  client_id: s3h.id,
  title: "MEP Implementation",
  amount_cents: 4_800_000,
  unit: "flat",
  description: "8-week dispatch/scheduling infrastructure."
})

insert_task.(%{
  client_id: s3h.id,
  contact_id: s3h_contact.id,
  title: "Schedule discovery call with Rick",
  commentary: "Inbound interest; confirm real data-center pipeline and constraint.",
  next_action: "Confirm 45-minute discovery slot and prep modular productization questions.",
  status: :not_started,
  estimated_minutes: 45,
  remaining_estimate_minutes: 45,
  priority: 4
})

insert_log.(%{
  client_id: s3h.id,
  contact_id: s3h_contact.id,
  kind: :comms,
  author: "Michael",
  body: "Stopped by S3H (no answer), called Rick, sent text/email introducing independent role and request to reconnect.",
  occurred_at: ~U[2026-06-29 16:00:00Z]
})

harbinger =
  insert_client.(%{
    name: "Harbinger Homes",
    short_name: "HH",
    slug: "harbinger-homes",
    stage: :prospect,
    source: "In-person meet on Mare Island",
    aka: "Factory OS"
  })

harbinger_contact =
  insert_contact.(%{
    client_id: harbinger.id,
    name: "Justin Douglas",
    role: "primary_contact",
    email: "jdouglas@harbinger.homes",
    phone: "+1 (205) 246-5429"
  })

insert_offer.(%{
  client_id: harbinger.id,
  title: "Operational Forensics Sprint",
  amount_cents: 1_200_000,
  unit: "flat",
  description: "2-week constraint diagnosis playbook."
})

insert_offer.(%{
  client_id: harbinger.id,
  title: "PFEP + Fractional Ops",
  amount_cents: 1_800_000,
  unit: "monthly",
  description: "Embedded ops support, 3-month minimum."
})

insert_offer.(%{
  client_id: harbinger.id,
  title: "MEP Implementation",
  amount_cents: 4_800_000,
  unit: "flat",
  description: "8-week production system install."
})

insert_task.(%{
  client_id: harbinger.id,
  contact_id: harbinger_contact.id,
  title: "Send contact info to Justin",
  commentary: "Action assigned during 1-hour meeting; cutover date stated as Aug 1.",
  next_action: "Send direct contact details and confirm Monday follow-up.",
  status: :in_progress,
  estimated_minutes: 30,
  remaining_estimate_minutes: 20,
  priority: 5
})

insert_log.(%{
  client_id: harbinger.id,
  contact_id: harbinger_contact.id,
  kind: :comms,
  author: "Michael",
  body: "Met Justin Douglas; open invite extended for Monday visit.",
  occurred_at: ~U[2026-06-26 16:00:00Z]
})

pacha =
  insert_client.(%{
    name: "PACHA Bread Company",
    short_name: "PACHA",
    slug: "pacha",
    stage: :proposal,
    source: "Proposal prepared 2025-11-16",
    aka: nil
  })

pacha_contact =
  insert_contact.(%{
    client_id: pacha.id,
    name: "Adam Hiner",
    role: "owner",
    email: nil,
    phone: nil
  })

insert_offer.(%{
  client_id: pacha.id,
  title: "2D/3D Model of Factory",
  amount_cents: 360_000,
  unit: "flat",
  description: "30–40 hours @ $120/hr; pricing range noted in proposal."
})

insert_task.(%{
  client_id: pacha.id,
  contact_id: pacha_contact.id,
  title: "Collect PACHA site photos + CAD files",
  commentary: "Need photos, markups, and latest DWG files before model build.",
  next_action: "Request photos, markups, and utility schedules from Adam.",
  status: :not_started,
  estimated_minutes: 60,
  remaining_estimate_minutes: 60,
  priority: 6
})

insert_log.(%{
  client_id: pacha.id,
  contact_id: pacha_contact.id,
  kind: :work,
  author: "Michael",
  body: "Prepared proposal for PACHA 2D/3D factory model (30–40 hours @ $120/hr).",
  occurred_at: ~U[2025-11-16 08:00:00Z]
})

imod =
  insert_client.(%{
    name: "iMod Systems",
    short_name: "IMOD",
    slug: "imod",
    stage: :engaged,
    source: "VA Transitional Housing factory kickoff",
    aka: nil
  })

_imod_contact =
  insert_contact.(%{
    client_id: imod.id,
    name: "Reed Walker",
    role: "owner",
    email: nil,
    phone: nil
  })

va_factory =
  insert_factory.(%{
    name: "VA Transitional Housing",
    slug: "va-transitional-housing",
    client_id: imod.id,
    target_qty: 220,
    window_days: 90
  })

# ── Lines: parallel supply + plant path ─────────────────────────────
# Capacity rule: SUM designed rates across Frame MFG A/B; MIN along Frame Line.
# Receiving is ONE shared join node on Frame Line (never duplicated).
mfg_line_a = insert_line.(%{factory_id: va_factory.id, name: "Frame MFG A", position: 1})
mfg_line_b = insert_line.(%{factory_id: va_factory.id, name: "Frame MFG B", position: 2})
frame_line = insert_line.(%{factory_id: va_factory.id, name: "Frame Line", position: 3})

# SKUs: two unit variants
sku_a = insert_sku.(%{factory_id: va_factory.id, code: "SKU-A", name: "Modular Unit — Standard"})
sku_b = insert_sku.(%{factory_id: va_factory.id, code: "SKU-B", name: "Modular Unit — ADA"})
both_skus = "#{sku_a.code},#{sku_b.code}"

# ── Frame MFG A (supply rope 1) ─────────────────────────────────────
frame_mfg_a =
  insert_node.(%{
    factory_id: va_factory.id,
    line_id: mfg_line_a.id,
    kind: :supplier,
    name: "Frame Mfg",
    position: 1,
    inspection_point: false,
    location_note: "Kitchen Podular · Las Vegas",
    setup_days: 30,
    first_batch_days: 7,
    first_batch_qty: nil,
    production_batch_slots: nil,
    lead_time_days: 7,
    supply_cadence: "1 frame / week"
  })

transport_a =
  insert_node.(%{
    factory_id: va_factory.id,
    line_id: mfg_line_a.id,
    kind: :transport,
    name: "Transport",
    position: 2,
    vendor_name: "Mikey's Transport",
    from_location: "Las Vegas, NV",
    to_location: "Vallejo, CA",
    transit_days: 2,
    transport_duration_minutes: 2 * 24 * 60,
    batch_size: 3,
    ship_weekday: "thursday"
  })

# ── Frame MFG B (parallel supply — dosage lever) ────────────────────
frame_mfg_b =
  insert_node.(%{
    factory_id: va_factory.id,
    line_id: mfg_line_b.id,
    kind: :supplier,
    name: "Frame Mfg 2",
    position: 1,
    inspection_point: false,
    location_note: "Second supply path · TBD",
    setup_days: 30,
    first_batch_days: 7,
    lead_time_days: 7,
    supply_cadence: "1 frame / week",
    note: "Parallel rope — add capacity without redrawing the plant path."
  })

transport_b =
  insert_node.(%{
    factory_id: va_factory.id,
    line_id: mfg_line_b.id,
    kind: :transport,
    name: "Transport 2",
    position: 2,
    vendor_name: "Mikey's Transport",
    from_location: "Las Vegas, NV",
    to_location: "Vallejo, CA",
    transit_days: 2,
    transport_duration_minutes: 2 * 24 * 60,
    batch_size: 3,
    ship_weekday: "friday"
  })

# ── Frame Line (plant path — shared Receiving join) ─────────────────
receiving =
  insert_node.(%{
    factory_id: va_factory.id,
    line_id: frame_line.id,
    kind: :work_cell,
    name: "Receiving",
    position: 1,
    inspection_point: true,
    slots: 3,
    crew_size: 4
  })

insert_step.(%{
  factory_node_id: receiving.id,
  name: "Inspect",
  position: 1,
  people: 1
})

insert_step.(%{
  factory_node_id: receiving.id,
  name: "Unload / transfer",
  position: 2,
  people: 4
})

eps_lot_one =
  insert_node.(%{
    factory_id: va_factory.id,
    line_id: frame_line.id,
    kind: :queue,
    name: "Lot One",
    position: 2,
    queue_role: :storage_lot,
    storage_group: "EPS",
    slots: 10,
    location_note: "Near"
  })

# Transfer method for the EPS hold family (shown on the group card)
insert_step.(%{
  factory_node_id: eps_lot_one.id,
  name: "Pull & Setup",
  position: 1,
  people: 2,
  specs: "+equip Hyster Heavy\n+equip Transfer Wheels"
})

insert_step.(%{
  factory_node_id: eps_lot_one.id,
  name: "Tow transfer",
  position: 2,
  people: 2
})

eps_lot_two =
  insert_node.(%{
    factory_id: va_factory.id,
    line_id: frame_line.id,
    kind: :queue,
    name: "Lot Two",
    position: 3,
    queue_role: :storage_lot,
    storage_group: "EPS",
    slots: 20,
    location_note: "Remote"
  })

flooring =
  insert_node.(%{
    factory_id: va_factory.id,
    line_id: frame_line.id,
    kind: :work_cell,
    name: "Flooring",
    position: 4,
    slots: 3
  })

insert_step.(%{factory_node_id: flooring.id, name: "Install flooring panels", position: 1})
insert_step.(%{factory_node_id: flooring.id, name: "Inspect and sign off", position: 2})

ceiling =
  insert_node.(%{
    factory_id: va_factory.id,
    line_id: frame_line.id,
    kind: :work_cell,
    name: "Ceiling",
    position: 5,
    note: "Stub — not yet configured."
  })

walls =
  insert_node.(%{
    factory_id: va_factory.id,
    line_id: frame_line.id,
    kind: :work_cell,
    name: "Walls",
    position: 6,
    note: "Stub — not yet configured."
  })

s3_node =
  insert_node.(%{
    factory_id: va_factory.id,
    line_id: frame_line.id,
    kind: :work_cell,
    name: "S3",
    position: 7,
    note: "Stub — external plumbing path pending."
  })

# Links — supply → Receiving; split to Flooring vs EPS; lots feed Flooring
insert_link.(%{factory_id: va_factory.id, from_node_id: frame_mfg_a.id, to_node_id: transport_a.id, sku_filter: both_skus})
insert_link.(%{factory_id: va_factory.id, from_node_id: transport_a.id, to_node_id: receiving.id, sku_filter: both_skus, label: "×3 Thu"})
insert_link.(%{factory_id: va_factory.id, from_node_id: frame_mfg_b.id, to_node_id: transport_b.id, sku_filter: both_skus})
insert_link.(%{factory_id: va_factory.id, from_node_id: transport_b.id, to_node_id: receiving.id, sku_filter: both_skus, label: "×3 Fri"})
insert_link.(%{factory_id: va_factory.id, from_node_id: receiving.id, to_node_id: flooring.id, sku_filter: both_skus, label: "slot open"})
insert_link.(%{factory_id: va_factory.id, from_node_id: receiving.id, to_node_id: eps_lot_one.id, sku_filter: both_skus, label: "overflow"})
insert_link.(%{factory_id: va_factory.id, from_node_id: receiving.id, to_node_id: eps_lot_two.id, sku_filter: both_skus, label: "overflow"})
insert_link.(%{factory_id: va_factory.id, from_node_id: eps_lot_one.id, to_node_id: flooring.id, sku_filter: both_skus})
insert_link.(%{factory_id: va_factory.id, from_node_id: eps_lot_two.id, to_node_id: flooring.id, sku_filter: both_skus})
insert_link.(%{factory_id: va_factory.id, from_node_id: flooring.id, to_node_id: ceiling.id, sku_filter: both_skus})
insert_link.(%{factory_id: va_factory.id, from_node_id: flooring.id, to_node_id: s3_node.id, label: "SKU-B side path"})
insert_link.(%{factory_id: va_factory.id, from_node_id: ceiling.id, to_node_id: walls.id, sku_filter: both_skus})
