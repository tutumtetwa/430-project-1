# Cleaning and corroboration note

Scope: independent car repair / maintenance shops holding a City of Chicago
**Motor Vehicle Services License** in four North Side community areas
(Lake View, Lincoln Park, Lincoln Square, North Center). Collected 2026-09-30.

## Raw inputs (unchanged)

| File | What it is |
|---|---|
| `raw/chicago_business_licenses_2026-09-30.csv` | Original City of Chicago download (74 rows). Stable raw-row ID = the dataset's `id` column; referenced in MySQL as `LIC:<id>`. |
| `raw/manual_observations.csv` | Manual log, one row per observation (83 rows, `OBS001`–`OBS083`): name, address, or service wording exactly as seen, plus source ID, URL, date, and collector. Referenced as `OBS:<id>`. |
| `raw/snapshots/SRCxx.html` | Saved copy of every cited web page, so grading does not depend on live sites. The only edit: 5 pages (SRC02, 06, 12, 15, 16) embedded a web vendor's Mapbox map key, which was replaced with `pk.REDACTED_MAPBOX_TOKEN` so the repository does not republish third-party credentials. |

Exact license download (SoQL) query:

```
https://data.cityofchicago.org/resource/uupf-x98q.csv?$select=id,license_id,legal_name,doing_business_as_name,address,city,state,zip_code,community_area_name,license_description,business_activity,license_number,license_start_date,expiration_date&$where=license_description='Motor Vehicle Services License' AND community_area_name in('NORTH CENTER','LAKE VIEW','LINCOLN SQUARE','LINCOLN PARK')&$order=community_area_name,doing_business_as_name&$limit=500
```

## Cleaning rules

**Rule 1: One business, one selected location, one standard name and address.**
Use the shop's public trading name (the name on its own sign or website), not the
all-caps legal or DBA string. Write addresses as `number direction street suffix`
in title case, and drop the license's floor or unit tokens (`1ST`, `1`, `# 1ST`).
When the license gives a lot range (e.g. `3731-3739`), keep the single street
number the shop itself publishes, as long as it falls inside that range. If one
company holds licenses at several locations, keep one selected location and do not
count the others as extra businesses.

**Rule 2: Map observed service wording to one of 7 standard services.**
Keep the original text in `business_service.observed_wording` and in the raw log.
Map a phrase only when it names the service itself:

| Standard service | Wording mapped to it (examples) |
|---|---|
| Oil Change | Oil Changes; Fast Oil Change; Oil change and inspection; Oil Changes & Fluid Replacement |
| Tire Service | Tire Services; Tires; Tires for Sale; Tire Rotation; Tire installation; Tire Mounting, Balancing and Flat Repair |
| Wheel Alignment | Wheel Alignment(s); Alignment; Steering, Suspension & Alignment Repair |
| Brake Repair | Brakes; Brake Services; Brake Pad & Rotor Replacement; Brake Inspections & Repair |
| Vehicle Diagnostics | Diagnostics; engine diagnostics; Computer Diagnostic(s); Check Engine Light(s) |
| Transmission Repair | Transmission Services; Transmissions; Clutch & Transmission |
| A/C & Heating Repair | A/C Service; Heating & AC; Car Air Conditioner Repair; A/C & Heating |

Inspection-only wording is **not** mapped. For example, Cassidy's "Alignment
Inspection" is not recorded as Wheel Alignment. A phrase that names two services
becomes two offerings from the same raw row.

## Before → after examples (real rows)

| # | Before (raw) | After (clean) | Rule |
|---|---|---|---|
| 1 | `RELIABLE AUTO REPAIR CENTR INC`, `3401 N ASHLAND AVE` (LIC:2213706-20250216) | `Reliable Auto Repair Center`, `3401 N Ashland Ave` | 1: truncated DBA replaced by public name; title case |
| 2 | `ASHLAND TIRE & AUTO CLINIC`, `3731-3739 N ASHLAND AVE 1ST` (LIC:2215290-20250416) | `Ashland Tire & Auto Clinic`, `3737 N Ashland Ave` | 1: lot range resolved to the published number; `1ST` dropped |
| 3 | `E & J FOREIGN CARS LTD`, `4241  -04245 N WESTERN AVE  1` | `E & J Foreign Cars`, `4245 N Western Ave` | 1: malformed range and extra spaces cleaned |
| 4 | `WM J CASSIDY TIRE & AUTO` at `824 W DIVERSEY PKWY` **and** `3235 N WESTERN AVE 1ST` (2 license rows) | One business, `Cassidy Tire & Service`, `3235 N Western Ave` | 1: branch merge. Western was selected because the store page (SRC04) is specific to it. |
| 5 | `Diagnostic Resting` (OBS028, typo on the E & J site) | Vehicle Diagnostics | 2: typo kept in the raw log, mapped by meaning |
| 6 | `Tires and Alignments` (OBS003, Ashland) | Two offerings: Tire Service + Wheel Alignment, both citing OBS003 | 2: compound phrase split |
| 7 | `Alignment Inspection` (OBS018, Cassidy) | *not mapped* | 2: an inspection is not an alignment service |

