#!/usr/bin/env python3
"""Pawvest economy model (ROADMAP -> E0).

Reads every number that already exists in the game from the Luau configs in src/ReplicatedStorage (so the model
cannot drift silently), adds the planned content that is not in a config yet (PLANNED below, from the GDD / STAGES),
and reports the Coin economy.

  python tools/economy.py report   # baseline tables (faucets, sinks, obby hour, today's pen economy)
  python tools/economy.py check    # acceptance checks of E0 that can run so far; exit 1 on a failure
  python tools/economy.py drift    # only the drift check (configs vs tools/economy_pins.json and the formulas)
  python tools/economy.py pin      # accept the current config values as the reviewed state (rewrites the pins)

Drift workflow: when a price or rate changes in a config, `check` fails with the differing value. Re-run `report`, decide
whether the model still holds, then `pin`. New numbers for crops, fields and landmarks are not here yet (E0 continues).
All values are Coins before the pet multiplier unless a column says otherwise. Python 3.9+, standard library only.
"""
import argparse
import json
import math
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CFG = ROOT / "src" / "ReplicatedStorage"
PINS = Path(__file__).with_name("economy_pins.json")

# --------------------------------------------------------------------------------------------------------------------
# Planned content that no config holds yet (GDD §5-§6, STAGES §3). Provisional: every entry is a model assumption.
# --------------------------------------------------------------------------------------------------------------------
PLANNED = {
    "stage_count": 20,  # display numbers 1..20 plus the Tutorial = 21 stages (GDD §5)
    "t_base": {13: 120, 14: 135, 15: 145, 16: 120, 17: 110, 18: 135, 19: 150, 20: 180},  # midpoints of STAGES §3
    # extrapolated from the built prices (+500 every second stage); World 4 opener = StageConfig.Worlds[4].unlockPrice
    "unlock_price": {13: 5000, 14: 5000, 15: 5500, 16: 6000, 17: 6000, 18: 6500, 19: 6500, 20: 7000},
    "talents": {"WallJump": [10000], "Glide": [12000]},  # GDD §6 planned talents
    # first stage that needs a talent level (GDD §6 required-set table); checked against StageConfig `requires`
    "required_at": {("DoubleJump", 1): 6, ("DoubleJump", 2): 11, ("Dash", 1): 13, ("WallJump", 1): 16, ("Glide", 1): 17},
    "coins_per_planned_stage": 400,  # challenge coins, GDD §5 ("about 400 per stage")
    "required_share_max": 0.65,  # GDD §6
}

# --------------------------------------------------------------------------------------------------------------------
# Model assumptions (not game values): how a player spends time. Provisional until measured in M6.
# --------------------------------------------------------------------------------------------------------------------
MODEL = {
    "gold_run_factor": 0.85,  # a Gold run takes this share of T_base (Gold limit is 0.8 x T_base, plus a slow start)
    "run_overhead_s": 25.0,  # walking back to the gate, door, loading, between runs
    "offline_cap_h": 8.0,  # GardenConfig.OfflineCapSeconds, read below; kept in sync by the loader
}

# Archetypes (ROADMAP E0): sessions = (start hour of day, hours online) inside a period of `period_days` days;
# `obby_min` = minutes of obby per period; online time pays pen production too.
ARCHETYPES = [
    {"name": "Obby main", "sessions": [(7.0, 0.5), (12.5, 0.5), (18.0, 2.5)], "period_days": 1, "obby_min": 120},
    {"name": "Casual", "sessions": [(8.0, 0.25), (19.0, 0.75)], "period_days": 1, "obby_min": 45},
    {"name": "Garden main", "sessions": [(7.0, 0.5), (12.0, 0.5), (17.0, 0.5), (21.0, 0.5)], "period_days": 1, "obby_min": 15},
    {"name": "Binge", "sessions": [(10.0, 6.0)], "period_days": 7, "obby_min": 300},
]

