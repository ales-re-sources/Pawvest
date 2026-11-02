#!/usr/bin/env python3
"""Pawvest economy model (ROADMAP -> E0).

Reads every number that already exists in the game from the Luau configs in src/ReplicatedStorage (so the model
cannot drift silently), adds the planned content that is not in a config yet (PLANNED below, from the GDD / STAGES),
and reports the Coin economy.

  python tools/economy.py report   # baseline tables (faucets, sinks, obby hour, today's pen economy) and the crop field tables
  python tools/economy.py sim      # day-by-day simulation per archetype and purchase policy (--days, --seeds) incl. the field
  python tools/economy.py field    # catalogue size and ladder-scale comparison (how the guardrails move)
  python tools/economy.py check    # acceptance checks of E0 that can run so far (incl. guardrails A-C); exit 1 on a failure
  options: --garden pens|field|both (default field: pens become Field posts; pens = today's Coins-per-hour pens; both = grandfathered
           pens that pay AND work as posts), --crops min|mvp|full, --scale <ladder scale>,
           --offline-rate <x> (passive income while away relative to online, default 0.33; 1 = no difference), --offline-cap <hours> (field)
  python tools/economy.py drift    # only the drift check (configs vs tools/economy_pins.json and the formulas)
  python tools/economy.py pin      # accept the current config values as the reviewed state (rewrites the pins)

Drift workflow: when a price or rate changes in a config, `check` fails with the differing value. Re-run `report`, decide
whether the model still holds, then `pin`. The crop field's numbers that E1a2 copied into src/ReplicatedStorage/CropConfig.luau (crops, squares, expansions, Renown, barn, online / offline
rates) are read from that file and pinned like every other config. What CropConfig does not hold yet (upgrade prices, reserved sinks, the Gardener,
rare crops, the optional Radish / Carrot / Trophy pumpkin, guardrail bands) stays in the FIELD / CROP_DEFS blocks below, provisional.
All values are Coins before the pet multiplier unless a column says otherwise. Python 3.9+, standard library only.
"""
import argparse
import json
import math
import random
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
    "required_at": {("DoubleJump", 1): 6, ("DoubleJump", 2): 11, ("Dash", 2): 13, ("WallJump", 1): 16, ("Glide", 1): 17},
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


def apply_crop_config(P):
    """CropConfig.luau -> P["crop_cfg"] (what `pin` stores), the FIELD values marked (CropConfig) and the config crops of CROP_DEFS."""
    f = "CropConfig.luau"
    crops = luau(f, "CropConfig.Crops")
    start, top = luau(f, "CropConfig.StartSquares"), luau(f, "CropConfig.MaxSquares")
    exps = luau(f, "CropConfig.Expansions")
    if start + len(exps) != top:
        raise ValueError(f"CropConfig: StartSquares {start} + {len(exps)} Expansions != MaxSquares {top}")
    points = luau(f, "CropConfig.RenownPoints")
    cfg = {
        "crops": [[c["id"], c["tier"], c["growSeconds"] / 3600, c["sale"], c["seed"], c["renown"]] for c in crops],  # grow time in hours
        "squares": [start, top],
        "expansions": [[e["price"], e["renown"]] for e in exps],
        "renown": [points, luau(f, "CropConfig.RenownK"), luau(f, "CropConfig.RenownP")],
        "barn_capacity": luau(f, "CropConfig.BarnCapacity"),
        "rates": [luau(f, "CropConfig.OnlineRate"), luau(f, "CropConfig.OfflineRate"), luau(f, "CropConfig.OfflineCapSeconds") / 3600],  # hours
    }
    P["crop_cfg"] = cfg

    gate = {}
    for _, tier, _, _, _, renown in cfg["crops"]:
        if gate.setdefault(tier, renown) != renown:
            raise ValueError(f"CropConfig: crops of tier {tier} have different renown levels; the model gates per tier")
    gate.setdefault(1, 0)
    F = FIELD
    F["start_squares"], F["max_squares"] = start, top
    F["expansions"] = [(start + k + 1, price, renown) for k, (price, renown) in enumerate(cfg["expansions"])]
    F["tier_gate"] = gate
    F["renown"].update({"k": cfg["renown"][1], "p": cfg["renown"][2], "weight": {t + 1: w for t, w in enumerate(points)}})
    F["capacity"] = cfg["barn_capacity"]
    F["online_rate"], F["offline_rate"], F["offline_cap_h"] = cfg["rates"]

    by_id = {c[0]: c for c in cfg["crops"]}
    for d in CROP_DEFS:
        if "cfg" in d:
            _, tier, hours, sale, seed, renown = by_id[d["cfg"]]
            d.update({"tier": tier, "h": int(hours) if float(hours).is_integer() else hours, "sale": sale, "seed": seed, "gate": renown})
    missing = [i for i in by_id if i not in {d.get("cfg") for d in CROP_DEFS}]
    if missing:
        raise ValueError(f'CropConfig crops without a CROP_DEFS entry (add one with "cfg"): {missing}')


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
    P["medal_xp"] = luau("PetConfig.luau", "PetConfig.MedalXp")
    P["finish_xp"] = luau("PetConfig.luau", "PetConfig.FinishXp")
    P["coin_xp"] = luau("PetConfig.luau", "PetConfig.CoinXp")
    P["studs_per_xp"] = luau("PetConfig.luau", "PetConfig.StudsPerXp")
    P["max_move_xp"] = luau("PetConfig.luau", "PetConfig.MaxMoveXp")

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
    apply_crop_config(P)
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
        "pet_xp": [P["medal_xp"], P["finish_xp"], P["coin_xp"], P["studs_per_xp"], P["max_move_xp"]],
        "pen_prices": P["pen_prices"],
        "pen_rates": P["pen_rates"],
        "pen_level_rate": P["pen_level_rate"],
        "offline_cap_h": P["offline_cap_h"],
        "incubator_prices": P["incubator_prices"],
        "foods": [[f["id"], f["price"], f["xp"]] for f in P["foods"]],
        "coin_tiers": P["coin_tiers"],
        "coin_counts": {k: len(c) for k, c in sorted(P["coins_by_stage"].items())},
        # CropConfig (E1a2), the crop field; grow time and offline cap in hours; read at load, so --offline-rate / --offline-cap do not show up as drift
        "crop_field_crops": P["crop_cfg"]["crops"],  # [id, tier, grow hours, sale, seed, renown level]
        "crop_field_squares": P["crop_cfg"]["squares"],  # [StartSquares, MaxSquares]
        "crop_field_expansions": P["crop_cfg"]["expansions"],  # [price, renown level] per extra square
        "crop_field_renown": P["crop_cfg"]["renown"],  # [points per harvest by tier, RenownK, RenownP]
        "crop_field_barn_capacity": P["crop_cfg"]["barn_capacity"],
        "crop_field_rates": P["crop_cfg"]["rates"],  # [online rate, offline rate, offline cap in hours]
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


def covered_hours_per_day(P, arch, weighted=False):
    """Hours per day for which pens produce: online time plus the offline gap after each session, capped (GardenConfig).
    weighted: online hours x online_rate + offline hours x offline_rate (the passive-income rule); the baseline report uses today's unweighted hours."""
    on, off = pen_hours(P, arch, weighted)
    return on + off


def pen_hours(P, arch, weighted=True):
    """(online hours, offline hours) per day in which pens produce, weighted by the online / offline rate."""
    period_h = arch["period_days"] * 24.0
    sess = sorted(arch["sessions"])
    on = off = 0.0
    for i, (start, length) in enumerate(sess):
        nxt = sess[i + 1][0] if i + 1 < len(sess) else sess[0][0] + period_h
        on += length
        off += min(max(nxt - (start + length), 0.0), P["offline_cap_h"])
    wo, wf = (FIELD["online_rate"], FIELD["offline_rate"]) if weighted else (1.0, 1.0)
    return on * wo / arch["period_days"], off * wf / arch["period_days"]


def pet_bonus(P, kind_rarity, level):
    return P["rarities"][kind_rarity]["bonus"] + P["level_bonus"] * (level - 1)


