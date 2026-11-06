"""Deterministic rules for the 'playtesting' skill (Lantern Moth example).

Only the skill's *checkable* rules are encoded here. Content judgement that a
real agent would make (e.g. "is this root cause really UX friction?") is
supplied by the fixtures as explicit tags/fields, never inferred from prose.
"""

from __future__ import annotations

# --- Constants taken verbatim from the skill -------------------------------

COHORTS = ("FTUE", "Core", "Hardcore")

# Tri-Category Framework (Step 2). "Feature Noise" is the checklist wording.
CATEGORIES = ("UX Friction", "Difficulty Tuning", "Feature Noise")

# Deliverable matrix columns, in order.
MATRIX_COLUMNS = (
    "Player ID",
    "Cohort",
    "Encounter / Level",
    "Observed Behavior (Action)",
    "Stated Reason (Words)",
    "Root Cause Category",
    "Actionable Solution",
)

# Funnel drop-off threshold: > 30% at a stage is a lethal design blocker.
DROP_OFF_LIMIT = 30.0

# Silent Observer: a player lost for 5 minutes must NOT be helped.
SILENT_OBSERVER_MINUTES = 5

# Required telemetry events (Step 3.1).
TELEMETRY_EVENTS = ("death", "dwell", "resource_bank", "quit")

# Severity -> priority mapping used by the aggregation.
SEVERITY_PRIORITY = {"critical": 1, "high": 2, "medium": 3, "low": 4}


# --- Plan validation -------------------------------------------------------

def validate_plan(plan: dict) -> list[str]:
    """Return a list of rule violations for a playtest plan (empty = valid)."""
    errors: list[str] = []

    # Cohort segmentation: every cohort must be represented.
    cohorts = plan.get("cohorts", [])
    for c in COHORTS:
        if c not in cohorts:
            errors.append(f"missing cohort {c}")
    for c in cohorts:
        if c not in COHORTS:
            errors.append(f"unknown cohort {c}")

    # Silent Observer protocol must be declared.
    if plan.get("silent_observer") is not True:
        errors.append("silent_observer must be true")

    # Telemetry must log all four critical events.
    events = plan.get("telemetry_events", [])
    for e in TELEMETRY_EVENTS:
        if e not in events:
            errors.append(f"missing telemetry event {e}")

    # Debrief questions must be open-ended and non-leading.
    questions = plan.get("debrief_questions", [])
    if not questions:
        errors.append("no debrief questions")
    for q in questions:
        if q.get("leading") is not False:
            errors.append(f"leading question: {q.get('text', '?')}")
        if q.get("open_ended") is not True:
            errors.append(f"closed question: {q.get('text', '?')}")

    return errors


def plan_is_valid(plan: dict) -> bool:
    return not validate_plan(plan)


# --- Funnel / drop-off -----------------------------------------------------

def level_completion_rate(completed: int, entered: int) -> float:
    """Level Completion Rate = Completed N / Entered N * 100."""
    if entered <= 0:
        raise ValueError("entered must be > 0")
    return completed / entered * 100.0


def drop_off(completed: int, entered: int) -> float:
    return 100.0 - level_completion_rate(completed, entered)


def is_lethal_blocker(completed: int, entered: int) -> bool:
    """Drop-off > 30% at a stage indicates a lethal design blocker."""
    return drop_off(completed, entered) > DROP_OFF_LIMIT


# --- Observation matrix validation ----------------------------------------

def validate_matrix_row(row: dict) -> list[str]:
    """Validate one observation-matrix row against the deliverable format."""
    errors: list[str] = []
    for col in MATRIX_COLUMNS:
        if col not in row or row[col] in (None, ""):
            errors.append(f"missing column {col}")

    pid = row.get("Player ID", "")
    if pid and not (pid.startswith("#P") and pid[2:].isdigit()):
        errors.append(f"bad player id {pid}")

    cohort = row.get("Cohort")
    if cohort and cohort not in COHORTS:
        errors.append(f"bad cohort {cohort}")

    # Root Cause Category must start with one of the tri-category labels.
    cat = row.get("Root Cause Category", "")
    if cat and not any(cat.startswith(c) for c in CATEGORIES):
        errors.append(f"bad category {cat}")

    return errors


def validate_matrix(rows: list[dict]) -> list[str]:
    errors: list[str] = []
    if not rows:
        errors.append("empty matrix")
    for i, row in enumerate(rows):
        for e in validate_matrix_row(row):
            errors.append(f"row {i}: {e}")
    return errors


# --- Aggregation: tagged observations -> prioritized findings -------------

def _severity_for(category: str, occurrences: int) -> str:
    """Severity from category + how many players hit it.

    UX Friction is 'must fix immediately' -> at least high.
    Difficulty Tuning scales with occurrence count.
    Feature Noise is filtered, never critical.
    """
    if category == "UX Friction":
        return "critical" if occurrences >= 2 else "high"
    if category == "Difficulty Tuning":
        if occurrences >= 3:
            return "high"
        if occurrences >= 2:
            return "medium"
        return "low"
    return "low"  # Feature Noise


def aggregate_findings(observations: list[dict]) -> list[dict]:
    """Group tagged observations into prioritized findings.

    Each observation carries explicit tags (a real agent would assign these):
      category: one of CATEGORIES
      symptom:  short key describing the underlying symptom
      solution: proposed actionable solution
    """
    groups: dict[tuple[str, str], list[dict]] = {}
    for obs in observations:
        cat = obs["category"]
        if cat not in CATEGORIES:
            raise ValueError(f"bad category {cat}")
        key = (cat, obs["symptom"])
        groups.setdefault(key, []).append(obs)

    findings: list[dict] = []
    for (cat, symptom), obs_list in groups.items():
        n = len(obs_list)
        severity = _severity_for(cat, n)
        findings.append({
            "category": cat,
            "symptom": symptom,
            "occurrences": n,
            "severity": severity,
            "priority": SEVERITY_PRIORITY[severity],
            "solution": obs_list[0]["solution"],
            "players": [o["player"] for o in obs_list],
        })

    # Sort by priority, then by occurrence count (desc), then symptom.
    findings.sort(key=lambda f: (f["priority"], -f["occurrences"], f["symptom"]))
    return findings


def feature_noise_is_filtered(findings: list[dict]) -> bool:
    """Feature Noise must never be implemented directly (anti-pattern)."""
    return all(f["severity"] != "critical" for f in findings
               if f["category"] == "Feature Noise")


# --- Routing (from evals/routing.yaml) ------------------------------------

_ROUTE_KEYWORDS = ("playtest", "telemetry", "drop-off", "dropoff",
                   "player feedback", "completion rate", "difficulty spike")


def should_fire(prompt: str) -> bool:
    p = prompt.lower()
    return any(k in p for k in _ROUTE_KEYWORDS)
