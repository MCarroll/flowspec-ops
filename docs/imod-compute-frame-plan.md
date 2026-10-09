# iMod Compute Frame Plan

**Deliverable for:** Rick (S3h), Reed (iMod), Art (Eps)
**Date:** 2026-10-07
**Author:** Michael Carroll

---

## 1. What the iMod Factory Will Build

iMod is a modular structural frame system — asset-class frames designed to be leased and moved to where application demand is. The factory builds:

### Frame System
- Welded steel moment frames (seismic rated), stackable 2x high, open sides
- Standardized frame sections that bolt together in any configuration
- Electrically continuous for Faraday protection (single-point ground)

### Module Types
| Module | Function | Contents |
|--------|----------|----------|
| **PDU** | Power distribution | Solar, battery, grid tie, inverter, ATS, PDUs, monitoring |
| **CDU** | Cooling distribution | Manifolds, pumps, heat rejection, coolant, sensors |
| **Computer/Network** | Compute | DDC S-4 (52U, S4-GPU), NVIDIA B300 servers, switches, fiber, KVM |

### Compute Module: DDC S-4 (52U, S4-GPU)
- Heat abatement: Up to 85 kW air-only cooling
- Cabinet power draw: 9 kW (nameplate)
- Dimensions: 127" H x 30" W x 82" D (3226 x 762 x 2082 mm)
- Weight: 860 lbs
- Power: 208/230-415/460 3P @ 50/60Hz
- PDUs: Up to 5 per side A/B power
- Cooling: Dual redundant coils, dual series fans, 0-36 USGPM
- Liquid-to-chip: Optional provisioning
- DCIM: DDC software standard, BMS integration optional
- NEMA: 3R (outdoor rated)

### Server Platform
- NVIDIA B300 (Blackwell Ultra) by SuperMicro
- Networking: NVIDIA Spectrum-4 800GbE Ethernet with RoCE (primary); Quantum-2 NDR 400G InfiniBand (alternative for large-scale training)

### Uptime Standard
Tier 3 (Uptime Institute) — concurrently maintainable, N+1 redundancy on all critical systems, dual power feeds, 99.982% uptime (1.6h downtime/year), no single point of failure.

### Faraday Protection
- Frame: Conductive (steel preferred); all joints bonded with strap or weld
- Panels: Conductive mesh (for ventilation) or solid metal (for walls/roof)
- Doors: Conductive gasket around full perimeter; latch maintains contact
- Penetrations: Power (feedthrough filters), Cooling (honeycomb waveguide vents), Data (fiber optic or shielded Ethernet with feedthrough filters)
- Ground: Single-point ground to earth rod or building ground

---

## 2. How It Will Ship to the Site

- Modules are self-contained units that ship as completed assemblies
- Frame sections ship as standardized bolt-together components
- Modules are crated/palleted for freight; lift-gate or flatbed delivery
- Shipping configuration: modules nested or side-by-side to minimize freight volume
- Each module has a unique ID and shipping manifest (contents, weight, handling instructions)
- Modules arrive ready to place in frame — no field fabrication required

---

## 3. How It Will Be Assembled on the Site

1. **Site prep:** Level pad or foundation; seismic anchoring if required; utility connections (grid, water, fiber) stubbed to site
2. **Frame assembly:** Frame sections bolted together on-site; moment frame connections torqued to spec; grounding system installed
3. **Module placement:** PDU, CDU, and Computer/Network modules placed in frame (crane or forklift); modules bolt to frame
4. **Interconnections:** Power cables between PDU and Computer/Network modules; cooling piping between CDU and Computer/Network modules; fiber between modules
5. **Faraday completion:** Panels, doors, and penetrations installed; continuity tested
6. **Commissioning:** Power up, cooling on, compute online, Faraday verified, DCIM monitoring active

---

## 4. How Additional Equipment Will Be Configured, Packed and Shipped

- Additional equipment (spare parts, tools, test equipment, documentation) is configured and packed per module
- Each module ships with its own accessory kit: spare PDUs, spare fans, spare pumps, cable management, fasteners, test cables
- Documentation ships with each module: wiring diagrams, piping diagrams, assembly instructions, test procedures
- Spare compute nodes (servers, switches) ship as separate line items with their own packing lists
- All equipment labeled with module ID and destination site ID