# Reference pen sets (kind rarity -> count at a level), GDD §7.6 examples.
PEN_SETS = [
    ("1 Common Lv1", [("Common", 1, 1)]),
    ("3 starter Lv1", [("Common", 1, 2), ("Uncommon", 1, 1)]),
    ("6 mixed Lv5 (GDD)", [("Common", 5, 2), ("Uncommon", 5, 2), ("Rare", 5, 1), ("Epic", 5, 1)]),
    ("strong Lv10 (GDD)", [("Legendary", 10, 2), ("Epic", 10, 2), ("Rare", 10, 2)]),
    ("6 Legendary Lv20", [("Legendary", 20, 6)]),
]

# Formulas of the Luau code that the model re-implements: the snippet must still be in the file (whitespace-insensitive).
FORMULAS = [
    ("StageConfig.luau", "math.floor(StageConfig.FinishPayoutBase * stage.rewardFactor + 0.5)"),
    ("StageConfig.luau", "StageConfig.RunRewardBase * stage.rewardFactor * StageConfig.Medals[medal].runMultiplier"),
    ("StageConfig.luau", "* StageConfig.RunRewardDecay ^ finishesToday"),
    ("StageConfig.luau", "math.max(StageConfig.RunRewardFloor, math.floor(raw + 0.5 + 1e-9))"),
    ("StageConfig.luau", "coins += StageConfig.Medals[medal].basePayout * stage.rewardFactor"),
    ("PetConfig.luau", "math.floor(10 * level ^ 1.5 + 0.5)"),
    ("GardenConfig.luau", "rate * (1000 + GardenConfig.LevelRate * (PetConfig.ClampLevel(pet.Level) - 1))"),
]


# --------------------------------------------------------------------------------------------------------------------
# A small Luau table reader: enough of the language for the config files (tables, numbers, strings, + - * / ^).
# --------------------------------------------------------------------------------------------------------------------
class Raw(str):
    """A Luau value the reader does not evaluate (calls, enums, references)."""


_TOKEN = re.compile(
    r"""\s+|--\[\[.*?\]\]|--[^\n]*|(?P<str>"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*')|(?P<num>\d+\.?\d*(?:[eE][+-]?\d+)?)"""
    r"""|(?P<id>[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)|(?P<sym>::|\.\.|.)""",
    re.S,
)


def tokenize(text):
    tokens, pos = [], 0
    while pos < len(text):
        m = _TOKEN.match(text, pos)
        if not m:
            raise ValueError("cannot tokenize near: " + text[pos:pos + 30])
        pos = m.end()
        if m.lastgroup == "str":
            tokens.append(("str", bytes(m.group()[1:-1], "utf-8").decode("unicode_escape", "ignore") if "\\" in m.group() else m.group()[1:-1]))
        elif m.lastgroup == "num":
            tokens.append(("num", float(m.group()) if "." in m.group() or "e" in m.group().lower() else int(m.group())))
        elif m.lastgroup in ("id", "sym"):
            tokens.append((m.lastgroup, m.group()))
    return tokens