# --------------------------------------------------------------------------------------------------------------------
# Day-by-day simulation of one player: obby, pets (XP, levels, multiplier), pens, purchases by policy.
# --------------------------------------------------------------------------------------------------------------------
SIM = {
    "learn_base": 5,  # runs to first-clear a stage with Gold (practice, deaths): learn_base + learn_per_order x order, each taking
    "learn_per_order": 1,  # T_base x learn_factor + overhead; provisional, to be replaced by telemetry (T1a funnels) after M6a
    "learn_factor": 1.4,
    "coin_capture": 0.8,  # share of a stage's challenge-coin value collected when it is first cleared
    "move_speed": 16.0,  # studs/s while a timer runs, for movement XP
    "move_share": 0.6,  # share of a run spent actually moving
    "egg_share": {"talent-first": 0.10, "pets-first": 0.35},  # share of leftover Coins spent on Basic eggs each day
    "food_share": {"talent-first": 0.03, "pets-first": 0.15},  # share of leftover Coins spent on food for equipped pets
    "keep_order": 3,  # spare pets below this rarity order (Rare = 3) are sold
    "window": 3,  # the player may skip at most 2 unaffordable items to buy a cheaper one behind them
    "pet_cap": 50,
}


# --------------------------------------------------------------------------------------------------------------------
# The crop FIELD (E0, EXPANSION §5, ROADMAP -> E0 "Field model"). Provisional: every number is a model assumption until E1
# copies the reviewed ones into CropConfig. Crop prices derive from the ladder (net Coins per square-hour x scale).
# --------------------------------------------------------------------------------------------------------------------
MULT_REF = 1.48  # pet multiplier of a developed player (cap +50 %), used by the static field tables

FIELD = {
    # Values marked (CropConfig) are None here: apply_crop_config() fills them from src/ReplicatedStorage/CropConfig.luau in load(). Edit them there.
    "scale": 0.3,  # global factor on the ladder below: the 20 / 45 / 90 / 150 of EXPANSION §5 break the 24-hour rule on a field of tens of squares.
    #                The CropConfig crops keep their config sale / seed at this scale; other scales (--scale, the sweeps) derive prices from the ladder.
    "ladder": {1: 20, 2: 45, 3: 90, 4: 150},  # net Coins per square-hour at scale 1, tier 4 = rare (obby-unlocked only); derives the model-only crops
    "seed_frac": 0.25,  # seed cost / sale price (EXPANSION §5: 20-30 %)
    "max_squares": None,  # (CropConfig.MaxSquares) the field the plot draws (decided 2026-10-25: 12 squares at ladder scale ~0.3)
    "start_squares": None,  # (CropConfig.StartSquares)
    # expansion tiers: (squares after the purchase, price in Coins, Renown gate); the free start field is `start_squares`
    "expansions": None,  # (CropConfig.Expansions)
    "tier_gate": None,  # (CropConfig.Crops[].renown, per tier) Renown needed to plant a tier (rare crops: seeds from the obby, no gate)
    # points for level L = k x L^p; request board = placeholder
    "renown": {"k": None, "p": None, "weight": None, "requests_per_day": 0.0},  # (CropConfig.RenownK / RenownP / RenownPoints)
    "gardener": {"share": 0.35, "squares": 1, "max_tier": 3},  # share of hatched pets with Green thumb; squares each Gardener replants; best tier it may plant
    "capacity": None,  # (CropConfig.BarnCapacity) seeds the stock holds and crops the barn holds between two visits (limits the Gardener's cycles)
    # upgrades: levels cost `prices`; growth = grow time x (1 - step x level); barn = capacity + step x level; gardener = squares + step x level
    "upgrades": {
        "growth": {"step": 0.05, "prices": [3000, 8000, 20000, 45000]},
        "barn": {"step": 20, "prices": [1500, 4000, 10000, 25000, 60000]},
        "gardener": {"step": 1, "prices": []},  # no coverage level: on 12 squares one more square per Gardener would cover the whole field (A 1.06x)
    },
    "rare": {"per_first_gold": 1, "daily": 1, "sale_share": 0.5},  # rare seeds from the obby; the rest of the harvest is kept for landmarks (placeholder)
    # sinks the model does not design yet (landmark Coins parts, estate tiers, decor, stations; EXPANSION §12): a geometric ladder, bought last
    "reserved": {"first": 8000, "ratio": 1.3, "count": 20},
    "bias": {"talent-first": 1.5, "pets-first": 0.7},  # field price x bias when merged into a policy's buying order
    "sink_share": {30: 0.60, 60: 0.80},  # OPEN decision 1 (proposal): sinks / cumulative faucet by day 30 and day 60
    "a_band": (0.8, 1.0),  # guardrail A: the best-developed archetype's 24 h field / first obby hour must land inside this band
    "garden_share_max_obby": 0.5,  # the garden must not be a majority of Obby main's income
    # Online vs offline (user rule 2026-10-24): everything passive (crop growth, Gardener replanting, pen production) runs at `online_rate` while the player is
    # in the experience and at `offline_rate` while away, for at most `offline_cap_h` hours after a session. Provisional: the user gave no number (open decision).
    "online_rate": None, "offline_rate": None, "offline_cap_h": None,  # (CropConfig.OnlineRate / OfflineRate / OfflineCapSeconds); pens keep GardenConfig.OfflineCapSeconds (8 h)
}

# Crop catalogue: tier 1-3 by Renown gate, tier 4 = rare (one signature crop per world 1-3). `h` = grow time in hours. `size` = 2 means a 2 x 2 crop.
# Entries with "cfg" are in CropConfig.Crops (that id): apply_crop_config() fills their tier, h (growSeconds / 3600), sale, seed and gate from it.
# The other entries are MODEL-ONLY, NOT YET IN CropConfig: the optional crops of `--crops full` (Radish, Carrot, 2 x 2 Trophy pumpkin) and the rare
# crops Rare W1 / W2 / W3 (come with milestone E2); their numbers are model parameters (sale / seed derive from the ladder x scale).
CROP_DEFS = [
    {"id": "Radish", "tier": 1, "h": 1 / 3},  # model-only, not in CropConfig
    {"id": "Carrot", "tier": 1, "h": 1},  # model-only, not in CropConfig
    {"id": "Potato", "cfg": "Potato"},
    {"id": "Corn", "cfg": "Corn"},
    {"id": "Pumpkin", "cfg": "Pumpkin"},
    {"id": "Giant melon", "cfg": "GiantMelon"},  # the CropConfig id is GiantMelon
    {"id": "Trophy pumpkin", "tier": 3, "h": 12, "size": 2},  # model-only, not in CropConfig
    {"id": "Rare W1", "tier": 4, "h": 6, "world": 1},  # model-only, rare crops come with E2 (not in CropConfig)
    {"id": "Rare W2", "tier": 4, "h": 8, "world": 2},  # model-only (E2)
    {"id": "Rare W3", "tier": 4, "h": 10, "world": 3},  # model-only (E2)
]
CATALOGUES = {
    "min": ["Potato", "Pumpkin", "Giant melon", "Rare W1", "Rare W2", "Rare W3"],  # one per tier + one rare per world
    "mvp": ["Potato", "Corn", "Pumpkin", "Giant melon", "Rare W1", "Rare W2", "Rare W3"],  # Corn fills the 6 h slot (+10 % for Obby main); Carrot / Radish add nothing
    "full": ["Radish", "Carrot", "Potato", "Corn", "Pumpkin", "Giant melon", "Trophy pumpkin", "Rare W1", "Rare W2", "Rare W3"],
}
POLICIES = ("talent-first", "pets-first")
GARDEN_MODES = ("pens", "field", "both")  # pens = today's Coins-per-hour pens; field = pens become Field posts (replace); both = grandfather (pens pay AND are posts)


def learn_runs(stage):
    return SIM["learn_base"] + SIM["learn_per_order"] * stage["order"]


def xp_next(level):
    return lua_round(10 * level ** 1.5)


def make_crops(scale, catalogue):
    """The crop table of a ladder scale and catalogue: sale = net per square-hour x grow time / (1 - seed share), seed = share of the sale."""
    F = FIELD
    crops = {}
    for c in CROP_DEFS:
        if c["id"] not in CATALOGUES[catalogue]:
            continue
        size = c.get("size", 1)
        net_h = F["ladder"][c["tier"]] * scale
        sale = max(2, round(net_h * c["h"] * size / (1 - F["seed_frac"])))
        seed = max(1, round(sale * F["seed_frac"]))
        if "cfg" in c and scale == F["scale"]:  # a CropConfig crop at the model's own scale: the config's prices, not the ladder's
            sale, seed = c["sale"], c["seed"]
        crops[c["id"]] = {"id": c["id"], "tier": c["tier"], "h": c["h"], "size": size, "sale": sale, "seed": seed, "net": sale - seed,
                          "rare": c["tier"] == 4, "world": c.get("world"), "gate": c.get("gate", F["tier_gate"].get(c["tier"], 0))}
    return crops