---

## 5. Teams and Crews Needed to Assemble the Equipment, Fixtures, Cooling, Power and Compute

| Crew | Responsibility | Size |
|------|---------------|------|
| **Frame crew** | Frame assembly, bolting, grounding, seismic anchoring | 2-3 |
| **Electrical crew** | PDU install, power connections, grid tie, solar/battery hookup | 2-3 |
| **Mechanical crew** | CDU install, cooling piping, pumps, heat rejection | 2-3 |
| **Compute crew** | S-4 placement, server install, networking, fiber | 2-4 |
| **Commissioning lead** | System integration, testing, DCIM setup, customer handoff | 1-2 |

Total site crew: 8-15 people depending on deployment size.

---

## 6. Turning the System Over to the Customer

1. **Pre-turnover test:** Full system test — power, cooling, compute, Faraday, DCIM — with customer witness
2. **Documentation handoff:** As-built drawings, wiring/piping diagrams, O&M manuals, test reports, warranty documents
3. **Training:** Customer operations training (power up/down, cooling modes, compute management, DCIM monitoring, basic troubleshooting)
4. **Formal turnover:** Signed acceptance certificate; system goes into warranty period
5. **Support transition:** Customer support contact established; remote monitoring active

---

## 7. Warranty and Maintenance

- **Warranty:** 12 months full system warranty (parts and labor) from turnover date
- **Preventive maintenance:** Quarterly PM — filter changes, coolant checks, battery health, fan/pump inspection, Faraday continuity test
- **Corrective maintenance:** Remote diagnostics first; on-site dispatch if needed; 24/7 support hotline
- **DCIM monitoring:** Continuous remote monitoring of power, cooling, compute health; alerts to customer and iMod support
- **Spare parts:** Consumables (filters, fans, pumps) stocked at customer site or regional depot

---

## 8. Upgrading System

- **Compute upgrades:** Additional S-4 modules or server nodes added to existing frame; frame is expandable by design
- **Power upgrades:** Additional PDU modules or battery capacity added; solar array expanded
- **Cooling upgrades:** Additional CDU modules or heat rejection capacity added
- **Firmware/software:** DCIM, BMS, and server firmware updated remotely or on-site
- **Upgrade process:** Assess capacity → design upgrade → factory-build new modules → ship → install → commission → turnover

---

## 9. Moving System to Another Location

iMod is designed for relocation — asset-class frames leased and moved to where application demand is.

1. **Decommission:** Power down, cooling off, compute offline; disconnect power, cooling, fiber
2. **Module extraction:** Modules unbolted from frame; prepared for shipping (crated/palleted)
3. **Frame disassembly:** Frame sections unbolted; prepared for shipping
4. **Ship to new location:** Modules and frame sections shipped as units
5. **Reassemble at new site:** Follow assembly process (Section 3)
6. **Recommission:** Full system test; turnover to customer at new location
7. **Site restoration:** Original site restored to pre-installation condition

---

## 10. BOM (Top-Level)

| Category | Items |
|----------|-------|
| Frame | Steel tubing, welding/bonding materials, moment frame connections |
| Faraday | Mesh panels, solid panels, conductive gaskets, feedthrough filters, ground rod |
| Power (PDU) | Solar panels, LiFePO4 batteries, hybrid inverter, ATS, PDUs, wiring |
| Cooling (CDU) | Cold plates/immersion tanks, manifolds, pumps, dry cooler, coolant, sensors |
| Compute (Computer/Network) | DDC S-4 (52U, S4-GPU), NVIDIA B300 servers, Spectrum-4 switches, fiber, KVM |

---

## 11. Open Questions

- Exact frame dimensions (indoor vs. outdoor installation)?
- Compute load (kW) to size power and cooling?
- Budget range?
- Timeline for build?
- Location (grid access, solar exposure, seismic)?

---

## 12. Next Steps

1. Answer open questions
2. Detailed frame drawings
3. Power and cooling sizing calculations
4. Full BOM with part numbers
5. Build schedule