class Reader:
    def __init__(self, text):
        self.t = tokenize(text)
        self.i = 0

    def peek(self, k=0):
        return self.t[self.i + k] if self.i + k < len(self.t) else ("eof", None)

    def eat(self, value=None):
        tok = self.t[self.i]
        if value is not None and tok[1] != value:
            raise ValueError(f"expected {value!r}, got {tok!r}")
        self.i += 1
        return tok

    def find(self, name):
        for k in range(len(self.t) - 1):
            if self.t[k] == ("id", name) and self.t[k + 1] == ("sym", "="):
                self.i = k + 2
                return self.expr()
        raise KeyError(name)

    def expr(self):
        left = self.term()
        while self.peek()[0] == "sym" and self.peek()[1] in "+-" and self.peek()[1] != "":
            op = self.eat()[1]
            right = self.term()
            left = self._arith(left, op, right)
        return left

    def term(self):
        left = self.unary()
        while self.peek() in (("sym", "*"), ("sym", "/")):
            op = self.eat()[1]
            right = self.unary()
            left = self._arith(left, op, right)
        return left

    def unary(self):
        if self.peek() == ("sym", "-"):
            self.eat()
            v = self.unary()
            return -v if isinstance(v, (int, float)) else Raw("-" + str(v))
        base = self.primary()
        if self.peek() == ("sym", "^"):
            self.eat()
            return self._arith(base, "^", self.unary())
        return base

    @staticmethod
    def _arith(a, op, b):
        if not (isinstance(a, (int, float)) and isinstance(b, (int, float))) or isinstance(a, bool) or isinstance(b, bool):
            return Raw(f"{a}{op}{b}")
        r = {"+": a + b, "-": a - b, "*": a * b, "/": a / b if b else math.inf, "^": a ** b}[op]
        return int(r) if isinstance(r, float) and r.is_integer() and op != "/" else r

    def primary(self):
        kind, val = self.peek()
        if kind == "num" or kind == "str":
            self.eat()
            return val
        if (kind, val) == ("sym", "{"):
            return self.table()
        if (kind, val) == ("sym", "("):
            self.eat()
            v = self.expr()
            self.eat(")")
            return v
        if kind == "id":
            self.eat()
            if val == "nil":
                return None
            if val in ("true", "false"):
                return val == "true"
            if self.peek() == ("sym", "("):  # a call: skip its arguments
                depth = 0
                while True:
                    tok = self.eat()
                    depth += (tok == ("sym", "(")) - (tok == ("sym", ")"))
                    if depth == 0:
                        break
            return Raw(val)
        raise ValueError(f"unexpected token {self.peek()!r}")

    def table(self):
        self.eat("{")
        named, listed = {}, []
        while self.peek() != ("sym", "}"):
            if self.peek() in (("sym", ","), ("sym", ";")):
                self.eat()
                continue
            if self.peek() == ("sym", "["):
                self.eat()
                key = self.expr()
                self.eat("]")
                self.eat("=")
                named[key] = self.expr()
            elif self.peek()[0] == "id" and self.peek(1) == ("sym", "="):
                key = self.eat()[1]
                self.eat("=")
                named[key] = self.expr()
            else:
                listed.append(self.expr())
        self.eat("}")
        if named and listed:
            named.update({i + 1: v for i, v in enumerate(listed)})
        return named if named else listed


def luau(file, name):
    return Reader((CFG / file).read_text(encoding="utf-8")).find(name)


# --------------------------------------------------------------------------------------------------------------------
# Loading: configs + planned content -> one parameter dict.
# --------------------------------------------------------------------------------------------------------------------
def lua_round(x):
    return math.floor(x + 0.5)