## Duplicate handling

* `BELMONT AUTO CLINIC, INC.` appears twice in the license file (ids
  `2621313-20241016` and `2621313-20261016`: same license number, two terms). It is
  one business listed twice, and it was excluded anyway (see below).
* Cassidy's two licensed branches were merged (example 4).
* When the same service appeared more than once on a page (e.g. "Brakes" in both
  the navigation and the body), only one offering was created. The composite PK
  `(business_id, service_id)` makes a second one impossible (test T3).

## Counts

| Stage | Count |
|---|---|
| License rows downloaded (4 community areas) | 74 |
| Rows out of theme (collision/body-only, car wash, Best Buy, Costco, scooter shop, tire-only dealers, etc.) or not checked | 53 |
| Candidate repair shops checked against web sources | 20 shops (21 license rows; Belmont listed twice) |
| Excluded after checking | 4 (listed below) |
| **Final businesses** | **16** |
| Raw service observations | 60 service rows in `manual_observations.csv` (plus 23 identity rows) |
| **Final distinct offerings** | **60** (60 service observations − 1 not mapped (OBS018) + 1 extra from splitting OBS003 = 60) |
| Services / categories | 7 / 2 |
| Sources / distinct publishers in `source` | 21 / 21 (17 cited by businesses or offerings; SRC18–SRC21 are corroboration-only) |

Exclusions:

1. **Belmont Auto Clinic.** BBB lists only the category "Auto Repairs" and there
   is no working website. A category alone is not evidence of a specific
   service. The license file also lists it twice.
2. **Hybrid Auto Repair.** The only mention of services is in customer reviews
   (Yahoo Local), with no provider-published list.
3. **Kraftsmen Auto.** Its website returned HTTP 522 on 2026-09-30, and the
   directory listings describe mainly collision/body work.
4. **Cassidy Tire, 824 W Diversey branch.** Merged into the Western Ave
   business; not a separate business.

Website decisions: `Autohaus.website` is NULL because the domain listed for it
(`autohauschicago.com`, per EuroRepairHQ) returns `301 → aliadwraps.com`, an
unrelated company (`raw/snapshots/autohauschicago_redirect_headers.txt`).
Midtown's own site was confirmed separately
(`raw/snapshots/website_check_midtownautorepair.html`), even though its offering
evidence comes from SimpleTire.

## Corroboration (fact checked against two independent publishers)

| Business | Fact checked | Publisher 1 | Publisher 2 (independent) | Result |
|---|---|---|---|---|
| Ashland Tire & Auto Clinic | Street address | City of Chicago license (SRC01): `3731-3739 N ASHLAND AVE 1ST` | Provider site (SRC02): `3737 N Ashland Ave`; Consumers' Checkbook (SRC18): `3737 N Ashland Ave` | **Minor disagreement.** The city records the whole lot range, while the shop and Checkbook give 3737, which is inside the range. We store 3737. |
| Fred's Wrigleyville Garage & Auto Repair | Address + website | License (SRC01): `3848 N CLARK ST 1ST` | Lakeview East Chamber (SRC19): `3848 N. Clark St.`, website `fredswrigleyvillegarage.com`; provider site (SRC07): `3848 N Clark St` | Agree |
| Rockwell Auto Clinic | Address incl. unit + website | License (SRC01): `4050 N ROCKWELL ST 1 UNIT C` | North Center Chamber (SRC20): `4050 N Rockwell St Unit C`, website `rockwellautoclinic.com`; provider site (SRC13): same | Agree (`Unit C` kept) |
| Mechanista | Address + website | License (SRC01): `4526 N RAVENSWOOD AVE` (legal name BLUE SKY INN NFP) | Ravenswood directory (SRC21): `4526 N Ravenswood Ave`, `mechanista.org`; provider site (SRC09) | Agree. The legal entity name differs from the trading name; we store the trading name. |

The city license file is a government registry, and the chamber and Checkbook
listings are member or consumer directories. None of them copies the shop's own
site, so each check uses separately published data.
