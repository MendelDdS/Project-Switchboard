import json
import os
import sys

HERE = os.path.dirname(__file__)
EXAMPLES = os.path.dirname(HERE)
sys.path.insert(0, EXAMPLES)

import playtesting as pt

FIX = os.path.join(EXAMPLES, "fixtures")


def load(name):
    with open(os.path.join(FIX, name), encoding="utf-8") as f:
        return json.load(f)


passed = 0
total = 0


def check(name, cond, detail=""):
    global passed, total
    total += 1
    if cond:
        passed += 1
        print(f"PASS {name}")
    else:
        print(f"FAIL {name}: {detail}")


# 1. Good plan passes all plan rules.
good = load("plan_good.json")
check("plan_good_valid", pt.plan_is_valid(good), pt.validate_plan(good))

# 2. Leading question rejected (non-leading Socratic rule).
bad_lead = load("plan_bad_leading.json")
errs = pt.validate_plan(bad_lead)
check("plan_rejects_leading_question",
      any("leading question" in e for e in errs), errs)

# 3. Missing cohort rejected (three distinct cohorts).
check("plan_rejects_missing_cohort",
      any("missing cohort Hardcore" in e for e in errs), errs)

# 4. Silent observer must be true.
bad_tel = load("plan_bad_telemetry.json")
errs2 = pt.validate_plan(bad_tel)
check("plan_rejects_silent_observer_false",
      any("silent_observer" in e for e in errs2), errs2)

# 5. Missing telemetry events rejected.
check("plan_rejects_missing_telemetry",
      any("missing telemetry event dwell" in e for e in errs2), errs2)

# 6. Level completion rate formula.
check("completion_rate_formula",
      abs(pt.level_completion_rate(36, 100) - 36.0) < 1e-9,
      pt.level_completion_rate(36, 100))

# 7. Drop-off > 30% is a lethal blocker.
check("dropoff_gt_30_lethal",
      pt.is_lethal_blocker(64, 100) is True, pt.drop_off(64, 100))

# 8. Drop-off exactly 30% is NOT lethal (strict >).
check("dropoff_eq_30_not_lethal",
      pt.is_lethal_blocker(70, 100) is False, pt.drop_off(70, 100))

# 9. Good matrix validates.
mg = load("matrix_good.json")
check("matrix_good_valid", pt.validate_matrix(mg) == [], pt.validate_matrix(mg))

# 10. Bad category rejected (must be one of tri-categories).
mb = load("matrix_bad_category.json")
merrs = pt.validate_matrix(mb)
check("matrix_rejects_bad_category",
      any("bad category" in e for e in merrs), merrs)

# 11. Bad player id rejected.
bad_row = dict(mg[0])
bad_row["Player ID"] = "P1"
check("matrix_rejects_bad_player_id",
      any("bad player id" in e for e in pt.validate_matrix_row(bad_row)),
      pt.validate_matrix_row(bad_row))

# 12. Missing column rejected.
missing = dict(mg[0])
del missing["Actionable Solution"]
check("matrix_rejects_missing_column",
      any("missing column Actionable Solution" in e
          for e in pt.validate_matrix_row(missing)),
      pt.validate_matrix_row(missing))

# 13. Aggregation groups by (category, symptom).
obs = load("observations.json")
findings = pt.aggregate_findings(obs)
check("aggregate_groups_count", len(findings) == 3, len(findings))

# 14. UX Friction with 2 occurrences -> critical, priority 1.
ux = [f for f in findings if f["category"] == "UX Friction"][0]
check("aggregate_ux_critical",
      ux["severity"] == "critical" and ux["priority"] == 1, ux)

# 15. Difficulty with 3 occurrences -> high.
diff = [f for f in findings if f["category"] == "Difficulty Tuning"][0]
check("aggregate_difficulty_high",
      diff["severity"] == "high" and diff["occurrences"] == 3, diff)

# 16. Feature Noise never critical (anti-pattern: don't implement directly).
check("aggregate_feature_noise_not_critical",
      pt.feature_noise_is_filtered(findings), findings)

# 17. Findings sorted by priority ascending.
prios = [f["priority"] for f in findings]
check("aggregate_sorted_by_priority", prios == sorted(prios), prios)

# 18. Routing fires on playtest prompt.
check("routing_fires_playtest",
      pt.should_fire("structure an external blind playtest protocol") is True)

# 19. Routing does not fire on regression tests.
check("routing_skips_regression",
      pt.should_fire("run automated regression tests on game engine code") is False)

# 20. Silent observer threshold constant is 5 minutes.
check("silent_observer_5min", pt.SILENT_OBSERVER_MINUTES == 5,
      pt.SILENT_OBSERVER_MINUTES)

print(f"RESULT {passed}/{total}")
if passed != total:
    sys.exit(1)