def load():
    P = {}
    medals = luau("StageConfig.luau", "StageConfig.Medals")
    P["medals"] = [{"name": m["name"], "base": m["basePayout"], "mult": m["runMultiplier"]} for m in medals]
    P["rr_base"] = luau("StageConfig.luau", "StageConfig.RunRewardBase")
    P["rr_decay"] = luau("StageConfig.luau", "StageConfig.RunRewardDecay")
    P["rr_floor"] = luau("StageConfig.luau", "StageConfig.RunRewardFloor")
    P["finish_base"] = luau("StageConfig.luau", "StageConfig.FinishPayoutBase")
    P["world4_unlock_price"] = luau("StageConfig.luau", "StageConfig.Worlds")[4]["unlockPrice"]

    stages = []
    for s in luau("StageConfig.luau", "StageConfig.Stages"):
        stages.append({
            "key": s["key"], "order": s["order"], "world": s["world"], "factor": s["rewardFactor"], "t_base": s["tBase"],
            "unlock_price": s.get("unlockPrice"), "built": True,
            "requires": [(r["id"], r["level"]) for r in s.get("requires", [])],
        })
    for n in range(len(stages), PLANNED["stage_count"] + 1):
        stages.append({
            "key": f"Stage{n}", "order": n, "world": (n - 1) // 5 + 1, "factor": 0.5 + 0.25 * n, "t_base": PLANNED["t_base"][n],
            "unlock_price": PLANNED["unlock_price"][n], "built": False, "requires": [],
        })
    P["stages"] = stages

    talents = {t["id"]: {"costs": t["costs"], "built": True} for t in luau("TalentConfig.luau", "TalentConfig.List")}
    for tid, costs in PLANNED["talents"].items():
        talents[tid] = {"costs": costs, "built": False}
    P["talents"] = talents

    P["rarities"] = {r["id"]: {"order": r["order"], "bonus": r["bonus"], "sell": r["sellValue"]}
                     for r in luau("PetConfig.luau", "PetConfig.Rarities")}
    P["eggs"] = {k: {"price": e["price"], "hatch_s": e["hatchSeconds"], "weights": e["weights"]}
                 for k, e in luau("PetConfig.luau", "PetConfig.Eggs").items()}
    P["slot_prices"] = luau("PetConfig.luau", "PetConfig.SlotPrices")
    P["max_level"] = luau("PetConfig.luau", "PetConfig.MaxLevel")
    P["level_bonus"] = luau("PetConfig.luau", "PetConfig.LevelBonus")
    P["max_bonus"] = luau("PetConfig.luau", "PetConfig.MaxBonus")

    P["pen_prices"] = luau("GardenConfig.luau", "GardenConfig.PenPrices")
    P["pen_rates"] = luau("GardenConfig.luau", "GardenConfig.BaseRates")
    P["pen_level_rate"] = luau("GardenConfig.luau", "GardenConfig.LevelRate")
    P["offline_cap_h"] = luau("GardenConfig.luau", "GardenConfig.OfflineCapSeconds") / 3600
    P["incubator_prices"] = luau("GardenConfig.luau", "GardenConfig.IncubatorPrices")
    P["foods"] = [{"id": f["id"], "price": f["price"], "xp": f["xp"]} for f in luau("GardenConfig.luau", "GardenConfig.Foods")]

    tiers = luau("ChallengeCoinConfig.luau", "ChallengeCoinConfig.Tiers")
    coins = {}
    for c in luau("ChallengeCoinConfig.luau", "ChallengeCoinConfig.Coins"):
        coins.setdefault(c["stage"], []).append(tiers[c["tier"]])
    P["coin_tiers"] = tiers
    P["coins_by_stage"] = coins
    return P


def pin_values(P):
    """The existing config values the model depends on, flattened (what `pin` stores and `drift` compares)."""
    v = {
        "medals": [[m["base"], m["mult"]] for m in P["medals"]],
        "run_reward": [P["rr_base"], P["rr_decay"], P["rr_floor"]],
        "finish_base": P["finish_base"],
        "world4_unlock_price": P["world4_unlock_price"],
        "talent_costs": {k: t["costs"] for k, t in P["talents"].items() if t["built"]},
        "rarities": {k: [r["bonus"], r["sell"]] for k, r in P["rarities"].items()},
        "eggs": {k: [e["price"], e["hatch_s"], e["weights"]] for k, e in P["eggs"].items()},
        "slot_prices": P["slot_prices"],
        "pet_levels": [P["max_level"], P["level_bonus"], P["max_bonus"]],
        "pen_prices": P["pen_prices"],
        "pen_rates": P["pen_rates"],
        "pen_level_rate": P["pen_level_rate"],
        "offline_cap_h": P["offline_cap_h"],
        "incubator_prices": P["incubator_prices"],
        "foods": [[f["id"], f["price"], f["xp"]] for f in P["foods"]],
        "coin_tiers": P["coin_tiers"],
        "coin_counts": {k: len(c) for k, c in sorted(P["coins_by_stage"].items())},
    }
    for s in P["stages"]:
        if s["built"]:
            v[f"stage:{s['key']}"] = [s["order"], s["world"], s["factor"], s["t_base"], s["unlock_price"], s["requires"]]
    return json.loads(json.dumps(v))  # normalise tuples to lists


def drift(P):
    """List of differences between the configs and the reviewed pins, plus formulas that changed."""
    problems = []
    if not PINS.exists():
        return ["no tools/economy_pins.json: run `python tools/economy.py pin` after reviewing the report"]
    pinned, now = json.loads(PINS.read_text(encoding="utf-8")), pin_values(P)
    for key in sorted(set(pinned) | set(now)):
        if pinned.get(key) != now.get(key):
            problems.append(f"{key}: pinned {json.dumps(pinned.get(key))} -> config {json.dumps(now.get(key))}")
    for file, snippet in FORMULAS:
        text = re.sub(r"\s+", " ", (CFG / file).read_text(encoding="utf-8"))
        if re.sub(r"\s+", " ", snippet) not in text:
            problems.append(f"formula changed in {file}: {snippet!r} is gone; update the model's copy of it")
    return problems


