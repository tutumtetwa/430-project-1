"""Run Q1-Q6 from sql/03_queries.sql plus an independent check for each,
and write outputs/query_outputs.md.

Usage (project root):  MYSQL="mysql -u root -p" python3 scripts/run_queries.py
"""
import os, re, shlex, subprocess, datetime

MYSQL = shlex.split(os.environ.get("MYSQL", "mysql -u root"))

def run(sql):
    r = subprocess.run(MYSQL + ["-t", "p1_car_repair"], input=sql, text=True,
                       capture_output=True)
    return (r.stdout + r.stderr).rstrip()

text = open("sql/03_queries.sql", encoding="utf-8").read()
blocks = re.split(r"\n(?=-- -{20,}\n-- Q\d)", text)[1:]
queries = {}
for b in blocks:
    qid = re.search(r"-- (Q\d)\.", b).group(1)
    queries[qid] = b.strip()

checks = {
 "Q1": ("Independent method (INSTR instead of LIKE) should give the same 5 businesses; "
        "by hand from data/clean/business.csv the names containing 'Auto Repair' are "
        "Eliot's, Fred's, Lincoln Park Auto Repair Service, Midtown, Reliable.",
        "SELECT COUNT(*) AS expected_rows FROM business WHERE INSTR(business_name, 'Auto Repair') > 0;"),
 "Q2": ("Row count must equal the number of DISTINCT providers (no duplicates), and "
        "a spot check traces Bucaro Brothers to raw row OBS011 'Transmission Services'.",
        "SELECT COUNT(*) AS offering_rows, COUNT(DISTINCT bs.business_id) AS distinct_providers\n"
        "FROM business_service bs JOIN service s ON s.service_id = bs.service_id\n"
        "JOIN business b ON b.business_id = bs.business_id\n"
        "WHERE s.service_name = 'Transmission Repair' AND b.city = 'Chicago';\n"
        "SELECT b.business_name, bs.raw_row_ref, bs.observed_wording FROM business_service bs\n"
        "JOIN business b ON b.business_id = bs.business_id WHERE bs.business_id = 3 AND bs.service_id = 6;"),
 "Q3": ("Manual count per service using plain COUNT(*) over the associative table "
        "(valid because the composite PK forbids duplicate pairs). Services with >= 7 must match Q3.",
        "SELECT service_id, COUNT(*) AS manual_count FROM business_service GROUP BY service_id ORDER BY manual_count DESC;"),
 "Q4": ("16 businesses minus the 5 with a recorded Wheel Alignment offering = 11 expected rows.",
        "SELECT (SELECT COUNT(*) FROM business) AS total_businesses,\n"
        "       (SELECT COUNT(*) FROM business_service WHERE service_id = 3) AS with_alignment,\n"
        "       (SELECT COUNT(*) FROM business) - (SELECT COUNT(*) FROM business_service WHERE service_id = 3) AS expected_rows;"),
 "Q5": ("Q5 must return one row per service (7). Mechanista has 4 recorded offerings, "
        "so 4 rows show 9 and 3 rows show NULL.",
        "SELECT (SELECT COUNT(*) FROM service) AS expected_rows,\n"
        "       (SELECT COUNT(*) FROM business_service WHERE business_id = 9) AS expected_non_null;"),
 "Q6": ("Base-table count of NULL websites must match the view. Autohaus is NULL because its listed "
        "domain autohauschicago.com 301-redirects to an unrelated company "
        "(data/raw/snapshots/autohauschicago_redirect_headers.txt).",
        "SELECT COUNT(*) AS null_websites_in_base_table FROM business WHERE website IS NULL;"),
}

meaning = {
 "Q1": "Businesses whose name contains the fragment 'Auto Repair'.",
 "Q2": "Chicago providers with a recorded Transmission Repair offering, each traced to its source URL and raw observation row. Evidence is for the selected location only; branch availability is unverified.",
 "Q3": "Services offered by at least 7 distinct businesses in the sample (threshold @min_providers = 7).",
 "Q4": "Businesses with no Wheel Alignment offering *recorded* in our sample. Absence means 'not recorded', not proof the shop lacks the service.",
 "Q5": "All 7 service types for Mechanista (business 9); NULL = no offering recorded for that service.",
 "Q6": "Businesses in the directory view with no working website recorded.",
}

server = run("SELECT VERSION() AS mysql_version;")
out = ["# Query outputs (Q1-Q6) with checks", "",
       f"Generated {datetime.datetime.now():%Y-%m-%d %H:%M} by `scripts/run_queries.py` against `p1_car_repair`.", "",
       "```text", server, "```", ""]
for qid in ["Q1", "Q2", "Q3", "Q4", "Q5", "Q6"]:
    sql = queries[qid]
    desc, chk = checks[qid]
    out += [f"## {qid}", "", f"**Meaning:** {meaning[qid]}", "", "```sql", sql, "```", "",
            "**Output**", "", "```text", run(sql), "```", "",
            f"**Check:** {desc}", "", "```text", run(chk), "```", ""]
open("outputs/query_outputs.md", "w", encoding="utf-8").write("\n".join(out))
print("wrote outputs/query_outputs.md")