def build_field(P, mode="field", catalogue="mvp", scale=None):
    """P["field"]: the crop table, price lists and gates the simulation reads (FIELD x scale x catalogue)."""
    F = FIELD
    scale = F["scale"] if scale is None else scale
    crops = make_crops(scale, catalogue)
    prices = {"exp": [p for _, p, _ in F["expansions"]], "res": [round(F["reserved"]["first"] * F["reserved"]["ratio"] ** k, -2) for k in range(F["reserved"]["count"])]}
    for name, u in F["upgrades"].items():
        prices[name] = list(u["prices"])
    P["field"] = {"mode": mode, "catalogue": catalogue, "scale": scale, "crops": crops, "prices": prices,
                  "exp_squares": [s for s, _, _ in F["expansions"]], "exp_gate": [g for _, _, g in F["expansions"]],
                  "on": mode in ("field", "both"), "pens_pay": mode in ("pens", "both")}
    return P["field"]


def renown_level(points):
    R = FIELD["renown"]
    return int((max(points, 0.0) / R["k"]) ** (1 / R["p"]))


def visit_schedule(arch):
    """Sessions of one period: [(start hour, gap in hours to the next session start, session length)] (the wrap-around gap spans the idle days)."""
    sess = sorted(arch["sessions"])
    period_h = arch["period_days"] * 24.0
    return [(start, (sess[i + 1][0] if i + 1 < len(sess) else sess[0][0] + period_h) - start, length) for i, (start, length) in enumerate(sess)]


_ceil_cache = {}


def manual_day_ceiling(sched, period_days, options):
    """Online ceiling of one manually tended square: the best long-run Coins per square and day when the player is present for every gap
    (a crop is ripe once the visit gaps since planting add up to its grow time; it may span several visits). options = [(Coins per square, grow hours)]."""
    key = (tuple(sched), period_days, tuple(options))
    if key not in _ceil_cache:
        n, horizon, best = len(sched), 120, 0.0
        for start in range(n):
            gaps = [sched[(start + k) % n][1] for k in range(horizon)]
            f = [0.0] * (horizon + 1)
            for i in range(horizon - 1, -1, -1):
                v = f[i + 1]
                for val, h in options:
                    acc, j = 0.0, i
                    while j < horizon and acc < h - 1e-9:
                        acc += gaps[j]
                        j += 1
                    if acc >= h - 1e-9 and val + f[j] > v:
                        v = val + f[j]
                f[i] = v
            best = max(best, f[0] / sum(gaps) * 24.0)
        _ceil_cache[key] = best
    return _ceil_cache[key]


def eff_time(gap, length):
    """Growth hours a passive process gets between two visits: full speed while online, offline_rate for the capped time away."""
    return min(length, gap) * FIELD["online_rate"] + min(max(gap - length, 0.0), FIELD["offline_cap_h"]) * FIELD["offline_rate"]


FAMILIES = ("exp", "growth", "barn", "gardener", "res")


def policy_items(P, name):
    def T(tid, lo=1, hi=None):
        top = len(P["talents"][tid]["costs"])
        return [("talent", tid, lv) for lv in range(lo, (hi or top) + 1)]
    slots, incs, pens = [("slot", 2), ("slot", 3)], [("inc", 2), ("inc", 3)], [("pen", k) for k in range(2, 7)]
    rest = T("DoubleJump", 2) + T("Dash") + T("WallJump") + T("Glide")
    if name == "talent-first":
        items = (T("DoubleJump", 1, 1) + T("RunSpeed") + T("JumpHeight") + T("QuickRespawn")
                 + [slots[0], incs[0], pens[0], slots[1], pens[1], incs[1]] + pens[2:] + rest)
    else:
        items = ([slots[0], incs[0], pens[0], slots[1], incs[1], pens[1]] + pens[2:] + T("DoubleJump", 1, 1) + T("RunSpeed")
                 + T("JumpHeight") + T("QuickRespawn") + rest)
    if not P["field"]["on"]:
        return items
    field = [(fam, k + 1) for fam in FAMILIES[:4] for k in range(len(P["field"]["prices"][fam]))]
    field.sort(key=lambda it: item_price(P, it))
    out, i, j, bias = [], 0, 0, FIELD["bias"][name]
    while i < len(items) or j < len(field):  # merge two ordered lists by price, the field's price x the policy's bias
        if j >= len(field) or (i < len(items) and item_price(P, items[i]) <= item_price(P, field[j]) * bias):
            out.append(items[i])
            i += 1
        else:
            out.append(field[j])
            j += 1
    return out + [("res", k + 1) for k in range(len(P["field"]["prices"]["res"]))]


def item_price(P, it):
    if it[0] == "talent":
        return P["talents"][it[1]]["costs"][it[2] - 1]
    if it[0] in FAMILIES:
        return P["field"]["prices"][it[0]][it[1] - 1]
    return {"slot": P["slot_prices"], "pen": P["pen_prices"], "inc": P["incubator_prices"]}[it[0]][it[1] - 1]


def item_name(it):
    if it[0] == "talent":
        return f"{it[1]} L{it[2]}"
    return {"slot": "Pet slot", "pen": "Pen", "inc": "Incubator", "exp": "Field tier", "growth": "Growth", "barn": "Barn",
            "gardener": "Gardener coverage", "res": "Reserved sink"}[it[0]] + f" {it[1]}"