# --------------------------------------------------------------------------------------------------------------------
# The model.
# --------------------------------------------------------------------------------------------------------------------
def stage_medal_total(P, s):
    return lua_round(sum(m["base"] * s["factor"] for m in P["medals"]))


def first_finish(P, s):
    return lua_round(P["finish_base"] * s["factor"])


def run_reward(P, s, medal, n):
    """StageConfig.RunReward: medal is 1..3 (0 = none); n = earlier medal finishes of the stage today."""
    if medal <= 0:
        return 0
    raw = P["rr_base"] * s["factor"] * P["medals"][medal - 1]["mult"] * P["rr_decay"] ** n
    return max(P["rr_floor"], math.floor(raw + 0.5 + 1e-9))


def coins_of(P, s):
    if s["built"]:
        return sum(P["coins_by_stage"].get(s["key"], []))
    return PLANNED["coins_per_planned_stage"]


def talent_total(P, tid, upto=None):
    costs = P["talents"][tid]["costs"]
    return sum(costs[: upto or len(costs)])


def obby_sim(P, stages, minutes):
    """Greedy Gold-run farming on a fresh day: always run the stage with the best reward per second.
    Returns (coins, runs, coins after each full hour)."""
    n = {s["key"]: 0 for s in stages}
    t, coins, runs, hourly, next_hour = 0.0, 0, 0, [], 3600.0
    limit = minutes * 60.0
    while True:
        best = max(stages, key=lambda s: run_reward(P, s, 3, n[s["key"]]) / (s["t_base"] * MODEL["gold_run_factor"] + MODEL["run_overhead_s"]))
        dt = best["t_base"] * MODEL["gold_run_factor"] + MODEL["run_overhead_s"]
        if t + dt > limit:
            break
        t += dt
        coins += run_reward(P, best, 3, n[best["key"]])
        n[best["key"]] += 1
        runs += 1
        while t >= next_hour:
            hourly.append(coins)
            next_hour += 3600.0
    return coins, runs, hourly


def pen_rate(P, rarity, level):
    return P["pen_rates"][rarity] * (1000 + P["pen_level_rate"] * (level - 1)) / 1000


def pen_set_rate(P, entries):
    return sum(pen_rate(P, rarity, level) * count for rarity, level, count in entries)


def covered_hours_per_day(P, arch):
    """Hours per day for which pens produce: online time plus the offline gap after each session, capped (GardenConfig)."""
    period_h = arch["period_days"] * 24.0
    sess = sorted(arch["sessions"])
    total = 0.0
    for i, (start, length) in enumerate(sess):
        nxt = sess[i + 1][0] if i + 1 < len(sess) else sess[0][0] + period_h
        total += length + min(max(nxt - (start + length), 0.0), P["offline_cap_h"])
    return total / arch["period_days"]


def pet_bonus(P, kind_rarity, level):
    return P["rarities"][kind_rarity]["bonus"] + P["level_bonus"] * (level - 1)


# --------------------------------------------------------------------------------------------------------------------
# Output helpers.
# --------------------------------------------------------------------------------------------------------------------
def n(x):
    if isinstance(x, float) and abs(x) < 100 and not x.is_integer():
        return f"{x:,.1f}".replace(",", " ")
    return f"{round(x):,}".replace(",", " ")


def table(header, rows, right_from=1):
    cells = [header] + [[str(c) for c in r] for r in rows]
    widths = [max(len(r[i]) for r in cells) for i in range(len(header))]
    out = []
    for k, r in enumerate(cells):
        out.append("  ".join(c.ljust(widths[i]) if i < right_from else c.rjust(widths[i]) for i, c in enumerate(r)))
        if k == 0:
            out.append("  ".join("-" * w for w in widths))
    return "\n".join(out)


def tick(ok):
    return "ok" if ok else "FAIL"


# --------------------------------------------------------------------------------------------------------------------
# Checks (acceptance checks of E0 that exist so far).
# --------------------------------------------------------------------------------------------------------------------
def reproduction(P):
    """GDD figures the model must return (acceptance check 2)."""
    S = P["stages"]
    by_factor = {s["factor"]: s for s in S}
    built = [s for s in S if s["built"]]
    six = [s for s in S if s["order"] <= 5]
    gold_day = lambda s: sum(run_reward(P, s, 3, k) for k in range(10))
    mixed = [e for name, e in PEN_SETS if name.startswith("6 mixed")][0]
    full_tree = sum(talent_total(P, t) for t in P["talents"])
    rows = [
        ("Medals, Tutorial + stages 1-5 (GDD §5)", 9450, sum(stage_medal_total(P, s) for s in six)),
        ("Medals, all 21 stages", 88200, sum(stage_medal_total(P, s) for s in S)),
        ("First-finish payouts, all 21 stages", 6300, sum(first_finish(P, s) for s in S)),
        ("Planned talent tree", 47300, full_tree),
        ("Gold runs, first 10 of a day, factor 1.5", 668, gold_day(by_factor[1.5])),
        ("Gold runs, first 10 of a day, factor 1.0", 446, gold_day(by_factor[1.0])),
        ("Gold runs, first 10 of a day, factor 0.5 (Tutorial)", 227, gold_day(by_factor[0.5])),
        ("Pen income, 6 mixed Lv5 pens, Coins/h", 197, round(pen_set_rate(P, mixed))),
        ("Pen income, strong set Lv10, Coins/h", 626, round(pen_set_rate(P, [e for nme, e in PEN_SETS if nme.startswith("strong")][0]))),
        ("Pen income, 6 Legendary Lv20, Coins/h", 1267, round(pen_set_rate(P, [("Legendary", 20, 6)]))),
        ("Stage unlocks of stages 1-5 (GDD §6 'today')", 6700, sum(s["unlock_price"] for s in S if 1 <= s["order"] <= 5)),
        ("Pens (all 6)", 32500, sum(P["pen_prices"])),
        ("Incubators (all 3)", 17000, sum(P["incubator_prices"])),
        ("Pet slots", 7000, sum(P["slot_prices"])),
    ]
    return [(label, gdd, model, abs(gdd - model) <= 1) for label, gdd, model in rows]


def required_sets(P):
    """GDD §6 required-set table: cost of every talent level a stage needs vs the medals earned before that stage."""
    S = P["stages"]
    owned, out = [], []
    for stage in sorted(set(PLANNED["required_at"].values())):
        owned = [(t, l) for (t, l), at in PLANNED["required_at"].items() if at <= stage]
        cost = sum(sum(P["talents"][t]["costs"][:l]) for t, l in {(t, max(l2 for t2, l2 in owned if t2 == t)) for t, _ in owned})
        medals = sum(stage_medal_total(P, s) for s in S if s["order"] < stage)
        out.append((stage, cost, medals, cost / medals))
    return out


def run_checks(P):
    results = []
    d = drift(P)
    results.append(("1 Drift: configs equal the reviewed pins, formulas unchanged", not d, "; ".join(d[:3]) + (" ..." if len(d) > 3 else "")))
    for label, gdd, model, ok in reproduction(P):
        results.append((f"2 Reproduction: {label}", ok, f"GDD {n(gdd)} / model {n(model)}"))
    for stage, cost, medals, share in required_sets(P):
        results.append((f"3 Required set before stage {stage} (garden off)", share <= PLANNED["required_share_max"],
                        f"{n(cost)} of {n(medals)} = {share:.0%}"))
    cfg_first = {}
    for s in P["stages"]:
        for tid, lv in s["requires"]:
            cfg_first[(tid, lv)] = min(cfg_first.get((tid, lv), 99), s["order"])
    mismatched = [f"{k} config {cfg_first[k]} vs plan {v}" for k, v in PLANNED["required_at"].items() if k in cfg_first and cfg_first[k] != v]
    results.append(("3 Required talents of built stages match the planned table", not mismatched, "; ".join(mismatched)))
    return results