class Player:
    def __init__(self, P, arch, policy, rng, gardeners=True):
        self.P, self.arch, self.policy, self.rng = P, arch, policy, rng
        self.grng = random.Random(7919 + rng.getstate()[1][0] % 100000)  # separate stream: Green-thumb rolls must not shift the egg rolls
        self.stages = sorted(P["stages"], key=lambda s: s["order"])
        self.coins = 0.0
        self.done = []  # cleared stages
        self.learn_left = None
        self.talents = {t: 0 for t in P["talents"]}
        self.slots, self.pens, self.incs = 1, 1, 1
        self.lvl = {fam: 0 for fam in FAMILIES}  # owned levels of the field sinks
        self.pets = []  # {"r": rarity, "lvl": n, "xp": n, "g": Green thumb, "where": "eq" | "pen" | "spare"}
        self.free_eggs = 1  # the launch egg
        self.mult = 1.0
        self.afford, self.bought = {}, {}
        self.items = policy_items(P, policy)
        self.sessions = sorted(arch["sessions"])
        self.visits = len(arch["sessions"])  # visits on an active day
        self.sched = visit_schedule(arch)
        self.eq = []
        self.dt = {s["key"]: s["t_base"] * MODEL["gold_run_factor"] + MODEL["run_overhead_s"] for s in self.stages}
        self.cache = {}
        # field state
        self.F = P["field"]
        self.gardeners_on = gardeners
        self.sq = FIELD["start_squares"]
        self.post_g = 0  # Gardener pets on posts
        self.manual = []  # [crop id, planted at (h), plants]
        self.cov_crop, self.cov_n = None, 0
        self.cov_on = self.cov_off = 0.0  # growth progress of the Gardener squares' crop, hours earned online / offline
        self.last_len = 0.0
        self.seed_stock = 0
        self.rare_seeds = {}  # world -> seeds
        self.rare_kept = 0.0
        self.renown_pts = 0.0
        self.last_t = None
        self.spend, self.cum = {}, {"repeat": 0.0, "onetime": 0.0, "pen": 0.0, "field": 0.0, "sell": 0.0}
        self.stat = {"harv": 0.0, "man_harv": 0.0, "visit_sq": 0.0, "rare_given": 0.0}
        self.sold = 0.0
        self.manage()

    # ---- pets -------------------------------------------------------------------------------------------------
    def bonus(self, p):
        return self.P["rarities"][p["r"]]["bonus"] + self.P["level_bonus"] * (p["lvl"] - 1)

    def rate(self, p):
        return pen_rate(self.P, p["r"], p["lvl"])

    def manage(self):
        """Equip the best pets by bonus; pen / post the best of the rest; sell weak spares."""
        P, F = self.P, self.F
        pets = sorted(self.pets, key=lambda p: -self.bonus(p))
        for i, p in enumerate(pets):
            p["where"] = "eq" if i < self.slots else "spare"
        spare = [p for p in pets if p["where"] == "spare"]
        if F["mode"] == "field":  # pens became posts: Gardeners work them, other pets earn nothing there
            rest = sorted(spare, key=lambda p: (not p["g"], -self.bonus(p)))
            for p in [p for p in rest if p["g"]][: self.pens]:
                p["where"] = "pen"
        else:
            rest = sorted(spare, key=lambda p: -self.rate(p))
            for p in rest[: self.pens]:
                p["where"] = "pen"
        for p in [p for p in spare if p["where"] == "spare"]:
            if P["rarities"][p["r"]]["order"] < SIM["keep_order"]:
                self.coins += P["rarities"][p["r"]]["sell"]
                self.sold += P["rarities"][p["r"]]["sell"]
                self.pets.remove(p)
        self.eq = [p for p in self.pets if p["where"] == "eq"]
        self.post_g = sum(1 for p in self.pets if p["where"] == "pen" and p["g"])
        self.mult = 1 + min(P["max_bonus"], sum(self.bonus(p) for p in self.eq)) / 1000

    def add_xp(self, amount):
        levelled = False
        for p in self.eq:
            if p["lvl"] >= self.P["max_level"]:
                continue
            p["xp"] += amount
            while p["lvl"] < self.P["max_level"] and p["xp"] >= xp_next(p["lvl"]):
                p["xp"] -= xp_next(p["lvl"])
                p["lvl"] += 1
                levelled = True
        if levelled:
            self.mult = 1 + min(self.P["max_bonus"], sum(self.bonus(p) for p in self.eq)) / 1000

    def hatch(self, limit):
        """Start up to `limit` free eggs (bought eggs are hatched where they are bought); returns hatched count."""
        n = min(limit, self.free_eggs)
        for _ in range(n):
            self.free_eggs -= 1
            self.new_pet("Basic")
        return n

    def new_pet(self, egg):
        w = self.P["eggs"][egg]["weights"]
        r = self.rng.choices(list(w), weights=list(w.values()))[0]
        self.pets.append({"r": r, "lvl": 1, "xp": 0, "g": self.grng.random() < FIELD["gardener"]["share"], "where": "spare"})

    # ---- obby -------------------------------------------------------------------------------------------------
    def reward(self, s, n):
        key = (s["key"], n)
        if key not in self.cache:
            self.cache[key] = run_reward(self.P, s, 3, n)
        return self.cache[key]

    def run_xp(self, s, medal_xp):
        studs = SIM["move_speed"] * s["t_base"] * MODEL["gold_run_factor"] * SIM["move_share"]
        return medal_xp + min(self.P["max_move_xp"], int(studs // self.P["studs_per_xp"]))

    def required_missing(self, stage):
        reqs = sorted({(t, l) for (t, l), at in PLANNED["required_at"].items() if at <= stage["order"]})
        return [("talent", t, l) for t, l in reqs if self.talents[t] < l]

    def give_rare(self, world, count, row):
        if world >= 1 and count > 0:
            w = min(world, 3)
            self.rare_seeds[w] = self.rare_seeds.get(w, 0) + count
            self.stat["rare_given"] += count
            row["rare"] += count

    def play(self, minutes, day_row):
        budget = minutes * 60.0
        P = self.P
        # 1. learn new stages while talents allow
        while budget > 0 and len(self.done) < len(self.stages):
            s = self.stages[len(self.done)]
            if self.required_missing(s):
                day_row["blocked"] = 1
                break
            if self.learn_left is None:
                self.learn_left = learn_runs(s) * (s["t_base"] * SIM["learn_factor"] + MODEL["run_overhead_s"])
            spend = min(budget, self.learn_left)
            budget -= spend
            self.learn_left -= spend
            if self.learn_left > 1e-9:
                break
            self.learn_left = None
            coin_val = (sum(P["coins_by_stage"].get(s["key"], [])) if s["built"] else PLANNED["coins_per_planned_stage"]) * SIM["coin_capture"]
            pay = (stage_medal_total(P, s) + first_finish(P, s) + coin_val) * self.mult
            self.coins += pay
            day_row["onetime"] += pay
            self.add_xp(learn_runs(s) * self.run_xp(s, P["medal_xp"][0]) + int(coin_val / 40) * P["coin_xp"])
            self.free_eggs += 1  # first Gold of a stage gives a free Basic egg
            self.give_rare(s["world"], FIELD["rare"]["per_first_gold"], day_row)
            self.done.append(s)
        # 2. farm Gold runs on cleared stages (greedy by Coins per second, daily decay per stage)
        counts = {s["key"]: 0 for s in self.done}
        gold_xp = P["medal_xp"][2]
        ran = False
        while self.done:
            best = max(self.done, key=lambda s: self.reward(s, counts[s["key"]]) / self.dt[s["key"]])
            if self.dt[best["key"]] > budget:
                break
            budget -= self.dt[best["key"]]
            pay = self.reward(best, counts[best["key"]]) * self.mult
            counts[best["key"]] += 1
            self.coins += pay
            day_row["repeat"] += pay
            self.add_xp(self.run_xp(best, gold_xp))
            ran = True
        if ran and self.F["on"]:  # the daily first-run seed: a rare seed of one of the worlds reached
            worlds = sorted({min(s["world"], 3) for s in self.done if s["world"] >= 1})
            if worlds:
                self.give_rare(self.grng.choice(worlds), FIELD["rare"]["daily"], day_row)

    # ---- the field --------------------------------------------------------------------------------------------
    def renown_level(self):
        return renown_level(self.renown_pts)

    def growth(self):
        return 1 - FIELD["upgrades"]["growth"]["step"] * self.lvl["growth"]

    def capacity(self):
        return FIELD["capacity"] + FIELD["upgrades"]["barn"]["step"] * self.lvl["barn"]

    def per_gardener(self):
        return FIELD["gardener"]["squares"] + FIELD["upgrades"]["gardener"]["step"] * self.lvl["gardener"]

    def covered(self):
        return min(self.sq, self.post_g * self.per_gardener()) if self.gardeners_on and self.F["on"] else 0

    def sell(self, crop, items, row, on_share):
        if items <= 0:
            return
        share = FIELD["rare"]["sale_share"] if crop["rare"] else 1.0
        gross = items * share * crop["sale"] * self.mult
        self.coins += gross
        self.cum["field"] += gross
        row["field"] += gross
        row["field_on"] += gross * on_share
        row["field_off"] += gross * (1 - on_share)
        self.rare_kept += items * (1 - share) if crop["rare"] else 0.0
        row["harv"] += items
        self.stat["harv"] += items
        self.renown_pts += items * FIELD["renown"]["weight"][crop["tier"]]

    def pay(self, cat, amount, row=None):
        self.coins -= amount
        self.spend[cat] = self.spend.get(cat, 0.0) + amount
        if row is not None:
            row["seeds"] += amount

    def wall_to_ripe(self, idx, g):
        """Wall-clock hours from visit `idx` until a crop needing `g` growth hours is ripe at a visit (None if never)."""
        acc = wall = 0.0
        for k in range(120):
            _, gap, length = self.sched[(idx + k) % len(self.sched)]
            acc += eff_time(gap, length)
            wall += gap
            if acc >= g - 1e-9:
                return wall
        return None

    def visit(self, t, idx, row):
        """One visit (session start) at absolute hour t, entry `idx` of the schedule. Harvest what is ripe, sell, replant.
        Crops and Gardener squares grow at online_rate while the player was online and at offline_rate (capped) while away."""
        F, cat, gs = self.F, self.F["crops"], self.growth()
        _, gap, length = self.sched[idx]
        T = 0.0 if self.last_t is None else t - self.last_t
        d_on = min(self.last_len, T) * FIELD["online_rate"]
        d_off = min(max(T - self.last_len, 0.0), FIELD["offline_cap_h"]) * FIELD["offline_rate"]
        # 1. Gardener squares cycled by themselves since the last visit (limited by the seed stock and the barn)
        if self.cov_n and self.cov_crop:
            c = cat[self.cov_crop]
            g = c["h"] * gs
            self.cov_on += d_on
            self.cov_off += d_off
            prog = self.cov_on + self.cov_off
            raw = prog / g
            n = min(int(raw), self.capacity() // self.cov_n, self.seed_stock // self.cov_n)
            on_share = self.cov_on / prog if prog > 0 else 0.0
            if n >= int(raw):
                rest = prog - n * g
                self.cov_on, self.cov_off = on_share * rest, (1 - on_share) * rest
            else:  # barn or stock full: the ripe crop waits
                self.cov_on = self.cov_off = 0.0
            self.seed_stock -= n * self.cov_n
            self.sell(c, n * self.cov_n, row, on_share)
        # 2. manual squares: one harvest per square, if ripe
        keep = []
        for grp in self.manual:
            c = cat[grp[0]]
            g = c["h"] * gs
            grp[3] += d_on
            grp[4] += d_off
            if grp[3] + grp[4] >= g - 1e-9:
                self.sell(c, grp[2], row, min(grp[3], g) / g)
                self.stat["man_harv"] += grp[2]
            else:
                keep.append(grp)
        self.manual = keep
        # 3. coverage for the coming interval, then replant the empty manual squares
        self.cov_n = self.covered()
        lvl = self.renown_level()
        common = [c for c in cat.values() if not c["rare"] and c["size"] == 1 and c["gate"] <= lvl]
        big = [c for c in cat.values() if not c["rare"] and c["size"] > 1 and c["gate"] <= lvl]
        eff = eff_time(gap, length)
        if self.cov_n and common:
            best, best_v = None, -1.0
            for c in common:
                if c["tier"] > FIELD["gardener"]["max_tier"]:
                    continue
                g = c["h"] * gs
                prog = self.cov_on + self.cov_off if c["id"] == self.cov_crop else 0.0  # switching crop loses the growth in progress
                v = min((prog + eff) / g, self.capacity() / self.cov_n) * self.cov_n * c["net"] * (1.05 if c["id"] == self.cov_crop else 1.0)
                if v > best_v:
                    best, best_v, best_cyc = c, v, min(int((prog + eff) / g), self.capacity() // self.cov_n)
            if best is not None:
                if best["id"] != self.cov_crop:
                    self.cov_crop, self.cov_on, self.cov_off = best["id"], 0.0, 0.0
                need = max(0, best_cyc * self.cov_n - self.seed_stock)
                buy = min(need, int(max(self.coins, 0) // best["seed"]))
                self.pay("seeds", buy * best["seed"], row)
                self.seed_stock += buy
        else:
            self.cov_crop = None
        free = self.sq - self.cov_n - sum(grp[2] * cat[grp[0]]["size"] for grp in self.manual)
        for world in sorted(self.rare_seeds, reverse=True):  # rare seeds first (best first)
            rc = next((c for c in cat.values() if c["rare"] and c["world"] == world), None)
            while rc and self.rare_seeds[world] > 0 and free >= 1 and self.wall_to_ripe(idx, rc["h"] * gs) is not None:
                self.rare_seeds[world] -= 1
                self.manual.append([rc["id"], t, 1, 0.0, 0.0])
                free -= 1
        # the crop with the best net per square and wall-clock hour until it is ripe at a visit (it may span several visits)
        best, best_rate = None, 0.0
        for c in common + big:
            w = self.wall_to_ripe(idx, c["h"] * gs)
            if w and c["net"] / c["size"] / w > best_rate:
                best, best_rate = c, c["net"] / c["size"] / w
        if best and free >= 1:
            plants = min(int(free // best["size"]), int(max(self.coins, 0) // best["seed"]))
            if plants > 0:
                self.pay("seeds", plants * best["seed"], row)
                self.manual.append([best["id"], t, plants, 0.0, 0.0])
                self.stat["visit_sq"] += plants * best["size"]
        self.last_t, self.last_len = t, length

    def potential(self, ignore_gardeners=False):
        """Guardrail A: Coins per day (before the multiplier) of the current field if every square is planted and replanted at every
        opportunity with the best unlocked crop: Gardener squares cycle 24 h a day, the others give one harvest per visit."""
        F, gs = self.F, self.growth()
        lvl = self.renown_level()
        common = [c for c in F["crops"].values() if not c["rare"] and c["gate"] <= lvl]
        if not F["on"]:
            return 0.0, 0.0
        cov = 0 if ignore_gardeners else self.covered()
        gard = [c for c in common if c["size"] == 1 and c["tier"] <= FIELD["gardener"]["max_tier"]]
        m = self.mult  # sales are multiplied at sale time, seeds are not: the multiplier counts on this side as on the hour-1 side
        value = lambda c: m * c["sale"] - c["seed"]
        auto = cov * max((24 / (c["h"] * gs) * value(c) for c in gard), default=0.0)
        # online ceiling: the player is present for the whole gap (offline can only be lower)
        per_day = manual_day_ceiling(self.sched, self.arch["period_days"], [(value(c) / c["size"], c["h"] * gs) for c in common])
        manual = (self.sq - cov) * per_day
        if F["pens_pay"]:  # --garden both: the grandfathered pens still pay Coins per hour, uncapped by the 24-hour rule
            auto += sum(self.rate(p) for p in self.pets if p["where"] == "pen") * 24 * m * FIELD["online_rate"]
        return auto, manual

    # ---- money ------------------------------------------------------------------------------------------------
    def level_of(self, fam):
        return {"slot": self.slots, "pen": self.pens, "inc": self.incs}.get(fam, self.lvl.get(fam))

    def owned(self, it):
        if it[0] == "talent":
            return self.talents[it[1]] >= it[2]
        return self.level_of(it[0]) >= it[1]

    def prereq_ok(self, it):
        if it[0] == "talent":
            return self.talents[it[1]] == it[2] - 1
        return self.level_of(it[0]) == it[1] - 1

    def gate_ok(self, it):
        return it[0] != "exp" or self.renown_level() >= self.F["exp_gate"][it[1] - 1]

    def buy(self, it, day):
        self.pay(it[0], item_price(self.P, it))
        if it[0] == "talent":
            self.talents[it[1]] = it[2]
        elif it[0] == "slot":
            self.slots = it[1]
        elif it[0] == "pen":
            self.pens = it[1]
        elif it[0] == "inc":
            self.incs = it[1]
        else:
            self.lvl[it[0]] = it[1]
            if it[0] == "exp":
                self.sq = self.F["exp_squares"][it[1] - 1]
        self.bought.setdefault(it, day)
        self.manage()

    def shop(self, day, day_row):
        P = self.P
        for it in self.items:
            if it not in self.afford and self.coins >= item_price(P, it) and self.gate_ok(it):
                self.afford[it] = day
        for it in sorted({it for s in self.stages for it in self.required_missing(s)}):
            if it not in self.afford and self.coins >= item_price(P, it):
                self.afford[it] = day
        used = self.hatch(self.incs * self.visits)
        saving = False
        while True:
            need = self.required_missing(self.stages[min(len(self.done), len(self.stages) - 1)]) if len(self.done) < len(self.stages) else []
            need = [it for it in need if self.prereq_ok(it)]
            if need:
                it = min(need, key=lambda x: item_price(P, x))
                if self.coins >= item_price(P, it):
                    self.buy(it, day)
                    continue
                saving = True
                break
            cand = [it for it in self.items if not self.owned(it) and self.prereq_ok(it) and self.gate_ok(it)][: SIM["window"]]
            hit = next((it for it in cand if self.coins >= item_price(P, it)), None)
            if hit is None:
                break
            self.buy(hit, day)
        used += self.hatch(self.incs * self.visits - used)
        if not saving:
            # eggs: Basic eggs bought into free incubator capacity, limited by the pet cap
            room = SIM["pet_cap"] - len(self.pets)
            cap = max(0, min(self.incs * self.visits - used, room))
            n_eggs = int(min(cap, (self.coins * SIM["egg_share"][self.policy]) // P["eggs"]["Basic"]["price"]))
            for _ in range(n_eggs):
                self.pay("egg", P["eggs"]["Basic"]["price"])
                self.new_pet("Basic")
            if n_eggs:
                self.manage()
            budget = self.coins * SIM["food_share"][self.policy]
            for food in sorted(P["foods"], key=lambda f: -f["xp"]):
                while budget >= food["price"] and any(p["where"] == "eq" and p["lvl"] < P["max_level"] for p in self.pets):
                    tgt = min((p for p in self.pets if p["where"] == "eq" and p["lvl"] < P["max_level"]), key=lambda p: p["lvl"])
                    budget -= food["price"]
                    self.pay("food", food["price"])
                    tgt["xp"] += food["xp"]
                    while tgt["lvl"] < P["max_level"] and tgt["xp"] >= xp_next(tgt["lvl"]):
                        tgt["xp"] -= xp_next(tgt["lvl"])
                        tgt["lvl"] += 1
                    self.manage()

    def day(self, d):
        a = self.arch
        row = {"repeat": 0.0, "onetime": 0.0, "pen": 0.0, "field": 0.0, "seeds": 0.0, "harv": 0.0, "rare": 0, "blocked": 0,
               "field_on": 0.0, "field_off": 0.0, "pen_on": 0.0, "pen_off": 0.0}
        sold0 = self.sold
        active = d % a["period_days"] == 0
        if active:
            self.play(a["obby_min"], row)
        if self.F["on"]:
            self.renown_pts += FIELD["renown"]["requests_per_day"]
            if active:
                for idx, (start, _gap, _length) in enumerate(self.sched):
                    self.visit(d * 24.0 + start, idx, row)
        pen_rate_now = sum(self.rate(p) for p in self.pets if p["where"] == "pen")
        if self.F["pens_pay"]:
            h_on, h_off = pen_hours(self.P, a)
            row["pen_on"], row["pen_off"] = pen_rate_now * h_on * self.mult, pen_rate_now * h_off * self.mult
            row["pen"] = row["pen_on"] + row["pen_off"]
        self.coins += row["pen"]
        if active:
            self.shop(d + 1, row)
        pen_rate_after = sum(self.rate(p) for p in self.pets if p["where"] == "pen") if self.F["pens_pay"] else 0.0
        row["sell"] = self.sold - sold0
        for k in ("repeat", "onetime", "pen", "sell"):
            self.cum[k] += row[k]
        auto, manual = self.potential()
        pot0 = sum(self.potential(True))
        h1 = hour1(self.P, self.done)
        row.update({
            "stage": len(self.done), "mult": self.mult, "bank": self.coins, "pets": len(self.pets),
            "eq_lvl": sum(p["lvl"] for p in self.eq) / len(self.eq) if self.eq else 0, "pen_h": pen_rate_after,
            "talents": sum(self.talents.values()), "pens": self.pens, "hour1": h1,
            "sq": self.sq, "cov": self.covered(), "post_g": self.post_g, "renown": self.renown_level(),
            "f24_auto": auto, "f24_man": manual, "f24_0": pot0, "ratio": (auto + manual) / (h1 * self.mult) if h1 else 0.0,
            "faucet": sum(self.cum.values()), "sink": sum(self.spend.values()), "spend": dict(self.spend),
            "field_net": row["field"] - row["seeds"],
        })
        return row


_hour1_cache = {}


def hour1(P, done):
    key = len(done)
    if key not in _hour1_cache:
        _hour1_cache[key] = obby_sim(P, done, 65)[2][0] if done else 0
    return _hour1_cache[key]


def simulate(P, arch, policy, days, seeds, gardeners=True):
    runs = []
    for seed in range(seeds):
        pl = Player(P, arch, policy, random.Random(1000 + seed), gardeners)
        runs.append(([pl.day(d) for d in range(days)], pl))
    return runs


def mean(xs):
    xs = list(xs)
    return sum(xs) / len(xs) if xs else 0.0


_G_CACHE = {}


def guardrails(P, days=60, seeds=6):
    """Run every archetype x policy (with and without Gardeners) and collect the numbers of guardrails A, B, C. Cached per setting."""
    key = (P["field"]["mode"], P["field"]["catalogue"], P["field"]["scale"], days, seeds, json.dumps(FIELD, sort_keys=True, default=str))
    if key in _G_CACHE:
        return _G_CACHE[key]
    out = {}
    for arch in ARCHETYPES:
        for pol in POLICIES:
            runs = simulate(P, arch, pol, days, seeds)
            runs0 = simulate(P, arch, pol, days, seeds, gardeners=False)
            m = {"runs": runs}
            worst = (0.0, 0, 0)
            for si, (rows, _) in enumerate(runs):
                for d, r in enumerate(rows):
                    if r["hour1"] and r["ratio"] > worst[0]:
                        worst = (r["ratio"], d + 1, si)
            m["a_max"], m["a_day"], m["a_seed"] = worst
            last = [rows[-1] for rows, _ in runs]
            m["a_final"] = mean(r["ratio"] for r in last)
            m["a_auto"] = mean(r["f24_auto"] / (r["hour1"] * r["mult"]) for r in last)
            m["a_man"] = mean(r["f24_man"] / (r["hour1"] * r["mult"]) for r in last)
            w = slice(max(0, days - 7), days)
            m["net_g"] = mean(mean(r["field_net"] for r in rows[w]) for rows, _ in runs)
            m["net_0"] = mean(mean(r["field_net"] for r in rows[w]) for rows, _ in runs0)
            m["gross_g"] = mean(mean(r["field"] for r in rows[w]) for rows, _ in runs)
            m["pot_g"] = mean(r["f24_auto"] + r["f24_man"] for r in last)
            m["pot_0"] = mean(r["f24_0"] for r in last)  # the same field with no Gardener
            m["b_struct"] = all(r["f24_auto"] + r["f24_man"] >= r["f24_0"] - 1e-9 for rows, _ in runs for r in rows)
            for dd in (30, 60):
                if dd <= days:
                    m[f"sink{dd}"] = mean(rows[dd - 1]["sink"] / max(1.0, rows[dd - 1]["faucet"]) for rows, _ in runs)
                    nores = lambda r: sum(v for k, v in r["spend"].items() if k != "res")
                    if dd == 60:
                        m["res60"] = mean(rows[-1]["spend"].get("res", 0.0) for rows, _ in runs)
                        m["res_need60"] = max(0.0, mean(FIELD["sink_share"][60] * rows[-1]["faucet"] - nores(rows[-1]) for rows, _ in runs))
                    m[f"sink{dd}_nores"] = mean(nores(rows[dd - 1]) / max(1.0, rows[dd - 1]["faucet"]) for rows, _ in runs)
            m["garden_share"] = mean(
                mean(r["field"] + r["pen"] for r in rows[w]) / max(1.0, mean(r["repeat"] + r["onetime"] + r["pen"] + r["field"] + r["sell"] for r in rows[w]))
                for rows, _ in runs)
            m["bank"] = mean(rows[-1]["bank"] for rows, _ in runs)
            # online vs offline: garden income (field + pens) earned during online hours vs offline hours, last 7 days
            inc_on = mean(mean(r["field_on"] + r["pen_on"] for r in rows[w]) for rows, _ in runs)
            inc_off = mean(mean(r["field_off"] + r["pen_off"] for r in rows[w]) for rows, _ in runs)
            on_h = sum(length for _, length in arch["sessions"]) / arch["period_days"]
            m["on_hours"], m["inc_on"], m["inc_off"] = on_h, inc_on, inc_off
            m["on_share"] = inc_on / max(1e-9, inc_on + inc_off)
            m["inc_h_on"], m["inc_h_off"] = inc_on / on_h, inc_off / (24.0 - on_h)
            m["oo_ratio"] = m["inc_h_on"] / m["inc_h_off"] if m["inc_h_off"] > 1e-9 else math.inf
            m["real_ratio"] = mean(mean(r["field_net"] for r in rows[w]) / max(1.0, r["hour1"] * r["mult"]) for rows, _ in runs)  # realised net per day / the first obby hour
            out[(arch["name"], pol)] = m
    _G_CACHE[key] = out
    return out


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
        ("Planned talent tree", 44300, full_tree),  # 47 300 until Double Jump became a world reward (K1, 2026-11-01)
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


def run_checks(P, days=60, seeds=6):
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
    results.extend(field_checks(P, days, seeds))
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
    field_report(P)


def cmd_check(P, days, seeds):
    results = run_checks(P, days, seeds)
    for name, ok, detail in results:
        print(f"[{tick(ok):4}] {name}" + (f"  ({detail})" if detail else ""))
    failed = [r for r in results if not r[1]]
    print(f"\n{len(results) - len(failed)} / {len(results)} checks pass" + ("" if not failed else f", {len(failed)} FAIL"))
    print("Not implemented yet (E0 continues): dead end (7), rare-crop supply (8), repricing (10), sensitivity (11).")
    return 1 if failed else 0


def field_checks(P, days=60, seeds=6):
    """Acceptance checks 4-6 (guardrails A, B, C) and the garden share of Obby main, from the day-by-day simulation."""
    if not P["field"]["on"]:
        return [("4-6 Field guardrails A, B, C", True, "skipped: --garden pens has no field")]
    G = guardrails(P, days, seeds)
    res, lo, hi = [], *FIELD["a_band"]
    for arch in ARCHETYPES:
        nm = arch["name"]
        ms = {pol: G[(nm, pol)] for pol in POLICIES}
        w = max(ms.values(), key=lambda m: m["a_max"])
        fin = " / ".join(f"{ms[p]['a_final']:.2f}x" for p in POLICIES)
        res.append((f"4 A 24-hour rule, {nm}: field over 24 h <= first obby hour, every day", w["a_max"] <= 1.0,
                    f"worst {w['a_max']:.2f}x on day {w['a_day']}; day {days}: {fin} (talent-first / pets-first)"))
    for pol in POLICIES:
        best = max(ARCHETYPES, key=lambda a: G[(a["name"], pol)]["a_final"])
        v = G[(best["name"], pol)]["a_final"]
        res.append((f"4 A target band {lo}-{hi}x at day {days}, best-developed archetype, {pol}", lo <= v <= hi, f"{v:.2f}x ({best['name']})"))
    for arch in ARCHETYPES:
        nm = arch["name"]
        bad = [pol for pol in POLICIES if not (G[(nm, pol)]["b_struct"] and G[(nm, pol)]["pot_g"] > G[(nm, pol)]["pot_0"] + 1e-9
                                                and G[(nm, pol)]["net_g"] > G[(nm, pol)]["net_0"])]
        d = "; ".join(f"{pol}: 24 h potential {n(G[(nm, pol)]['pot_g'])} with / {n(G[(nm, pol)]['pot_0'])} without Gardeners, net/day {n(G[(nm, pol)]['net_g'])} / {n(G[(nm, pol)]['net_0'])}"
                      for pol in POLICIES)
        res.append((f"5 B Gardener-run field beats the same field without a Gardener, {nm}", not bad, d))
    for arch in ARCHETYPES:
        nm = arch["name"]
        ms = [G[(nm, pol)] for pol in POLICIES]
        s30, s60 = min(m["sink30"] for m in ms), min(m["sink60"] for m in ms)
        r30, r60 = min(m["sink30_nores"] for m in ms), min(m["sink60_nores"] for m in ms)
        resv = max(m["res60"] for m in ms)
        res.append((f"6 C sink share, {nm}: >= {FIELD['sink_share'][30]:.0%} by day 30 and >= {FIELD['sink_share'][60]:.0%} by day 60",
                    s30 >= FIELD["sink_share"][30] and s60 >= FIELD["sink_share"][60],
                    f"day 30 {s30:.0%}, day 60 {s60:.0%} (worst policy); without the reserved sinks {r30:.0%} / {r60:.0%}; "
                    f"reserved sinks bought {n(resv)}, needed for {FIELD['sink_share'][60]:.0%} by day 60: {n(max(m['res_need60'] for m in ms))}"))
    need = 1 / FIELD["offline_rate"] if FIELD["offline_rate"] > 0 else math.inf
    for arch in ARCHETYPES:
        nm = arch["name"]
        ms = [G[(nm, pol)] for pol in POLICIES]
        r = min(m["oo_ratio"] for m in ms)
        res.append((f"O Online income per hour >= {need:.1f}x offline income per hour, {nm} (online_rate {FIELD['online_rate']}, offline_rate {FIELD['offline_rate']})",
                    r >= need - 1e-6 and min(m["inc_off"] for m in ms) > 0,
                    f"garden income earned in online hours {min(m['on_share'] for m in ms):.0%}-{max(m['on_share'] for m in ms):.0%} (online {ms[0]['on_hours']:.1f} h a day); "
                    f"per hour online {n(min(m['inc_h_on'] for m in ms))} vs offline {n(max(m['inc_h_off'] for m in ms))} = {r:.1f}x"))
    for arch in ARCHETYPES:
        nm = arch["name"]
        sh = [G[(nm, pol)]["garden_share"] for pol in POLICIES]
        txt = f"garden share of income, last 7 days: {sh[0]:.0%} / {sh[1]:.0%}"
        if nm == "Obby main":
            res.append(("6 Garden income is not a majority for Obby main", max(sh) <= FIELD["garden_share_max_obby"], txt))
        else:
            res.append((f"6 Garden share reported, {nm}", True, txt))
    return res


def cmd_sim(P, days, seeds):
    import statistics
    F = P["field"]
    print(f"DAY-BY-DAY SIMULATION: {days} days, {seeds} seeds per cell (egg rolls differ), pet multiplier ON, Coins after the multiplier")
    print(f"Garden mode: {F['mode']} ({'pens pay Coins per hour' if F['pens_pay'] else 'pens are Field posts, no Coins per hour'}"
          f"{'; Field squares and crops ON' if F['on'] else ''}); catalogue {F['catalogue']} ({len(F['crops'])} crops), ladder scale {F['scale']}")
    print(f"Passive income: online_rate {FIELD['online_rate']}, offline_rate {FIELD['offline_rate']} (field offline cap {FIELD['offline_cap_h']:g} h, pens {P['offline_cap_h']:g} h)\n")
    print("Assumptions (SIM / MODEL / FIELD blocks in economy.py, all provisional): a new stage takes "
          f"({SIM['learn_base']} + {SIM['learn_per_order']} x stage number) runs x (T_base x {SIM['learn_factor']} + {MODEL['run_overhead_s']:.0f} s) and ends in Gold; farming = Gold runs, greedy;\n"
          "required talents are bought first (saving for them blocks other purchases); stage unlocks are never bought; Golden eggs are not bought;\n"
          "equipped pets (best bonus) get the full XP of each run; the next best pets sit in pens / on posts; spare Common / Uncommon pets are sold;\n"
          "field: every visit harvests what is ripe, sells it (pet multiplier at sale time), buys seeds and replants; Gardeners cycle their squares between visits.\n")
    G = guardrails(P, days, seeds)
    snaps = [d for d in (1, 3, 7, 14, 30, 45, 60) if d <= days]
    for policy in POLICIES:
        afford_rows = {}
        for arch in ARCHETYPES:
            runs = G[(arch["name"], policy)]["runs"]

            def avg(key, d, window=1):
                vals = [sum(r[key] for r in rows[max(0, d - window):d]) / len(rows[max(0, d - window):d]) for rows, _ in runs]
                return sum(vals) / len(vals)
            print(f"== {policy} / {arch['name']} (obby {arch['obby_min']} min per {arch['period_days']} d; incomes = mean of the last 7 days)")
            rows = []
            for d in snaps:
                inc = [avg(k, d, 7) for k in ("repeat", "onetime", "pen", "field")]
                rows.append((d, f"{avg('stage', d):.0f}", f"{avg('talents', d):.0f}", f"{avg('pets', d):.0f}", f"{avg('eq_lvl', d):.1f}",
                             f"{avg('mult', d):.2f}", n(inc[0]), n(inc[1]), n(inc[2]), n(inc[3]), f"{(inc[2] + inc[3]) / max(1, sum(inc)):.0%}",
                             n(avg("bank", d))))
            print(table(["Day", "Stages", "Talents", "Pets", "Eq Lv", "Mult", "Repeat/d", "One-time/d", "Pens/d", "Field/d", "Garden share", "Bank"], rows))
            if F["on"]:
                rows = []
                for d in snaps:
                    rows.append((d, f"{avg('sq', d):.0f}", f"{avg('cov', d):.0f}", f"{avg('post_g', d):.1f}", f"{avg('renown', d):.0f}", n(avg("harv", d, 7)),
                                 n(avg("seeds", d, 7)), n(avg("field_net", d, 7)), f"{avg('ratio', d):.2f}x",
                                 f"{avg('sink', d) / max(1, avg('faucet', d)):.0%}", n(avg("faucet", d))))
                print("   field:")
                print(table(["Day", "Squares", "Covered", "Gardeners", "Renown", "Harvests/d", "Seeds/d", "Field net/d", "24h/h1 (A)", "Sink share", "Faucet cum."], rows))
                last = [r[-1]["spend"] for r, _ in runs]
                tot = {k: sum(s.get(k, 0) for s in last) / len(last) for k in sorted({k for s in last for k in s})}
                allv = sum(tot.values())
                print("   sinks to day %d: " % days + ", ".join(f"{k} {n(v)} ({v / allv:.0%})" for k, v in sorted(tot.items(), key=lambda kv: -kv[1]) if v > 0))
                gm = G[(arch["name"], policy)]
                print(f"   online vs offline (last 7 days): garden income {n(gm['inc_on'])} online / {n(gm['inc_off'])} offline per day = {gm['on_share']:.0%} online "
                      f"({gm['on_hours']:.1f} online hours a day); per hour {n(gm['inc_h_on'])} online vs {n(gm['inc_h_off'])} offline = {gm['oo_ratio']:.1f}x; "
                      f"realised field net / online ceiling's yardstick (first obby hour) {gm['real_ratio']:.2f}x")
                rare = statistics.mean(sum(r["rare"] for r in rows_) for rows_, _ in runs) / max(1, days) * 7
                print(f"   rare seeds from the obby: {rare:.1f} a week on average; stage/day-60 pet multiplier {avg('mult', days):.2f}")
            blocked = statistics.mean(sum(r["blocked"] for r in rws) for rws, _ in runs)
            print(f"   days blocked by a missing required talent: {blocked:.1f}\n")
            for it in sorted({it for _, pl in runs for it in list(pl.afford) + list(pl.bought)}, key=lambda x: (x[0] != "talent", x[0], x[1], x[2] if len(x) > 2 else 0)):
                med = lambda attr: statistics.median([getattr(pl, attr).get(it, math.inf) for _, pl in runs])
                a, b = med("afford"), med("bought")
                afford_rows.setdefault(it, {})[arch["name"]] = f"{'-' if a == math.inf else int(a)}/{'-' if b == math.inf else int(b)}"
        print(f"Time to afford / time bought (median day, '-' = not within {days} days) -- {policy}")
        order = sorted(afford_rows, key=lambda x: (x[0] != "talent", x[0], x[1], x[2] if len(x) > 2 else 0))
        print(table(["Sink", "Price"] + [a["name"] for a in ARCHETYPES],
                    [[item_name(it), n(item_price(P, it))] + [afford_rows[it].get(a["name"], "-") for a in ARCHETYPES] for it in order if it[0] != "res" or it[1] % 4 == 1]))
        print()
    print("24h/h1 (A) = the field's 24-hour potential (Gardener squares cycle 24 h, the others give one harvest per visit, every square always replanted, net of\n"
          "seeds) divided by the player's first obby hour at the same progress; the multiplier is on both sides. > 1 breaks the 24-hour rule.\n")
    if F["on"]:
        print("GUARDRAILS (also in `check`)")
        for name, ok, detail in field_checks(P, days, seeds):
            print(f"[{tick(ok):4}] {name}  ({detail})")


def cmd_field(P, days, seeds):
    """Catalogue and ladder-scale comparison: how the guardrails move with the number of crops and the price scale."""
    saved = (P["field"]["catalogue"], P["field"]["scale"], P["field"]["mode"])
    print("CATALOGUE COMPARISON (ladder scale %s, garden mode %s; A = worst 24 h field / first obby hour, day-60 field net per day, talent-first)" % (saved[1], saved[2]))
    rows = []
    for name in CATALOGUES:
        build_field(P, saved[2], name, saved[1])
        G = guardrails(P, days, seeds)
        for arch in ARCHETYPES:
            m = G[(arch["name"], "talent-first")]
            rows.append((name, len(P["field"]["crops"]), arch["name"], f"{m['a_max']:.2f}x", f"{m['a_final']:.2f}x", n(m["net_g"]), f"{m['garden_share']:.0%}", f"{m['sink60']:.0%}"))
    print(table(["Catalogue", "Crops", "Archetype", "A worst", "A day 60", "Field net/d", "Garden share", "Sink day 60"], rows, right_from=3))
    print("\nLADDER SCALE SWEEP (catalogue %s, talent-first)" % saved[0])
    rows = []
    for sc in (1.0, 0.5, 0.35, 0.25, 0.15):
        build_field(P, saved[2], saved[0], sc)
        G = guardrails(P, days, seeds)
        for arch in ARCHETYPES:
            m = G[(arch["name"], "talent-first")]
            rows.append((sc, arch["name"], f"{m['a_max']:.2f}x", f"{m['a_final']:.2f}x", n(m["net_g"]), f"{m['garden_share']:.0%}", f"{m['sink60']:.0%}"))
    print(table(["Scale", "Archetype", "A worst", "A day 60", "Field net/d", "Garden share", "Sink day 60"], rows, right_from=2))
    build_field(P, saved[2], saved[0], saved[1])


def field_report(P):
    F = P["field"]
    print(f"\n7. The crop field (provisional, FIELD block; ladder scale {F['scale']}, catalogue {F['catalogue']}, garden mode {F['mode']})")
    rows = []
    for c in sorted(F["crops"].values(), key=lambda c: (c["tier"], c["h"])):
        hrs = f"{c['h'] * 60:.0f} min" if c["h"] < 1 else f"{c['h']:.0f} h"
        rows.append((c["id"], "rare W%d" % c["world"] if c["rare"] else c["tier"], hrs, f"{c['size']}x{c['size']}" if c["size"] > 1 else "1", c["sale"], c["seed"],
                     c["net"], f"{c['net'] / c['h'] / c['size']:.1f}", f"{c['seed'] / c['sale']:.0%}", "obby" if c["rare"] else f"Renown {c['gate']}"))
    print(table(["Crop", "Tier", "Grow", "Squares", "Sale", "Seed", "Net", "Net/square-h", "Seed share", "Unlock"], rows, right_from=3))
    print(f"\n   Expansion tiers (free start field {FIELD['start_squares']} squares; provisional ceiling {FIELD['max_squares']}):")
    cum, rows = 0, []
    for k, (sq, price, gate) in enumerate(FIELD["expansions"]):
        cum += price
        rows.append((k + 1, sq, n(price), gate, n(cum)))
    print(table(["Tier", "Squares", "Price", "Renown", "Cumulative"], rows, right_from=0))
    print("   Upgrades: " + "; ".join(f"{name} ({'+' if name != 'growth' else '-'}{u['step'] if name != 'growth' else str(round(u['step'] * 100)) + ' % grow time'} per level) " + "/".join(n(p) for p in u["prices"])
                                      for name, u in FIELD["upgrades"].items() if u["prices"]))
    res = F["prices"]["res"]
    print(f"   Reserved sink ladder (landmarks / estate / decor placeholder): {len(res)} steps from {n(res[0])} to {n(res[-1])}, total {n(sum(res))}")
    print(f"   Gardener: {FIELD['gardener']['share']:.0%} of hatched pets have Green thumb, each replants {FIELD['gardener']['squares']} square(s), posts = pens owned (prices unchanged).")

    print()
    print("8. Structural value of one square per day by archetype (Coins after the multiplier "
          f"{MULT_REF}, minus seeds; one harvest per visit, the best crop that is ripe by the next visit; Gardener square = best crop cycling 24 h)")
    h1 = hour1(P, list(P["stages"]))
    budget = 0.9 * h1 * MULT_REF
    rows, casual_model = [], None
    for sc in (1.0, 0.5, 0.25, FIELD["scale"], 0.1, 0.05):
        cs = [c for c in make_crops(sc, F["catalogue"]).values() if not c["rare"] and c["size"] == 1]
        val = lambda c: MULT_REF * c["sale"] - c["seed"]
        per = [manual_day_ceiling(visit_schedule(a), a["period_days"], [(val(c), c["h"]) for c in cs]) for a in ARCHETYPES]
        auto = max(24 / c["h"] * val(c) for c in cs)
        if sc == FIELD["scale"]:
            casual_model = per[1]
        rows.append([sc if sc != FIELD["scale"] else f"{sc} (model)", n(auto)] + [n(p) for p in per] + [f"{budget / auto:.0f}"] + [f"{budget / p:.0f}" for p in per[:3]])
    print(table(["Ladder scale", "Gardener sq/day"] + [a["name"] + " sq/day" for a in ARCHETYPES] + ["Fits, all Gardener", "Fits, manual: Obby", "Casual", "Garden"], rows))
    print(f"   Last stage: first obby hour {n(h1)} ({n(h1 * MULT_REF)} with the multiplier); 'Fits' = squares whose 24 h potential stays at 0.9x of it.")
    print("   Read: the ladder of EXPANSION §5 as written (scale 1) fits only 4-7 squares; squares x scale is what the rule limits:")
    for squares in (FIELD["max_squares"], 24, 150):
        sc = FIELD["scale"] * budget / squares / casual_model
        potato = make_crops(sc, "min")["Potato"]
        print(f"   - {squares} squares (all manual, Casual's long gaps) -> scale {sc:.3f} (a potato sells for {potato['sale']} Coins, seed {potato['seed']})")


def main():
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass
    ap = argparse.ArgumentParser(description="Pawvest economy model (ROADMAP E0)")
    ap.add_argument("command", choices=["report", "sim", "field", "check", "drift", "pin"])
    ap.add_argument("--garden", choices=GARDEN_MODES, default="field")
    ap.add_argument("--crops", choices=list(CATALOGUES), default="mvp")
    ap.add_argument("--scale", type=float, default=None)
    ap.add_argument("--offline-rate", type=float, default=None)
    ap.add_argument("--offline-cap", type=float, default=None)
    ap.add_argument("--days", type=int, default=60)
    ap.add_argument("--seeds", type=int, default=6)
    args = ap.parse_args()
    P = load()
    if args.offline_rate is not None:
        FIELD["offline_rate"] = args.offline_rate
    if args.offline_cap is not None:
        FIELD["offline_cap_h"] = args.offline_cap
    build_field(P, args.garden, args.crops, args.scale)
    if args.command == "report":
        cmd_report(P)
        return 0
    if args.command == "sim":
        cmd_sim(P, args.days, args.seeds)
        return 0
    if args.command == "check":
        return cmd_check(P, args.days, args.seeds)
    if args.command == "field":
        cmd_field(P, args.days, args.seeds)
        return 0
    if args.command == "drift":
        d = drift(P)
        print("\n".join(d) if d else "no drift")
        return 1 if d else 0
    PINS.write_text(json.dumps(pin_values(P), indent=1, sort_keys=True, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"pinned {len(pin_values(P))} values to {PINS.name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