# --------------------------------------------------------------------------------------------------------------------
# Commands.
# --------------------------------------------------------------------------------------------------------------------
def cmd_report(P):
    S = P["stages"]
    built = [s for s in S if s["built"]]
    print("PAWVEST ECONOMY BASELINE (E0, today's configs + planned content; Coins before the pet multiplier)\n")

    print("1. One-time faucets by world (medals, first finish, challenge coins); (p) = planned, not built")
    rows = []
    for w in range(0, 5):
        ws = [s for s in S if s["world"] == w]
        if not ws:
            continue
        flag = "" if all(s["built"] for s in ws) else (" (p)" if not any(s["built"] for s in ws) else " (part p)")
        rows.append((("Tutorial" if w == 0 else f"World {w}") + flag, len(ws), sum(stage_medal_total(P, s) for s in ws),
                     sum(first_finish(P, s) for s in ws), sum(coins_of(P, s) for s in ws),
                     sum(stage_medal_total(P, s) + first_finish(P, s) + coins_of(P, s) for s in ws)))
    tot = [sum(r[i] for r in rows) for i in range(1, 6)]
    rows = [(r[0], r[1], n(r[2]), n(r[3]), n(r[4]), n(r[5])) for r in rows] + [("All", tot[0], n(tot[1]), n(tot[2]), n(tot[3]), n(tot[4]))]
    print(table(["World", "Stages", "Medals", "First finish", "Coins", "Total"], rows))
    one_time = tot[4]

    print("\n2. Sinks (prices from the configs; planned items marked)")
    sink_rows, sink_total = [], 0
    def add(group, what, price, planned=False, one_time_sink=True):
        nonlocal sink_total
        sink_rows.append((group, what + (" (p)" if planned else ""), n(price)))
        if one_time_sink:
            sink_total += price
    for tid, t in P["talents"].items():
        add("Talent", f"{tid} " + "/".join(n(c) for c in t["costs"]), sum(t["costs"]), not t["built"])
    for s in S:
        if s["unlock_price"]:
            add("Stage unlock", f"{s['key']}", s["unlock_price"], not s["built"])
    add("Pet slots", "/".join(n(c) for c in P["slot_prices"]), sum(P["slot_prices"]))
    add("Pens", "/".join(n(c) for c in P["pen_prices"]), sum(P["pen_prices"]))
    add("Incubators", "/".join(n(c) for c in P["incubator_prices"]), sum(P["incubator_prices"]))
    print(table(["Group", "Item", "Total"], sink_rows, right_from=2))
    xp = sum(round(10 * lv ** 1.5) for lv in range(1, P["max_level"]))
    feast = max(P["foods"], key=lambda f: f["xp"])
    print(f"\n  One-time sinks total {n(sink_total)} vs one-time faucet {n(one_time)}: {sink_total / one_time:.2f}x. "
          f"Open-ended sinks: eggs, food (Lv1 -> {P['max_level']} = {n(xp)} XP = {n(math.ceil(xp / feast['xp']) * feast['price'])} Coins in {feast['id']}s per pet).")
    for k, e in P["eggs"].items():
        w = e["weights"]
        tw = sum(w.values())
        resale = sum(w[r] / tw * P["rarities"][r]["sell"] for r in w)
        bonus = sum(w[r] / tw * P["rarities"][r]["bonus"] for r in w) / 10
        print(f"  {k} egg {n(e['price'])}: expected resale {n(resale)} ({resale / e['price']:.0%} of the price), expected base bonus +{bonus:.1f} %")

    print("\n3. Required talent sets vs medals earned before (GDD §6, garden income off; share must be <= 65 %)")
    rows = [(f"stage {st}", n(c), n(m), f"{sh:.0%}", tick(sh <= PLANNED["required_share_max"])) for st, c, m, sh in required_sets(P)]
    print(table(["First required at", "Set cost", "Medals before", "Share", ""], rows))

    print("\n4. Obby farming on a fresh day (Gold runs, greedy best Coins/s; model: Gold run = "
          f"{MODEL['gold_run_factor']:.0%} of T_base + {MODEL['run_overhead_s']:.0f} s overhead)")
    prog = [("Tutorial + World 1", [s for s in built if s["order"] <= 5]), ("+ World 2", [s for s in built if s["order"] <= 10]),
            ("+ World 3 (built)", built)]
    rows, first_hour = [], {}
    for name, ss in prog:
        coins, runs, hourly = obby_sim(P, ss, 200)  # a little over 3 h so every hour is complete
        hs = [hourly[0], hourly[1] - hourly[0], hourly[2] - hourly[1]]
        first_hour[name] = hs[0]
        rows.append((name, len(ss), n(hs[0]), n(hs[1]), n(hs[2])))
    print(table(["Progress", "Stages", "Hour 1", "Hour 2", "Hour 3"], rows))
    print("  GDD §6 estimates ~2 230 for the first hour and ~500 later; the model is not tuned to them (run times are assumptions).")

    print("\n5. Today's pen economy per day (Coins/day before the pet multiplier; pens pay online + up to "
          f"{P['offline_cap_h']:.0f} h offline per session)")
    print("   a) archetypes: covered hours per day and obby Coins per day (World 1 / World 3 progress)")
    rows = []
    for a in ARCHETYPES:
        ch = covered_hours_per_day(P, a)
        o1 = obby_sim(P, prog[0][1], a["obby_min"])[0] / a["period_days"]
        o3 = obby_sim(P, prog[2][1], a["obby_min"])[0] / a["period_days"]
        rows.append((a["name"], f"{a['obby_min']} min/" + (f"{a['period_days']} d" if a["period_days"] > 1 else "d"),
                     f"{ch:.1f} h", n(o1), n(o3)))
    print(table(["Archetype", "Obby", "Pens pay", "Obby W1", "Obby W3"], rows))
    print("   b) pen income per day by pet set")
    rows = []
    for setname, entries in PEN_SETS:
        rate = pen_set_rate(P, entries)
        rows.append([setname, n(rate)] + [n(rate * covered_hours_per_day(P, a)) for a in ARCHETYPES] + [n(rate * 24)])
    print(table(["Pet set", "Coins/h"] + [a["name"] for a in ARCHETYPES] + ["24 h"], rows))

    print("\n6. The 24-hour rule applied to today's pens (decided 2026-10-24: a fully automated field over 24 h <= the first obby hour)")
    rows = []
    for setname, entries in PEN_SETS:
        rate = pen_set_rate(P, entries) * 24
        rows.append([setname, n(rate)] + [f"{rate / first_hour[name]:.1f}x" for name, _ in prog])
    print(table(["Pet set, 24 h uncapped", "Coins"] + [f"vs hour 1 ({name})" for name, _ in prog], rows))
    print("  Today only the 8 h offline cap keeps the pens near the rule; the crop field has no such cap, so its ceiling must come from\n"
          "  square count, seed cost and seed stock (E0 question 3).")


def cmd_check(P):
    results = run_checks(P)
    for name, ok, detail in results:
        print(f"[{tick(ok):4}] {name}" + (f"  ({detail})" if detail else ""))
    failed = [r for r in results if not r[1]]
    print(f"\n{len(results) - len(failed)} / {len(results)} checks pass" + ("" if not failed else f", {len(failed)} FAIL"))
    print("Not implemented yet (E0 continues): guardrails A-C, dead end, rare crops, repricing, sensitivity (checks 4-11).")
    return 1 if failed else 0


def main():
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass
    ap = argparse.ArgumentParser(description="Pawvest economy model (ROADMAP E0)")
    ap.add_argument("command", choices=["report", "check", "drift", "pin"])
    args = ap.parse_args()
    P = load()
    if args.command == "report":
        cmd_report(P)
        return 0
    if args.command == "check":
        return cmd_check(P)
    if args.command == "drift":
        d = drift(P)
        print("\n".join(d) if d else "no drift")
        return 1 if d else 0
    PINS.write_text(json.dumps(pin_values(P), indent=1, sort_keys=True, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"pinned {len(pin_values(P))} values to {PINS.name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
