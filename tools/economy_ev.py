"""EV — the engagement-first economy model (docs/ECONOMY.md -> "EV", docs/ROADMAP.md -> EV). Python stdlib only.

Run through `python tools/economy.py ev | proposal | evcheck` (or `python tools/economy_ev.py ...`).

What it is: an event-by-event simulation of one player per archetype (sessions, garden attention, obby runs inside a session, absences),
built on the EV rules the user decided on 2026-11-07:
  * one crop ladder from 20 s to 48 h baseline (10 s to 24 h online, OG2b), net Coins per square-hour rising per step;
  * perennials ("Future tree 1..4", model-only): fruit every f, at most c fruits held;
  * repeat obby runs pay Sunshine (growth for the whole field and the incubators) and rare seeds instead of Coins;
  * talents cost Coins + a crop bundle;
  * eggs are rolled at purchase and the rarity sets the hatch time;
  * a semi-random request board (crops, sometimes a timed run), a 7-day streak with an Epic+ pet on day 7;
  * pets: Cuteness (Coin multiplier), Tending, Scouting (XP from timer seconds), Pest-control guards;
  * a Spender archetype for the monetization headroom.
Every number in CAND is a candidate for the user's review (the proposal table); the CropConfig crops keep their ids, the rest are placeholders.
The checks G1-G12, R, B, B2, C, U read the simulation (ECONOMY.md -> "EV checks"). EV3a: CAND["mode"] "stars" (crop levels, quests, crop
points, sinks on Coins alone) or "renown" (the game as built).
"""
import ast
import bisect
import math
import random
import statistics
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import economy as E  # noqa: E402  (the config reader, stage and pet data)

H = 3600.0
DAY = 86400.0
RARITIES = ("Common", "Uncommon", "Rare", "Epic", "Legendary")

# --------------------------------------------------------------------------------------------------------------------
# The candidate (EV1). Prices are anchored to the square ladder: sq(j) = price of the j-th bought square.
# --------------------------------------------------------------------------------------------------------------------
CAND = {
    # crop ladder: (id, grow seconds); the CropConfig ids keep their names, "FP<n>" = Future plant n (model-only)
    # OG2b: doubled growth-second durations cancel the ×2 / ×1 rates; v1 halves to keep every sale / seed price unchanged.
    # FL (2026-11-21, ECONOMY.md → Findings (FL)): grow time is a choice inside a price tier (short / medium / long), the longest crop
    # 14 h; until FL the ladder rose with every crop (20 s … 48 h: Corn 1 h, Broccoli 4 h, Pumpkin 6 h, Eggplant 8 h, Blueberry 12 h,
    # Sweet potato 16 h, Giant melon 24 h, Sunflower 36 h, Pineapple 48 h).
    "ladder": [("Potato", 20), ("FP1", 60), ("FP2", 120), ("FP3", 360), ("FP4", 960), ("FP5", 1800), ("Corn", 900), ("FP6", 7200),
               ("FP7", 28800), ("Pumpkin", 43200), ("FP8", 18000), ("FP9", 1200), ("FP10", 21600), ("GiantMelon", 50400),
               ("FP11", 36000), ("FP12", 1800)],
    "v1": 1250.0,  # net Coins per square-hour of growth of the first crop (real-hour income unchanged)
    "r": 1.20,  # each next crop: x r net per square-hour
    "seed_frac": 0.25,
    # EV3 (draft 2026-11-14): "stars" = crop levels replace Renown; "renown" = the game as built until EV3b (kept for the old -> new table
    # and EV0's comparison with the configs)
    "mode": "stars",
    # crop levels (EV3a): XP = grow minutes of every harvest of that crop. Star 1 (the unlock pace) needs star1(k) = round(star_n0 x
    # star_g^k) square-harvests x its grow minutes; star L > 1 needs star1 + star_u x minutes^star_b x (L - 1)^star_p in all (a star of a long
    # crop costs less than its grow time suggests: long crops grow overnight, short ones in sessions). The next crop opens at the previous
    # one's star 1, a milestone by its quest.
    "star_n0": 12, "star_g": 1.05, "star_u": 40.0, "star_b": 0.7, "star_p": 1.5,
    # each star = one point in Value (sale x), Size (size factor x) or Speed (grow time x); up to pt_cap per line, pt_total per crop.
    # The draft's first cut (+10 % / +10 % / -6 %) made a maxed crop x3.7 per square-hour (~7 steps); the cap is 2-3 steps (check U).
    # At 3 steps (+3 % / +3 % / -3 %) the extra income bought the shop out early (G5, C, G8, B2 failed): about 2 steps
    # EV3 revision (2026-11-17): 3 levels, one point per level and per line (+11 % / +11 % / -11 %: x1.47, 2.1 steps); the draft had
    # pt_cap 5 at +2 % / +2 % / -2.5 % (15 stars per crop, steps a player does not notice).
    # EV3c revision (the user, 2026-11-17): the 3 points go into any line, up to 3 in one (pt_cap 3, pt_total 3): three in Speed = grow
    # time x 0.67 (x1.49 net per square-hour), three in Price x1.44, one each x1.47 (all 2.0-2.2 steps). The game: Mastery.Points.PerLine.
    "pt_cap": 3, "pt_value": 0.11, "pt_size": 0.11, "pt_speed": 0.11,
    "pt_total": 3,  # points (= levels) per crop; None = 3 x pt_cap (every line filled)
    # policy: a fill order of the lines, or "auto": every point in Speed for a crop that grows in a session (t <= pt_fast seconds:
    # replanted as soon as it is ripe), in Value for one that grows overnight (a faster one only waits longer for the player)
    "pt_order": "auto", "pt_fast": 3600,
    "chase": 0.5,  # policy: just enough squares of the newest crop to fill its star 1, while it earns >= chase x the best crop's rate
    # FL: a crop open for more than chase_stuck_days is planted for its bar whatever it earns (the chase floor alone left a 5 h crop
    # unplanted for 55 days by a twice-a-day player: 2-6 h crops fit neither a session nor the night). None = the floor only.
    "chase_stuck_days": 1.0,
    # EV3 revision (the user, 2026-11-17; the 2026-11-14 draft = tier_of None, mastery "time", quest_partial / req_auto False,
    # rest_per_day 0, pt_cap 5 at +2 / +2 / -2.5 %, the Giant melon quest; probe it with --set):
    # tier_of: price tiers of 2-3 crops (ladder index -> tier); a tier shares one net Coins per square-hour (v1 x r_tier^tier), its crops
    # differ in grow time, so the rotating stall (ST) can offer any of them. None = the smooth ladder (v1 x r^k).
    "tier_of": [0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 5, 5], "r_tier": 1.727,
    # tier_mult (FL): the tiers' net per square-hour as multiples of v1 (None = r_tier ** tier): tiers 0-2 as built, then x1.5 a tier
    "tier_mult": [1.0, 1.727, 1.727 ** 2, 1.727 ** 2 * 1.5, 1.727 ** 2 * 1.5 ** 2, 1.727 ** 2 * 1.5 ** 3],
    # mastery "count": a level needs plants of that crop (star 1 = round(star_n0 x star_g^k) plants, level L = star 1 x m_mult[L - 1]);
    # "time": XP = grow minutes (the draft). pt_total 3: 3 levels, a level-3 crop is fully upgraded.
    "mastery": "count", "m_mult": (1, 4, 25),
    # m_levels (count mode): the same plant counts for every crop's levels (e.g. (50, 100, 200)); the next crop then opens at the old
    # level-1 count (star_n0 x star_g^k plants of the previous crop), not at a level. None = levels from m_mult, unlock at level 1.
    "m_levels": (25, 75, 200),  # the user, 2026-11-17
    # m_bands (FL): level counts of quick crops by base grow seconds ((up to, levels), first match); the rest take m_levels. A short crop
    # stays worth planting on a flat ladder and reached 200 plants by day 2.7 (G12)
    "m_bands": ((600, (25, 225, 600)), (3600, (25, 110, 300))),
    # quest_partial: crops are handed in as they come and the progress is kept (no barn space held, no expiry)
    "quest_partial": True,
    # req_auto: requests track crops grown ("grow 6 Tomatoes"), nothing is handed in, the bonus is req_bonus x the sale of the count;
    # an unfinished request stays, only finished slots refill on the next UTC day
    "req_auto": True, "req_bonus": 0.6,
    # rested mastery: each full day away past the first adds rest_per_day "star 1s" of plants that count double (cap rest_cap)
    "rest_per_day": 0.5, "rest_cap": 3.0,
    # milestone quests (taken at once from the barn, EV2b's TakeCrops); quest_star: the quest opens only at the previous crop's star 1
    # (False: as soon as the previous crop is unlocked; the strict chain made a 3-4 h crop come days later for a 2-visit player, G2)
    "quest_star": False,
    # (about one partial field harvest: 15 Broccoli + 15 Pepper took Casual ~2.5 days and ~615 000 Coins of sales; Broccoli in the Pumpkin
    # quest kept 2 h crops on a weekly player's squares through its first session, G1)
    # (2026-11-17: the third quest moved from Giant melon to Sweet potato, the first crop of price tier 5; the draft had Giant melon:
    # 4 Sweet potato + 5 Blueberry)
    "quests": {"Corn": {"FP5": 6, "FP3": 10}, "Pumpkin": {"FP6": 5, "Corn": 8}, "FP10": {"FP9": 5, "FP8": 4}},
    # unlock rule (EV3a comparison, 2026-11-14): "price" = no unlock: every crop is in the stall from the start and its seed price paces
    # it (the genre's way; a crop counts as "opened" at its first harvest, quests off); "chain" = a crop opens at the previous one's
    # star 1 (the draft); "total" = at a total of
    # crop XP over all crops (one bar on the next locked seed: growing anything counts; a fixed Renown without the word), total_k x
    # gate^renown_p with the as-built gate ladder (crop_gate); "hybrid" = chain up to ladder index hybrid_k, total after. Milestones keep
    # their quest in every rule (opened by the rule, taken from the barn).
    # price_quests (price rule only): the milestone quests gate groups (Potato-Cucumber, Corn-Broccoli, Pumpkin-Sweet potato, Giant
    # melon-Pineapple: garden levels); inside a group the price paces
    "price_quests": False,
    # "stall" (2026-11-15, the genre's rotating shop): no unlock, every crop is sold in a stall that restocks every stall_every seconds
    # (the same stock on every server, counts per player; a missed restock is gone). The staples (ladder index < stall_staples) are always
    # in stock; crop k above them shows with chance stall_p0 x stall_pd^(k - staples), 1..round(stall_n0 x stall_nd^(k - staples)) seeds.
    # Bought seeds wait in the seed bag (non-staple seeds: at most stall_bag x open squares and one field of a kind, bundle / request
    # crops on top).
    # ST (ROADMAP → ST, 2026-11-17): the EV3 chain decides which crops exist for the player; a stall restocks every st_every seconds on a
    # UTC schedule (the same draw on every server, counts per player). Always in stock (bought on planting, like the staples): the
    # staples (ladder index < stall_staples), the next talent's bundle crops, the open quest's crops and (st_newest) the newest unlocked
    # crop. Every other unlocked crop shows with chance st_p, and at least every st_pity restocks (staggered by crop), with st_n seeds.
    # The ST candidate (2026-11-17, ECONOMY.md → Findings "ST"): hourly restocks, staples Potato-Onion (stall_staples 3), 12 seeds.
    # Without st_newest the first hour loses its news (G7 failed on every seed).
    "st": True, "st_every": 3600, "st_p": 0.5, "st_pity": 3, "st_n": 12, "st_newest": True,
    # st_long (FL): the newest unlocked crop of >= st_long seconds is always in stock too (an overnight staple; with one long crop per
    # tier, an hour whose restock had none left nothing for the night, G2). None = off.
    "st_long": 21600,
    # stall_staples: ST's staples; the 2026-11-15 probe ("stall" unlock rule) ran with 4
    "stall_every": 600, "stall_staples": 3, "stall_p0": 0.7, "stall_pd": 0.7, "stall_n0": 4.0, "stall_nd": 0.85, "stall_bag": 2.0,
    # the stall rule's trees (replace "trees"): timers from a session to a day, the overnight hook the stall's random bag cannot give
    "stall_trees": [("Tree1", 6, 3, 3600, 600, 4, 6), ("Tree2", 10, 3, 14400, 3600, 4, 8), ("Tree3", 14, 3, 43200, 10800, 4, 10),
                    ("Tree4", 18, 3, 86400, 21600, 4, 12), ("Tree5", 22, 3, 172800, 43200, 4, 14), ("Tree6", 26, 3, 172800, 43200, 4, 16)],
    "unlock": "chain", "total_k": 0.8, "hybrid_k": 5, "total_rare": True,  # total_rare: rare crops' growing time counts toward the total
    "crows_from": "FP3",  # crows and the market cart's taste start with the Garlic unlock (were Renown 3)
    # first clears of the Tutorial and World 1 (EV3 rule 6): stage key -> (finish + medal Coins, seed pack size, up to crop): the pack holds
    # seeds of the newest unlocked crop up to that one (a locked crop's seeds would skip its unlock; "the newest" alone paid a late
    # Garden main clear ~44 000 in Pumpkin seeds). Challenge coins unchanged; a stage not listed pays as built (StageConfig).
    # As built (finish + medals): Tutorial 750, Stage1-5 1 125 / 1 500 / 1 875 / 2 250 / 2 625.
    "obby_first": {"Tutorial": (250, 4, "FP3"), "Stage1": (600, 4, "FP4"), "Stage2": (800, 4, "FP4"), "Stage3": (1000, 4, "FP4"),
                   "Stage4": (1250, 4, "FP4"), "Stage5": (1500, 4, "FP4")},
    # Renown (the game as built): points per harvest = max(1, round(pts_a x minutes^pts_b)); level L needs K x L^P points; crop k needs
    # level crop_gate[k]
    "pts_a": 4.0, "pts_b": 0.5,
    "renown_k": 0.4, "renown_p": 3.0,
    "crop_gate": [0, 1, 2, 3, 4, 5, 6, 8, 11, 15, 20, 26, 33, 42, 54, 68],
    # rare crops (CropConfig ids, world, grow seconds, sale, Renown points): set by hand against the income of the days a world is reached (playtest
    # 2026-11-08: 2.5x a ladder crop of the same grow time made the first Golden carrot, day 1, worth 350 000 and 7 Renown levels; check R)
    # FL: sales halved with the flatter ladder (50 000 / 150 000 / 300 000 until FL; check R)
    "rare": [("GoldenCarrot", 1, 43200, 25000, 22), ("FrostGrape", 2, 57600, 75000, 44), ("GlowMushroom", 3, 72000, 150000, 76)],
    # squares: 32 bought, price p1 x q^(i-1), Renown gate round(sq_gate_a x i^sq_gate_b)
    "sq_p1": 290.0, "sq_q": 1.33, "sq_q2": 1.45, "sq_k2": 16, "sq_gate_a": 0.8, "sq_gate_b": 1.08,
    # sinks anchored to squares: (family, level, anchor square j, factor); price = factor x sq(j), Renown gate = the gate of square j
    "anchored": [
        ("Growth", 1, 8, 1.5), ("Growth", 2, 14, 1.5), ("Growth", 3, 20, 1.5), ("Growth", 4, 26, 1.5),
        ("Barn", 1, 6, 1.0), ("Barn", 2, 11, 1.0), ("Barn", 3, 16, 1.0), ("Barn", 4, 21, 1.0), ("Barn", 5, 26, 1.0),
        ("Sorter", 1, 12, 1.5), ("Sorter", 2, 19, 1.5), ("Sorter", 3, 27, 1.5),
        ("Cloches", 1, 9, 1.5), ("Cloches", 2, 16, 1.5), ("Cloches", 3, 24, 1.5),
        ("Shears", 1, 14, 1.5), ("Shears", 2, 21, 1.5), ("Shears", 3, 29, 1.5),
        ("FieldSlot", 2, 7, 1.5), ("FieldSlot", 3, 13, 1.5), ("FieldSlot", 4, 19, 1.5), ("FieldSlot", 5, 25, 1.5),
        ("EquipSlot", 2, 4, 1.0), ("EquipSlot", 3, 10, 1.0),
        ("Incubator", 2, 3, 1.0), ("Incubator", 3, 9, 1.0),
    ],
    # perennials (model-only): (id, anchor square j of the first sapling, saplings, first growth s, fruit every s, fruits held, ladder index of value)
    "trees": [("Tree1", 10, 3, 4 * 3600, 600, 4, 8), ("Tree2", 16, 3, 12 * 3600, 1800, 4, 10),
              ("Tree3", 22, 3, 24 * 3600, 3600, 5, 12), ("Tree4", 28, 3, 48 * 3600, 7200, 6, 14)],
    "tree_mult": 1.0,  # fruit value per square-hour against the ladder crop of its index
    "sapling_step": 1.4,  # each next sapling of a kind costs x this
    # talents: id -> list of levels (anchor square j, factor, {ladder index: count}, {rare world: count}); a world reward level is ("reward",)
    "talents": {
        "RunSpeed": [(3, 1.0, {}, {}), (5, 1.0, {4: 12}, {}), (7, 1.0, {6: 12}, {}), (9, 1.0, {7: 15}, {}), (11, 1.0, {8: 15}, {})],
        "JumpHeight": [(4, 1.0, {}, {}), (6, 1.0, {6: 12}, {}), (10, 1.0, {8: 15}, {})],
        "QuickRespawn": [(4, 1.0, {5: 12}, {}), (12, 1.0, {9: 15}, {})],
        # EV3a (the user, 2026-11-17: G4, make them easier): 20 -> 12 crops and factor 1.5 -> 1.0 (the configs follow in EV3b)
        # FL: 10 Cucumber and factor 0.8 (12 and 1.0 until FL; G4 on the flatter ladder)
        "DoubleJump": [("reward",), (12, 0.8, {6: 10}, {2: 1})],
        "Dash": [(11, 1.0, {7: 12}, {}), (14, 1.0, {8: 12}, {3: 1})],
        "WallJump": [(20, 1.5, {12: 20}, {3: 3})],
        "Glide": [(22, 1.5, {12: 25}, {3: 4})],
    },
    "talent_mult": 1.6,
    # eggs: kind -> (price anchor square j, factor, rarity weights) or (0, price, weights); hatch seconds by rarity (rolled at purchase)
    # EG (2026-11-21): Basic = Pearl, Golden = Topaz; Ruby and Diamond (were the model-only FutureEgg1 / 2) open with a crop (egg_opens) and
    # cost 2-4 h of the archetypes' median income on the day they open (check EG)
    "eggs": {"Basic": (1, 0.4, {"Common": 600, "Uncommon": 262, "Rare": 110, "Epic": 27, "Legendary": 1}),
             "Golden": (10, 1.0, {"Uncommon": 500, "Rare": 370, "Epic": 127, "Legendary": 3}),
             # EG fit (seeds 1-4): Ruby 450 000 is the lowest nice price that keeps Obby main >= 2 h (400 000: 1.9 h on seed 1);
             # Diamond 3 000 000 keeps Casual's Legendary odds at 50 % on day >= 15.8 (2 000 000: day 14.3 on seed 4)
             "Ruby": (0, 450000, {"Rare": 600, "Epic": 396, "Legendary": 4}),
             "Diamond": (0, 3000000, {"Rare": 400, "Epic": 580, "Legendary": 20})},
    "egg_opens": {"Ruby": "Pumpkin", "Diamond": "GiantMelon"},  # egg -> the crop (config id) that opens it
    "req_egg_late": "Golden", "req_egg_late_after": "Ruby",  # the request drop's free egg: Topaz once Ruby's crop is open
    "hatch": {"Common": 300, "Uncommon": 300, "Rare": 3600, "Epic": 4 * 3600, "Legendary": 4 * 3600},
    "starter_egg": {"Common": 70, "Uncommon": 30},  # the launch egg: hatches within 5 min (G7)
    "food_mult": 1.0,  # food prices x this (GardenConfig.Foods)
    # Sunshine: seconds per repeat medal finish (Bronze, Silver, Gold) x decay^n (n = earlier medal finishes of that stage today), floor, cap
    "sun": [16, 24, 32], "sun_decay": 0.8, "sun_floor": 6, "sun_cap": 3 * 3600,
    # Scouting: XP = timer seconds while equipped; level L -> L+1 in first x ratio^(L-1) hours; bonus = min(cap, per x strength) on meter,
    # pouch and Sunshine
    "scout_first_h": 0.75, "scout_ratio": 2.0, "scout_per": 0.5, "scout_cap": 0.5,
    # request board: 3 a day; slot 3 is a timed run with run_share (if a stage is cleared); crop requests pay req_mult x the sale
    # 1.0 (E5, the user 2026-11-19): no timed run and no Sunshine drop until EV2c (req_run_share 0, req_drop_sun False); the drop is a
    # rare seed or a free egg, half and half (CropConfig.Requests)
    "req_per_day": 3, "req_run_share": 0.0, "req_mult": 1.75, "req_drop": 1 / 3, "req_size": 0.3, "req_max_h": 8.0,
    "req_drop_sun": False,
    "req_sun": 20 * 60,  # Sunshine of a run request / a request drop
    # streak: days 1-6 Sunshine minutes, day 7 an Epic+ pet
    "streak_sun": [10, 10, 15, 15, 20, 30], "streak_pet": {"Epic": 95, "Legendary": 5},
    # reserved sinks (landmarks, estate, decor: not designed): a ladder from the last square's price
    "res_from": 12, "res_first_mult": 1.0, "res_ratio": 1.15, "res_count": 70,
    # crows (CropConfig.Crows as built) and guards (PetConfig.Guard as built)
    "act_s": 1.5,  # seconds of attention to harvest and replant one square
    # Tending (finding 2026-11-07: harvest-and-replant is worth ~0.1 % of income on a dense ladder): "replant" = as built; "growth" = crops in a
    # tender's reach grow faster by tend_boost x strength (online and offline)
    "tend_mode": "growth", "tend_boost": 0.5,
    # crows and guards (finding: crows eat ~3 % of income at 1 crop per absence, one guard covers 1-9 of 36 squares): crows eat at most one
    # crop per crow_per open squares per absence; a guard covers guard_reach[level band] squares
    "crow_per": 12, "guard_reach": {1: 18, 2: 18, 3: 18, 4: 30, 5: 30, 6: 30, 7: 42, 8: 42, 9: 42, 10: 42},
}

# Archetypes: E0's four + the Spender (Casual's schedule with comfort products). check = minutes between garden checks during obby time.
ARCH = [
    {"name": "Obby main", "sessions": [(7.0, 0.5), (12.5, 0.5), (18.0, 2.5)], "period": 1, "obby_min": 120, "check": 10},
    {"name": "Casual", "sessions": [(8.0, 0.25), (19.0, 0.75)], "period": 1, "obby_min": 45, "check": 10},
    {"name": "Garden main", "sessions": [(7.0, 0.5), (12.0, 0.5), (17.0, 0.5), (21.0, 0.5)], "period": 1, "obby_min": 15, "check": 5},
    {"name": "Binge", "sessions": [(10.0, 6.0)], "period": 7, "obby_min": 300, "check": 10},
    {"name": "Spender", "sessions": [(8.0, 0.25), (19.0, 0.75)], "period": 1, "obby_min": 45, "check": 10, "spender": True},
]
SPENDER = {"offline_rate": 2.0, "offline_cap_h": 48, "from_day": 1, "instant_per_day": 3}  # OG2b clock conversion preserves the old paid speed (model-only)
POLICY_BIAS = {"talent-first": {"talent": 0.5, "field": 1.0, "pets": 1.5}, "pets-first": {"talent": 1.0, "field": 1.0, "pets": 0.6}}
SHARES = {"talent-first": (0.08, 0.02), "pets-first": (0.25, 0.08)}  # (egg share, food share) of income


# --------------------------------------------------------------------------------------------------------------------
# Building the model's parameters from the configs + the candidate.
# --------------------------------------------------------------------------------------------------------------------
# "Nice" prices (the user, 2026-11-07): every Coin price is a round number a player reads at a glance. Below 10 exact; 10-30
# (times a power of ten) every integer mantissa (12, 13 ... 29: 120, 2 900, 13 000 000); 30-100 in steps of 5 (35, 40 ... 95).
# Worst-case shift 8 % (32.5 -> 30 or 35), so the model is re-checked on the rounded values, not on the raw curve.
def nice(x):
    if x < 10:
        return max(1, round(x))
    m = 10 ** (math.floor(math.log10(x)) - 1)
    a = x / m
    a = round(a) if a < 30 else 5 * round(a / 5)
    return int(a * m)


def build(c=None):
    c = dict(CAND if c is None else c)
    P = E.load()
    M = {"c": c, "P": P}
    seed = c["seed_frac"]
    crops = []
    for k, (cid, secs) in enumerate(c["ladder"]):
        if c["tier_of"] is None:
            v = c["v1"] * c["r"] ** k
        else:
            v = c["v1"] * (c["tier_mult"][c["tier_of"][k]] if c.get("tier_mult") else c["r_tier"] ** c["tier_of"][k])
        sale = max(2, nice(v * secs / H / (1 - seed)))
        sd = max(1, nice(sale * seed))
        pts = max(1, round(c["pts_a"] * (secs / 60.0) ** c["pts_b"]))
        crops.append({"k": k, "id": cid, "t": float(secs), "sale": sale, "seed": sd, "net": sale - sd, "pts": pts, "gate": c["crop_gate"][k],
                      "v": v, "rare": False, "tier": k if c["tier_of"] is None else c["tier_of"][k],
                      "star1": round(c["star_n0"] * c["star_g"] ** k) * (1.0 if c["mastery"] == "count" else secs / 60.0),
                      "quest": dict(c["quests"].get(cid, {})), "total_need": c["total_k"] * c["crop_gate"][k] ** c["renown_p"]})
    M["crops"] = crops
    M["mode"] = c["mode"]
    M["by_id"] = {cr["id"]: cr for cr in crops}
    M["levels"] = c["pt_total"] or 3 * c["pt_cap"]
    rares = {}
    for cid, world, secs, sale, pts in c["rare"]:
        rares[world] = {"k": None, "id": cid, "t": float(secs), "sale": sale, "seed": 0, "net": sale, "pts": pts,
                        "gate": 0, "v": sale * H / secs, "rare": True, "world": world}
    M["rares"] = rares
    raw = [c["sq_p1"] * c["sq_q"] ** i * c["sq_q2"] ** max(0, i + 1 - c["sq_k2"]) for i in range(32)]
    sq = [nice(x) for x in raw]
    M["sq"] = sq
    M["sq_gate"] = [round(c["sq_gate_a"] * (i + 1) ** c["sq_gate_b"]) for i in range(32)]
    def anchor(j, f):
        return nice(sq[j - 1] * f)
    M["anchor"] = anchor
    items = []
    for fam, lvl, j, f in c["anchored"]:
        group = "pets" if fam in ("FieldSlot", "EquipSlot", "Incubator") else "field"
        items.append({"name": f"{fam} {lvl}", "fam": fam, "lvl": lvl, "price": anchor(j, f), "gate": M["sq_gate"][j - 1], "group": group})
    for i in range(32):
        items.append({"name": f"Square {5 + i}", "fam": "Square", "lvl": i + 1, "price": sq[i], "gate": M["sq_gate"][i], "group": "field"})
    trees = []
    for tid, j, n, t0, f, cap, at in (c["stall_trees"] if c["mode"] == "stars" and c["unlock"] == "stall" else c["trees"]):
        # the ladder crop it points at (FL: its tier's rate; the smooth x r ladder before tier_mult)
        v = c["tree_mult"] * (crops[at - 1]["v"] if c.get("tier_mult") else c["v1"] * c["r"] ** (at - 1))
        fruit = round(v * f / H)
        trees.append({"id": tid, "t0": float(t0), "f": float(f), "cap": cap, "fruit": fruit, "pts": crops[at - 1]["pts"]})
        for s in range(n):
            items.append({"name": f"{tid} sapling {s + 1}", "fam": "Sapling", "tree": tid, "lvl": s + 1,
                          "price": anchor(j, c["sapling_step"] ** s), "gate": M["sq_gate"][j - 1], "group": "field"})
    M["trees"] = {t["id"]: t for t in trees}
    talents = {}
    for tid, levels in c["talents"].items():
        lv = []
        for n, spec in enumerate(levels):
            if spec[0] == "reward":
                lv.append(None)
                continue
            j, f, bundle, rare = spec
            price = anchor(j, f * c["talent_mult"])
            lv.append({"price": price, "crops": dict(bundle), "rare": dict(rare)})
            items.append({"name": f"{tid} {n + 1}", "fam": "Talent", "tid": tid, "lvl": n + 1, "price": price, "gate": 0, "group": "talent",
                          "crops": dict(bundle), "rare_need": dict(rare)})
        talents[tid] = lv
    M["talents"] = talents
    res0 = sq[c["res_from"] - 1] * c["res_first_mult"]
    for k in range(c["res_count"]):
        items.append({"name": f"Reserved {k + 1}", "fam": "Reserved", "lvl": k + 1, "price": nice(res0 * c["res_ratio"] ** k),
                      "gate": 0, "group": "reserved"})
    M["items"] = items
    M["eggs"] = {k: {"price": anchor(j, f) if j else nice(f), "w": w} for k, (j, f, w) in c["eggs"].items()}
    ladder_k = {cfg_id(cr["id"]): cr["k"] for cr in crops}
    M["egg_opens"] = {egg: ladder_k[crop] for egg, crop in c["egg_opens"].items()}
    M["foods"] = [{"id": f["id"], "price": nice(f["price"] * c["food_mult"]), "xp": f["xp"]} for f in P["foods"]]
    cc = P["crop_cfg"]
    M["upg_step"] = {u[0]: u[1] for u in cc["upgrades"]}  # Growth 0.05, Barn 20
    M["tool_effect"] = {t[0]: t[1] for t in cc["tools"]}
    M["barn"] = cc["barn_capacity"]
    M["rates"] = cc["rates"]  # online, offline, cap h
    M["work_rates"] = cc["work_rates"]  # OG2: field-job XP is independent of crop speed
    share, chance, cap, block_h, _ = cc["crows"]  # the config's crow start is a crop (EV3b, `crows_from`); the Renown model keeps its level
    M["crows"] = [share, chance, cap, block_h, c["crop_gate"][M["by_id"][c["crows_from"]]["k"]]]  # share, chance, cap, block h, from level
    M["apt"] = {"cap": cc["apt_caps"], "str": cc["apt_strength"], "first": cc["apt_xp"][0], "ratio": cc["apt_xp"][1], "tending": cc["tending"]}
    M["obby_seeds"] = cc["obby_seeds"]  # first Gold world, per first Gold, daily, meter size, pts, first mult, pouch
    M["stages"] = [s for s in sorted(P["stages"], key=lambda s: s["order"]) if s["built"]]
    return M


def renown_level(M, pts):
    c = M["c"]
    return int((max(pts, 0.0) / c["renown_k"]) ** (1 / c["renown_p"]) + 1e-9)


def m_levels_of(crop, c):
    """The plant counts of `crop`'s levels: its grow-time band (FL `m_bands`), else `m_levels`."""
    for up_to, levels in c.get("m_bands") or ():
        if crop["t"] <= up_to:
            return levels
    return c["m_levels"]


def star_need(crop, L, c):
    """XP a crop needs in all for star L. "time": grow minutes, star1 (the unlock pace), then star_u x minutes^star_b x (L - 1)^star_p;
    "count": plants, star1 x m_mult[L - 1]."""
    if c["mastery"] == "count":
        return m_levels_of(crop, c)[L - 1] if c["m_levels"] else crop["star1"] * c["m_mult"][L - 1]
    if L <= 1:
        return crop["star1"] * L
    return crop["star1"] + c["star_u"] * (crop["t"] / 60.0) ** c["star_b"] * (L - 1) ** c["star_p"]


def pt_mults(pts, c):
    """(sale multiplier, grow-time multiplier) of a crop's points {"Value", "Size", "Speed"}."""
    return (1 + c["pt_value"] * pts["Value"]) * (1 + c["pt_size"] * pts["Size"]), 1 - c["pt_speed"] * pts["Speed"]


def pt_allocations(c):
    """Every way to spend a crop's points (pt_total or 3 x pt_cap, at most pt_cap per line), as {"Value", "Size", "Speed"} dicts."""
    total, cap = c["pt_total"] or 3 * c["pt_cap"], c["pt_cap"]
    return [{"Value": v, "Size": z, "Speed": total - v - z} for v in range(cap + 1) for z in range(cap + 1)
            if 0 <= total - v - z <= cap]


def maxed_mult(c, seed_frac=None, pts=None):
    """Net Coins per square-hour of a maxed crop against the same crop fresh (seed price unchanged): with the points `pts`, or the best
    way to spend them (pt_allocations)."""
    s = c["seed_frac"] if seed_frac is None else seed_frac

    def mult(p):
        a, g = pt_mults(p, c)
        return (a - s) / (1 - s) / g

    return mult(pts) if pts else max(mult(p) for p in pt_allocations(c))


def pt_line(crop, c, pts):
    """The line the policy puts crop `crop`'s next point in (pts: its points so far), None when every line is full."""
    order = c["pt_order"]
    if order == "auto":
        first = "Speed" if crop["t"] <= c["pt_fast"] else "Value"
        order = (first, "Value" if first == "Speed" else "Speed", "Size")
    return next((line for line in order if pts[line] < c["pt_cap"]), None)


def unlock_need(crop, c):
    """XP of a crop that opens the next one: its level 1, or (m_levels) the old level-1 count."""
    return crop["star1"] if c["mastery"] == "count" and c["m_levels"] else star_need(crop, 1, c)


def xp_unit(crop, c):
    """XP of one plant of `crop`: 1 ("count") or its grow minutes ("time")."""
    return 1.0 if c["mastery"] == "count" else crop["t"] / 60.0


def first_clear_coins(M, s):
    """Finish + medal Coins of a stage's first clear and its seed pack (EV3 rule 6 in stars mode; as built otherwise)."""
    P = M["P"]
    o = M["c"]["obby_first"].get(s["key"]) if M["mode"] == "stars" else None
    if o is None:
        return E.first_finish(P, s) + E.stage_medal_total(P, s), 0, None
    return o[0], o[1], o[2]


# --------------------------------------------------------------------------------------------------------------------
# One player.
# --------------------------------------------------------------------------------------------------------------------
class Sim:
    def __init__(self, M, arch, policy="talent-first", days=60, tending=True, guards=True, seed=1, free=False, guard_first=False, crows=True):
        self.guard_first = guard_first
        self.crows_on = crows
        self.now = 0.0
        self.M, self.c, self.P, self.arch, self.policy, self.days = M, M["c"], M["P"], arch, policy, days
        self.rng = random.Random(seed * 7919 + len(arch["name"]))
        self.prng = random.Random(seed * 104729 + 3)  # pets
        self.seed = seed
        self.qrng = random.Random(seed * 15485863 + 5)  # requests (re-seeded every day)
        self.pouch = {}  # crop id -> free seeds from the seed pouch
        self.tending_on, self.guards_on = tending, guards
        self.spender = bool(arch.get("spender")) and not free
        on, off, cap_h = M["rates"]
        if self.spender:
            off, cap_h = SPENDER["offline_rate"], SPENDER["offline_cap_h"]
        self.base_on, self.base_off, self.cap = on, off, cap_h * H
        self.egg_share, self.food_share = SHARES[policy]
        bias = POLICY_BIAS[policy]
        items = [dict(it) for it in M["items"]]
        bias = dict(bias, reserved=bias["field"])  # the placeholder landmarks / estate are bought in price order with the field items
        self.queue = sorted(items, key=lambda it: it["price"] * bias[it["group"]])
        self.bought = set()
        self.buy_day = {}
        self.build_sessions()
        # state
        self.coins = 0.0
        self.egg_fund = self.food_fund = 0.0
        self.pts = 0.0
        self.level = 0
        self.stars_on = M["mode"] == "stars"
        self.price_rule = M["mode"] == "stars" and M["c"]["unlock"] in ("price", "stall")
        self.stall_on = (self.price_rule and M["c"]["unlock"] == "stall") or (self.stars_on and M["c"]["st"])
        self.st = self.stars_on and M["c"]["st"] and not self.price_rule
        self.bag = {}  # stall: ladder index -> seeds bought, not planted yet
        self.stall_slot, self.stall_left = -1, {}
        self.first_seed_t = {}  # stall: ladder index -> first purchase of its seeds (news, G7)
        self.st_seen = []  # ST: (t, unlocked non-staple crops in stock) per restock the player saw
        self.unl = {0}  # ladder indexes the player may plant
        if self.price_rule:
            self.unl = set(self.group_from(0))
        self.xp = {cr["k"]: 0.0 for cr in M["crops"]}
        self.xp_total = 0.0  # crop XP over all crops (the "total" unlock rule)
        self.star = {cr["k"]: 0 for cr in M["crops"]}
        self.cpts = {cr["k"]: {"Value": 0, "Size": 0, "Speed": 0} for cr in M["crops"]}
        self.star_t = []  # (t, ladder index, star)
        self.quest_t = {}  # ladder index -> time its quest was done
        self.qgot = {}  # quest_partial: crop id -> crops already handed in to the open quest
        self.rest = 0.0  # rested mastery left, in "star 1s" of plants
        self.star_newest = []  # (t, ladder index of the star's crop, newest unlocked index then): the revised G11
        self.harv = {}  # day -> [square-harvests, of crops >= 3 steps below the newest unlocked]
        self.clear_log = []  # (t, stage key, Coins + seed pack value, the farm's online Coins per minute)
        self.lvl = {"Growth": 0, "Barn": 0, "Sorter": 0, "Cloches": 0, "Shears": 0, "FieldSlot": 1, "EquipSlot": 1, "Incubator": 1, "Square": 0}
        self.open_sq = 4
        self.batches = []  # {"crop", "n", "need", "grown", "at", "ready"}
        self.free_sq = 4
        self.start_seeds = 4
        self.trees = []  # {"id", "grown", "at", "fruits", "bearing"}
        self.kept = {}  # crop id -> crops kept in the barn (bundles, requests)
        self.rare_seeds = {}
        self.pets = []
        self.incs = []  # [{"r", "left"(s), "at"}]
        self.talent = {t: 0 for t in M["talents"]}
        self.talent["DoubleJump"] = 0
        self.sun = 0.0
        self.sun_day = 0.0
        self.mult = 1.0
        self.cleared = []
        self.learn = None  # [stage, runs left]
        self.reach_day = {}  # stage key -> day it became the next stage
        self.blocked_since = {}
        self.runs_today = {}
        self.first_today = set()
        self.daily_seed_day = -1
        self.meter = {}
        self.requests = []
        self.req_day = -1
        self.board_day = -1  # the day the request board was last filled
        self.req_done_t = []  # times requests were finished (news, G7)
        self.streak = 0
        self.streak_last = -1
        self.last_crop = M["crops"][0]
        # stats
        self.events = []  # online times of collect moments
        self.online_by_day = [0.0] * (days + 8)
        self.events_by_day = [0] * (days + 8)
        self.income = {"field": 0.0, "rare": 0.0, "obby": 0.0, "request": 0.0, "pets": 0.0}  # "rare": sales of rare crops (their seeds come from the obby)
        self.rare_by_day = [0.0] * (days + 2)
        self.rare_sales = []  # (t, Coins of one sale, the Coins earned before it)
        self.earned_total = 0.0
        self.after3 = self.obby_after3 = 0.0
        self.free_eggs = []  # egg kinds waiting for an incubator (request drops)
        self.egg_bought = {}  # egg kind -> eggs bought
        self.income_log = []  # (time, coins)
        self.spent = 0.0
        self.spent_by_day = [0.0] * (days + 8)
        self.earned_by_day = [0.0] * (days + 8)
        self.sun_by_day = [0.0] * (days + 8)
        self.obby_h_by_day = [0.0] * (days + 8)
        self.unlock_t = {0: 0.0}
        self.level_t = []  # times of Renown level-ups
        self.hooks = []  # (day, has hook)
        self.goal = []  # (day, hours to afford, affordable count)
        self.first = {}  # milestone -> time
        self.crow_loss = 0.0
        self.tend_extra = 0.0
        self.legendary_t = None
        self.leg_exp, self.leg_half = 0.0, None
        self.first_harvest_t = None
        self.first_crop_t = {}
        self.first_hatch_t = None
        self.hatch_t = []
        self.starter_egg = True
        self.rates()

    # ---- schedule ----------------------------------------------------------------------------------------------
    def build_sessions(self):
        a = self.arch
        S = []
        total_h = sum(l for _, l in a["sessions"])
        for d in range(self.days):
            if d % a["period"]:
                continue
            for st, ln in a["sessions"]:
                s = d * DAY + st * H
                e = s + ln * H
                ob = a["obby_min"] * 60.0 * ln / total_h
                os_ = s + (ln * H - ob) / 2
                S.append((s, e, os_, os_ + ob))
        self.S = S
        self.starts = [x[0] for x in S]
        self.ends = [x[1] for x in S]

    def idx(self, t):
        return bisect.bisect_right(self.starts, t) - 1

    def growth(self, a, b, on=None, off=None):
        on = self.g_on if on is None else on
        off = self.g_off if off is None else off
        if b <= a:
            return 0.0
        g, t = 0.0, a
        i = self.idx(t)
        n = len(self.S)
        while t < b:
            if i >= 0 and t < self.ends[i]:
                e = min(b, self.ends[i])
                g += (e - t) * on
                t = e
            else:
                prev = self.ends[i] if i >= 0 else -math.inf
                nxt = self.starts[i + 1] if i + 1 < n else math.inf
                e = min(b, nxt)
                oe = min(e, prev + self.cap)
                if oe > t:
                    g += (oe - t) * off
                t = e
                if t >= nxt:
                    i += 1
        return g

    def ready_at(self, a, need):
        if need <= 0:
            return a
        t, i, n = a, self.idx(a), len(self.S)
        while True:
            if i >= 0 and t < self.ends[i]:
                room = (self.ends[i] - t) * self.g_on
                if room >= need:
                    return t + need / self.g_on
                need -= room
                t = self.ends[i]
            else:
                prev = self.ends[i] if i >= 0 else -math.inf
                nxt = self.starts[i + 1] if i + 1 < n else math.inf
                oe = min(nxt, prev + self.cap)
                if oe > t and self.g_off > 0:
                    room = (oe - t) * self.g_off
                    if room >= need:
                        return t + need / self.g_off
                    need -= room
                if nxt == math.inf:
                    return math.inf
                t = nxt
                i += 1

    def attention_after(self, t):
        i = self.idx(t)
        if i >= 0 and t < self.ends[i]:
            s, e, os_, oe = self.S[i]
            if os_ <= t < oe:
                step = self.arch["check"] * 60.0
                k = math.ceil((t - os_) / step - 1e-9)
                return min(os_ + k * step, oe)
            return t
        return self.starts[i + 1] if i + 1 < len(self.S) else math.inf

    def rates(self):
        """Growth rates from the upgrades (call after an upgrade: batches keep the growth earned so far)."""
        speed = 1 / (1 - self.M["upg_step"]["Growth"] * self.lvl["Growth"])
        cl = self.M["tool_effect"]["Cloches"][self.lvl["Cloches"] - 1] if self.lvl["Cloches"] else 0.0
        tend = 1.0
        if self.c["tend_mode"] == "growth" and self.tending_on and self.pets:
            n, st, _, _ = self.coverage()
            tend = 1 + self.c["tend_boost"] * st * n / max(1, self.open_sq)
        self.g_on, self.g_off = self.base_on * speed * (1 + cl) * tend, self.base_off * speed * tend

    def settle(self, t):
        for b in self.batches:
            b["grown"] += self.growth(b["at"], t)
            b["at"] = t
        for tr in self.trees:
            if t > tr["at"]:
                tr["grown"] += self.growth(tr["at"], t)
                tr["at"] = t

    def refresh_ready(self, t):
        for b in self.batches:
            b["ready"] = self.ready_at(t, b["need"] - b["grown"])

    # ---- economy helpers ---------------------------------------------------------------------------------------
    def day(self, t):
        return int(t // DAY)

    def earn(self, t, coins, kind):
        coins *= self.mult if kind != "pets" else 1.0
        self.income[kind] += coins
        if kind == "rare":
            self.rare_by_day[min(self.day(t), len(self.rare_by_day) - 1)] += coins
            self.rare_sales.append((t, coins, self.earned_total))
        self.earned_total += coins
        if t >= 3 * DAY:
            self.after3 += coins
            if kind in ("obby", "rare"):  # the obby is where rare seeds come from: G6 counts what they pay as obby income
                self.obby_after3 += coins
        self.earned_by_day[self.day(t)] += coins
        self.income_log.append((t, coins))
        eg, fd = (self.egg_share, self.food_share) if kind != "obby" or self.day(t) > 0 else (0.0, 0.0)
        self.egg_fund += coins * eg
        self.food_fund += coins * fd
        self.coins += coins * (1 - eg - fd)

    def spend(self, t, coins):
        self.coins -= coins
        self.spent += coins
        self.spent_by_day[self.day(t)] += coins

    def barn_cap(self):
        return self.M["barn"] + self.M["upg_step"]["Barn"] * self.lvl["Barn"]

    def sale_mult(self):
        te = self.M["tool_effect"]
        s = te["Sorter"][self.lvl["Sorter"] - 1] if self.lvl["Sorter"] else 0.0
        sh = te["Shears"][self.lvl["Shears"] - 1] if self.lvl["Shears"] else 0.0
        return (1 + s) * (1 + sh)

    def unlocked(self):
        return [c for c in self.M["crops"] if c["k"] in self.unl]

    def group_from(self, k):
        """Ladder indexes from k up to the next milestone (price rule with quests), or to the top."""
        out, crops = [k], self.M["crops"]
        while out[-1] + 1 < len(crops) and not (self.c["price_quests"] and crops[out[-1] + 1]["quest"]):
            out.append(out[-1] + 1)
        return out

    def newest(self):
        """Ladder index of the newest crop the player has (price rule: the newest one harvested)."""
        return max(self.unlock_t) if self.price_rule else max(self.unl)

    def known(self):
        """Crops the player knows: unlocked ones, or (price rule) ones harvested at least once."""
        if self.price_rule:
            return [c for c in self.M["crops"] if c["k"] in self.unlock_t]
        return self.unlocked()

    def unlock(self, t, k):
        if self.price_rule:  # a milestone opens its group; "opened" stays the first harvest
            self.unl |= set(self.group_from(k))
            return
        if k not in self.unl:
            self.unl.add(k)
            self.unlock_t.setdefault(k, t)

    def add_points(self, t, pts):
        """Renown (the game as built): in "renown" mode its levels unlock crops; in "stars" mode it is only counted."""
        self.pts += pts
        lv = renown_level(self.M, self.pts)
        while self.level < lv:
            self.level += 1
            self.level_t.append(t)
            if not self.stars_on:
                for c in self.M["crops"]:
                    if c["gate"] == self.level:
                        self.unlock(t, c["k"])

    # ---- crop levels (EV3) -------------------------------------------------------------------------------------
    def add_xp(self, t, crop, n):
        """A harvest of n squares: XP = grow minutes; a star gives a point (Value first); star 1 opens the next crop unless it is a
        milestone (a quest)."""
        if not self.stars_on or n <= 0:
            return
        if crop["rare"]:  # no level of its own; its growing time counts toward the total when total_rare is on
            if self.c["total_rare"]:
                self.xp_total += n * crop["t"] / 60.0
                self.total_unlocks(t)
            return
        k = crop["k"]
        bonus = 0.0
        if self.rest > 0 and self.star[k] < self.M["levels"]:  # rested: plants count double while the pool lasts
            bonus = min(n, self.rest * crop["star1"] / xp_unit(crop, self.c))
            self.rest -= bonus * xp_unit(crop, self.c) / crop["star1"]
        self.xp[k] += (n + bonus) * xp_unit(crop, self.c)
        self.xp_total += n * crop["t"] / 60.0
        self.total_unlocks(t)
        while self.star[k] < self.M["levels"] and self.xp[k] >= star_need(crop, self.star[k] + 1, self.c) - 1e-9:
            self.star[k] += 1
            self.star_t.append((t, k, self.star[k]))
            self.star_newest.append((t, k, self.newest()))
            line = pt_line(crop, self.c, self.cpts[k])
            if line:
                self.cpts[k][line] += 1
        nxt = k + 1
        if (nxt not in self.unl and self.xp[k] >= unlock_need(crop, self.c) - 1e-9 and nxt < len(self.M["crops"])
                and not self.M["crops"][nxt]["quest"] and self.chain_rule(nxt)):
            self.unlock(t, nxt)

    def chain_rule(self, k):
        """Does crop k open at the previous crop's star 1 (else at a crop XP total)?"""
        u = self.c["unlock"]
        if u in ("price", "stall"):
            return False
        return u == "chain" or (u == "hybrid" and k <= self.c["hybrid_k"])

    def total_unlocks(self, t):
        """The "total" rule: the next crops open in ladder order while the crop XP total reaches theirs (a milestone waits for its quest)."""
        while True:
            k = max(self.unl) + 1
            if k >= len(self.M["crops"]) or self.chain_rule(k):
                return
            crop = self.M["crops"][k]
            if crop["quest"] or self.xp_total < crop["total_need"]:
                return
            self.unlock(t, k)

    def open_quest(self):
        """The milestone crop whose quest is open (the next crop to unlock; with quest_star the previous crop needs star 1), or None."""
        if not self.stars_on:
            return None
        k = max(self.unl) + 1
        if k >= len(self.M["crops"]):
            return None
        crop = self.M["crops"][k]
        if not crop["quest"]:
            return None
        if self.price_rule:
            return crop  # open as soon as the group below is open
        if not self.chain_rule(k):
            return crop if self.xp_total >= crop["total_need"] else None
        return crop if not self.c["quest_star"] or self.star[k - 1] >= 1 else None

    def try_quest(self, t):
        crop = self.open_quest()
        if crop is None:
            return False
        if self.c["quest_partial"]:  # hand in what the barn holds beyond the next talent's bundle, keep the progress
            nt = self.next_talent()
            hold = {self.M["crops"][k - 1]["id"]: m for k, m in nt["crops"].items()} if nt else {}
            for cid, n in crop["quest"].items():
                give = min(self.kept.get(cid, 0) - hold.get(cid, 0), n - self.qgot.get(cid, 0))
                if give > 0:
                    self.kept[cid] -= give
                    self.qgot[cid] = self.qgot.get(cid, 0) + give
            if any(self.qgot.get(cid, 0) < n for cid, n in crop["quest"].items()):
                return False
            self.qgot = {}
        elif any(self.kept.get(cid, 0) < n for cid, n in crop["quest"].items()):
            return False
        else:
            for cid, n in crop["quest"].items():
                self.kept[cid] -= n
        self.quest_t[crop["k"]] = t
        self.unlock(t, crop["k"])
        return True

    def sale_of(self, crop):
        """A crop's sale with its Value and Size points (rare crops have none)."""
        if not self.stars_on or crop["rare"]:
            return crop["sale"]
        return crop["sale"] * pt_mults(self.cpts[crop["k"]], self.c)[0]

    def grow_of(self, crop):
        if not self.stars_on or crop["rare"]:
            return crop["t"]
        return crop["t"] * pt_mults(self.cpts[crop["k"]], self.c)[1]

    def farm_rate(self):
        """The farm's online Coins per minute now: every open square on the best unlocked crop, harvested the moment it ripens."""
        best = max((self.sale_of(c) - c["seed"]) * self.sale_mult() / self.grow_of(c) for c in self.unlocked())
        return best * self.open_sq * self.g_on * self.mult * 60.0

    def wanted(self):
        """Crops the player keeps instead of selling: the next talent's bundle and open crop requests -> {crop id: count}."""
        want = {}
        nxt = self.next_talent()
        if nxt:
            for k, n in nxt["crops"].items():
                cid = self.M["crops"][k - 1]["id"]
                want[cid] = want.get(cid, 0) + n
        # rare crops are scarce: kept for the next level of every talent, not only the next talent (EV3a: a later crop unlock left
        # Quick Respawn 2 first in the queue and the Frost grapes Double Jump 2 needs were sold)
        rare = {}
        for it in self.queue:
            if it["fam"] == "Talent" and it["name"] not in self.bought and self.talent[it["tid"]] == it["lvl"] - 1:
                for w, n in it["rare_need"].items():
                    cid = self.M["rares"][w]["id"]
                    rare[cid] = max(rare.get(cid, 0), n)
        for cid, n in rare.items():
            want[cid] = want.get(cid, 0) + n
        q = self.open_quest()
        if q:
            for cid, n in q["quest"].items():
                left = n - self.qgot.get(cid, 0)
                if left > 0:
                    want[cid] = want.get(cid, 0) + left
        for rq in self.requests:
            if rq["type"] == "crop" and not rq["done"] and not self.c["req_auto"]:
                want[rq["crop"]["id"]] = want.get(rq["crop"]["id"], 0) + rq["q"]
        return want

    def next_talent(self):
        for it in self.queue:
            if it["fam"] == "Talent" and it["name"] not in self.bought and self.talent[it["tid"]] == it["lvl"] - 1:
                if self.policy == "talent-first" or self.required_block():
                    return it
                return it if it["price"] <= max(self.coins, 1) * 3 else None
        return None

    def required_block(self):
        return bool(self.blocked_since)

    # ---- harvesting and planting -------------------------------------------------------------------------------
    def harvest(self, t, crop, n, online=True):
        want = self.wanted()
        keep = 0
        have = self.kept.get(crop["id"], 0)
        room = max(0, self.barn_cap() - sum(self.kept.values()))
        if want.get(crop["id"], 0) > have:
            keep = min(n, want[crop["id"]] - have, room)
        if keep:
            self.kept[crop["id"]] = have + keep
        sell = n - keep
        if sell:
            self.earn(t, sell * self.sale_of(crop) * self.sale_mult(), "rare" if crop["rare"] else "field")
        self.add_points(t, crop["pts"] * n)
        self.add_xp(t, crop, n)
        if not crop["rare"]:
            if self.price_rule:
                self.unlock_t.setdefault(crop["k"], t)  # price rule: a crop is "opened" by its first harvest
            h = self.harv.setdefault(self.day(t), [0, 0])
            h[0] += n
            if crop["k"] <= self.newest() - 3:
                h[1] += n
        if self.first_harvest_t is None:
            self.first_harvest_t = t
        self.first_crop_t.setdefault(crop["id"], t)  # the first harvest of a crop kind is news too (G7)
        if self.c["req_auto"]:
            self.track_requests(t, crop, n)
        else:
            self.check_requests(t)

    def rate(self, t, crop, n, bonus=True):
        """Coins per wall-clock second of a square planted with `crop` at t until the player can harvest it."""
        plant = t + n * self.c["act_s"]
        ready = self.ready_at(plant, self.grow_of(crop))
        h = self.attention_after(ready) if ready < math.inf else math.inf
        if h == math.inf:
            return -1.0
        gain = (self.sale_of(crop) - crop["seed"]) * self.sale_mult() * self.mult
        if bonus and self.c["req_auto"] and self.req_left(crop["id"]) > 0:
            gain += self.sale_of(crop) * self.c["req_bonus"] * self.mult  # a tracked request pays its bonus on top of the sale
        elif bonus and self.wanted().get(crop["id"], 0) > self.kept.get(crop["id"], 0):
            gain += self.sale_of(crop) * (self.c["req_mult"] - 1) * self.mult  # a request crop pays the premium
        return gain / max(1.0, h - t)

    def choose(self, t, n, bonus=False):
        """The crop for n free squares at time t: the best net per wall-clock second until the player can harvest it."""
        best, best_rate = None, -1.0
        for crop in self.unlocked():
            cost = crop["seed"] * n
            if cost > self.coins and not (crop["k"] == 0 and self.start_seeds >= n):
                continue
            r = self.rate(t, crop, n, bonus)
            if r > best_rate:
                best, best_rate = crop, r
        return best

    def chase_bar(self, t):
        """The unlock bar (EV3): just enough squares of the newest crop to fill its star 1 with one harvest (counting what grows), while
        it earns at least `chase` x the best crop's rate. A maxed crop matches a fresh one 2-3 steps up, so a pure rate player would never
        grow the newest crop and nothing would open."""
        if not self.stars_on or self.free_sq <= 0 or not self.chain_rule(max(self.unl) + 1):
            return
        new = self.M["crops"][max(self.unl)]
        if self.xp[new["k"]] >= unlock_need(new, self.c) - 1e-9:
            return
        growing = sum(b["n"] for b in self.batches if b["crop"] is new)
        u = xp_unit(new, self.c)
        short = unlock_need(new, self.c) - self.xp[new["k"]] - growing * u
        a = self.avail(new)
        n = min(self.free_sq, math.ceil(short / u - 1e-9), a if a < math.inf else int(self.coins // max(1, new["seed"])))
        if n <= 0:
            return
        best = self.choose(t, n)
        stuck = self.c.get("chase_stuck_days") is not None and t - self.unlock_t.get(new["k"], t) > self.c["chase_stuck_days"] * DAY
        if not stuck and best is not new and best is not None and self.rate(t, new, n) < self.c["chase"] * self.rate(t, best, n):
            return
        self.take_seeds(t, new, n)
        at = t + n * self.c["act_s"]
        g = self.grow_of(new)
        self.batches.append({"crop": new, "n": n, "need": g, "grown": 0.0, "at": at, "ready": self.ready_at(at, g)})
        self.free_sq -= n

    def stall_stock(self, slot):
        """The stall's stock in restock slot `slot`: {ladder index: seeds} of the non-staple crops (staples are always there)."""
        c, rng = self.c, random.Random(self.seed * 1299709 + slot * 7919 + 11)
        out = {}
        if self.st:  # ST: every non-staple crop with chance st_p, at least every st_pity slots (staggered); the player sees the unlocked
            for crop in self.M["crops"][c["stall_staples"]:]:
                if rng.random() < c["st_p"] or (slot + crop["k"]) % max(1, c["st_pity"]) == 0:
                    out[crop["k"]] = c["st_n"]
            return out
        for crop in self.M["crops"][c["stall_staples"]:]:
            j = crop["k"] - c["stall_staples"]
            if rng.random() < c["stall_p0"] * c["stall_pd"] ** j:
                out[crop["k"]] = 1 + rng.randrange(max(1, round(c["stall_n0"] * c["stall_nd"] ** j)))
        return out

    def st_always(self, crop):
        """ST: is `crop` always in stock for this player now (a talent-bundle or open-quest crop, or the newest unlocked one)?"""
        if not self.st:
            return False
        k = crop["k"]
        if self.c["st_newest"] and k == max(self.unl):
            return True
        if self.c.get("st_long") and crop["t"] >= self.c["st_long"] and k == max(
                (u for u in self.unl if self.M["crops"][u]["t"] >= self.c["st_long"]), default=-1):
            return True
        nt = self.next_talent()
        if nt and k + 1 in nt["crops"]:
            return True
        q = self.open_quest()
        return bool(q) and crop["id"] in q["quest"]

    def avail(self, crop):
        """Seeds of `crop` the player can plant now without the Coins check (math.inf = a staple, bought on planting)."""
        if not self.stall_on or crop["k"] < self.c["stall_staples"] or self.st_always(crop):
            return math.inf
        return self.bag.get(crop["k"], 0) + self.pouch.get(crop["id"], 0)

    def take_seeds(self, t, crop, n):
        """Pay for n seeds of `crop` at planting: pouch first, then (stall) the bag, else Coins."""
        free = min(n, self.pouch.get(crop["id"], 0))
        if free:
            self.pouch[crop["id"]] -= free
        n -= free
        if self.stall_on and crop["k"] >= self.c["stall_staples"] and not self.st_always(crop):
            self.bag[crop["k"]] = self.bag.get(crop["k"], 0) - n
            return
        self.spend(t, crop["seed"] * n)

    def visit_stall(self, t):
        """Stall rule: buy the current restock, rarest first, into the seed bag (keeping a staple replant)."""
        if not self.stall_on:
            return
        slot = int(t // (self.c["st_every"] if self.st else self.c["stall_every"]))
        if slot != self.stall_slot:
            self.stall_slot, self.stall_left = slot, self.stall_stock(slot)
            if self.st:
                self.st_seen.append((t, sorted(k for k in self.stall_left if k in self.unl)))
        want = self.wanted()
        keep = self.reserve() if self.st else self.M["crops"][self.c["stall_staples"] - 1]["seed"] * self.open_sq
        cap = self.c["stall_bag"] * self.open_sq
        for k in sorted(self.stall_left, reverse=True):
            crop = self.M["crops"][k]
            if self.st and (k not in self.unl or self.st_always(crop)):
                continue  # ST: a locked crop is not shown; an always-stocked one is bought on planting
            left = self.stall_left[k]
            extra = max(0, want.get(crop["id"], 0) - self.kept.get(crop["id"], 0) - self.bag.get(k, 0))
            room = min(max(0, cap - sum(self.bag.values())), max(0, self.open_sq - self.bag.get(k, 0))) + extra  # one field of a kind
            n = min(left, room, int(max(0.0, self.coins - keep) // max(1, crop["seed"])))
            if n <= 0:
                continue
            self.spend(t, crop["seed"] * n)
            self.bag[k] = self.bag.get(k, 0) + n
            self.stall_left[k] -= n
            self.first_seed_t.setdefault(k, t)

    def stall_plant(self, t):
        """Stall rule: fill the free squares crop by crop, the best net per wall-clock second among the seeds at hand."""
        while self.free_sq > 0:
            best, best_r, best_n = None, -1.0, 0
            for crop in self.unlocked():
                a = self.avail(crop)
                n = min(self.free_sq, a if a < math.inf else int(self.coins // max(1, crop["seed"])))
                if n <= 0 and not (crop["k"] == 0 and self.start_seeds > 0):
                    continue
                if crop["k"] == 0 and self.start_seeds > 0:
                    n = min(self.free_sq, max(n, self.start_seeds))
                r = self.rate(t, crop, n) + (crop["seed"] * self.mult / max(1.0, self.grow_of(crop)) if a < math.inf else 0.0)
                if r > best_r:
                    best, best_r, best_n = crop, r, n
            if best is None:
                return
            crop, n = best, best_n
            if crop["k"] == 0 and self.start_seeds > 0:
                s0 = min(n, self.start_seeds)
                self.start_seeds -= s0
                self.spend(t, crop["seed"] * (n - s0))
            else:
                self.take_seeds(t, crop, n)
            at = t + n * self.c["act_s"]
            g = self.grow_of(crop)
            self.batches.append({"crop": crop, "n": n, "need": g, "grown": 0.0, "at": at, "ready": self.ready_at(at, g)})
            self.free_sq -= n
            self.last_crop = crop

    def plant(self, t):
        # rare seeds first (the best value on a square, kept apart from the ladder)
        for w in sorted(self.rare_seeds):
            while self.rare_seeds[w] > 0 and self.free_sq > 0:
                crop = self.M["rares"][w]
                self.rare_seeds[w] -= 1
                self.free_sq -= 1
                self.batches.append({"crop": crop, "n": 1, "need": crop["t"], "grown": 0.0, "at": t, "ready": self.ready_at(t, crop["t"])})
        self.chase_bar(t)  # the unlock bar before bundles and requests: it is what the player is after
        if self.free_sq <= 0:
            return
        # crops the barn still needs: the next talent's bundle (planted when it ripens by the next visit) and open requests (planted when
        # their premium beats the best crop's rate)
        want = self.wanted()
        if self.c["req_auto"]:  # tracked requests: planted when their bonus beats the best crop's rate (nothing kept in the barn)
            for rq in self.requests:
                if rq["type"] == "crop" and not rq["done"]:
                    want[rq["crop"]["id"]] = want.get(rq["crop"]["id"], 0) + rq["q"] - rq["have"]
        unl = {c["id"]: c for c in self.unlocked()}
        nt = self.next_talent()
        bundle = set()
        if nt:
            bundle = {self.M["crops"][k - 1]["id"] for k in nt["crops"]}
        q = self.open_quest()
        # a milestone quest's crops: planted at once, whatever their length, only the ones still missing (a kid who reads "bring 5
        # Blueberries" plants 5; timing rules stalled the Giant melon quest: a 6 h Blueberry ripens in no Casual absence or session)
        quest = set(q["quest"]) if q else set()
        base = self.choose(t, self.free_sq, bonus=False)
        base_rate = self.rate(t, base, self.free_sq, False) if base else 0.0
        nxt_visit = self.starts[self.idx(t) + 1] if self.idx(t) + 1 < len(self.S) else math.inf
        for cid, need in sorted(want.items(), key=lambda kv: kv[0] not in quest):
            crop = unl.get(cid)
            if crop is None or self.free_sq <= 0:
                continue
            growing = sum(b["n"] for b in self.batches if b["crop"]["id"] == cid)
            a = self.avail(crop)
            n = min(self.free_sq, need - self.kept.get(cid, 0) - growing, a if a < math.inf else int(self.coins // max(1, crop["seed"])))
            if n <= 0:
                continue
            g = self.grow_of(crop)
            if cid in quest:
                ok = True
            elif cid in bundle:
                ok = self.ready_at(t, g) <= nxt_visit
            else:
                ok = self.rate(t, crop, n, True) > base_rate
            if ok:
                if a < math.inf:
                    self.take_seeds(t, crop, n)
                else:
                    self.spend(t, crop["seed"] * n)
                at = t + n * self.c["act_s"]
                self.batches.append({"crop": crop, "n": n, "need": g, "grown": 0.0, "at": at, "ready": self.ready_at(at, g)})
                self.free_sq -= n
        if self.free_sq <= 0:
            return
        if self.stall_on:
            self.stall_plant(t)
            return
        n = self.free_sq
        crop = self.choose(t, n)
        if crop is None:  # too poor for a full replant: as many squares of the cheapest crop as the Coins buy
            cheap = self.M["crops"][0]
            n = min(n, int(self.coins // cheap["seed"]))
            if n <= 0:
                return
            crop = cheap
            self.free_sq -= n
            self.spend(t, crop["seed"] * n)
            at = t + n * self.c["act_s"]
            g = self.grow_of(crop)
            self.batches.append({"crop": crop, "n": n, "need": g, "grown": 0.0, "at": at, "ready": self.ready_at(at, g)})
            return
        if crop["k"] == 0 and self.start_seeds >= n:
            self.start_seeds -= n
        else:
            free = min(n, self.pouch.get(crop["id"], 0))
            if free:
                self.pouch[crop["id"]] -= free
            self.spend(t, crop["seed"] * (n - free))
        at = t + n * self.c["act_s"]
        g = self.grow_of(crop)
        self.batches.append({"crop": crop, "n": n, "need": g, "grown": 0.0, "at": at, "ready": self.ready_at(at, g)})
        self.free_sq = 0
        self.last_crop = crop

    def collect(self, t, online):
        """Harvest ripe batches, pick fruit, hatch eggs; returns True when something was collected (a collect moment)."""
        got = False
        ripe = [b for b in self.batches if b["ready"] <= t + 1e-6]
        for b in ripe:
            self.batches.remove(b)
            self.harvest(t, b["crop"], b["n"], online)
            self.free_sq += b["n"]
            got = True
        for tr in self.trees:
            T = self.M["trees"][tr["id"]]
            fruits = self.fruits(tr, t)
            if fruits > 0:
                # at the cap the tree stopped bearing: its count restarts now; below the cap the part-grown fruit carries on
                tr["picked"] = tr["grown"] if fruits >= T["cap"] else tr["picked"] + fruits * T["f"]
                self.earn(t, fruits * T["fruit"] * self.sale_mult(), "field")
                self.add_points(t, T["pts"] * fruits)
                got = True
        for inc in list(self.incs):
            if inc["end"] <= t:
                self.incs.remove(inc)
                self.new_pet(t, inc["r"])
                if self.first_hatch_t is None:
                    self.first_hatch_t = t
                self.hatch_t.append(t)
                got = True
        return got

    def fruits(self, tr, t):
        """Fruits hanging on tree `tr` at t (settles its growth): a fruit every f growth seconds after the first growth, at most cap."""
        T = self.M["trees"][tr["id"]]
        if t > tr["at"]:
            tr["grown"] += self.growth(tr["at"], t)
            tr["at"] = t
        if tr["grown"] < T["t0"]:
            return 0
        return min(T["cap"], int((tr["grown"] - tr["picked"]) // T["f"]))

    def apply_sun(self, t):
        if self.sun <= 0 or not self.batches:
            return
        long_left = sum(b["n"] for b in self.batches if b["need"] - b["grown"] >= self.sun * self.g_on)
        planted = sum(b["n"] for b in self.batches)
        if long_left * 2 < planted and self.sun < self.c["sun_cap"]:
            return
        for b in self.batches:
            b["grown"] = min(b["need"], b["grown"] + self.sun * self.g_on)
        for tr in self.trees:
            tr["grown"] += self.sun * self.g_on
        for inc in self.incs:
            inc["end"] -= self.sun
        self.sun = 0.0
        self.refresh_ready(t)

    # ---- pets --------------------------------------------------------------------------------------------------
    def roll_rarity(self, weights):
        ks = list(weights)
        return self.prng.choices(ks, weights=[weights[k] for k in ks])[0]

    def new_pet(self, t, r):
        P, A = self.P, self.M["apt"]
        base, extra = P["apt_count"][r]
        n = base + (1 if self.prng.random() < extra else 0)
        traits = {}
        if self.prng.random() < A["tending"][r]:
            traits["T"] = 1
        if len(traits) < n and self.prng.random() < P["cute_chance"][r]:
            traits["C"] = 1
        pool = ["G", "S"]
        self.prng.shuffle(pool)
        while len(traits) < n and pool:
            traits[pool.pop()] = 1
        for k in ("C", "T"):
            if len(traits) < n and k not in traits:
                traits[k] = 1
        pet = {"r": r, "tr": traits, "xp": {k: 0.0 for k in traits}, "where": "spare"}
        self.pets.append(pet)
        if r == "Legendary" and self.legendary_t is None:
            self.legendary_t = t
        self.manage()

    def bonus(self, p):
        return E.pet_bonus(self.P, p["r"], p["tr"].get("C", 0))

    def strength(self, lvl):
        return self.M["apt"]["str"][max(0, min(lvl, len(self.M["apt"]["str"])) - 1)] if lvl else 0.0

    def manage(self):
        pets = self.pets
        if len(pets) > 50:
            pets.sort(key=lambda p: (RARITIES.index(p["r"]), self.bonus(p)))
            while len(pets) > 50:
                p = pets.pop(0)
                self.earn(0, self.P["rarities"][p["r"]]["sell"], "pets")
        for p in pets:
            p["where"] = "spare"
        slots = self.lvl["EquipSlot"]
        scouts = sorted([p for p in pets if "S" in p["tr"]], key=lambda p: -p["tr"]["S"])
        eq = []
        if slots >= 2 and scouts:
            eq.append(scouts[0])
        for p in sorted([p for p in pets if p not in eq], key=lambda p: -self.bonus(p)):
            if len(eq) >= slots:
                break
            eq.append(p)
        for p in eq:
            p["where"] = "eq"
        field = self.lvl["FieldSlot"]
        rest = [p for p in pets if p["where"] == "spare"]
        if self.guard_first and self.guards_on:
            g = sorted([p for p in rest if "G" in p["tr"]], key=lambda p: -p["tr"]["G"])[:1]
            for p in g:
                p["where"] = "guard"
            field -= len(g)
            rest = [p for p in rest if p["where"] == "spare"]
        tend = sorted([p for p in rest if "T" in p["tr"]], key=lambda p: -p["tr"]["T"]) if self.tending_on else []
        for p in tend[:field]:
            p["where"] = "field"
        left = field - min(field, len(tend))
        if self.guards_on and left > 0:
            for p in sorted([p for p in rest if p["where"] == "spare" and "G" in p["tr"]], key=lambda p: -p["tr"]["G"])[:left]:
                p["where"] = "guard"
        self.mult = 1 + min(self.P["max_bonus"], sum(self.bonus(p) for p in pets if p["where"] == "eq")) / 1000
        if self.c["tend_mode"] == "growth" and hasattr(self, "batches"):
            now = self.now
            self.settle(now)
            self.rates()
            self.refresh_ready(now)

    def train(self, p, key, hours, cap_lvl=None):
        A = self.M["apt"]
        cap = cap_lvl or A["cap"][p["r"]]
        if key not in p["tr"]:
            return
        p["xp"][key] += hours
        first, ratio = (self.c["scout_first_h"], self.c["scout_ratio"]) if key == "S" else (A["first"], A["ratio"])
        while p["tr"][key] < cap and p["xp"][key] >= first * ratio ** (p["tr"][key] - 1):
            p["xp"][key] -= first * ratio ** (p["tr"][key] - 1)
            p["tr"][key] += 1

    def care(self, xp):
        """Care XP to each equipped pet: Cuteness to its cap, then the lowest work trait up to the care cap (PetConfig.GainCareXp)."""
        cap_care, secs = self.P["care"]
        for p in self.pets:
            if p["where"] != "eq":
                continue
            x = xp
            if "C" in p["tr"] and p["tr"]["C"] < self.M["apt"]["cap"][p["r"]]:
                p["xp"]["C"] += x
                while p["tr"]["C"] < self.M["apt"]["cap"][p["r"]] and p["xp"]["C"] >= E.xp_next(self.P, p["tr"]["C"]):
                    p["xp"]["C"] -= E.xp_next(self.P, p["tr"]["C"])
                    p["tr"]["C"] += 1
                continue
            work = [k for k in ("T", "G", "S") if k in p["tr"] and p["tr"][k] < cap_care]
            if work:
                k = min(work, key=lambda k: p["tr"][k])
                self.train(p, k, x * secs / H, cap_lvl=min(cap_care, self.M["apt"]["cap"][p["r"]]))
        self.mult = 1 + min(self.P["max_bonus"], sum(self.bonus(p) for p in self.pets if p["where"] == "eq")) / 1000

    def scout_bonus(self):
        return min(self.c["scout_cap"], sum(self.c["scout_per"] * self.strength(p["tr"]["S"]) for p in self.pets if p["where"] == "eq" and "S" in p["tr"]))

    def coverage(self):
        """Tended squares and their mean strength; guarded share and guard chance."""
        reach = {1: 1, 2: 1, 3: 1, 4: 5, 5: 5, 6: 5}
        n, s = 0, 0.0
        for p in self.pets:
            if p["where"] == "field":
                k = min(reach.get(p["tr"]["T"], 9), max(0, self.open_sq - n))
                n += k
                s += k * self.strength(p["tr"]["T"])
        gn, gc = 0, 0.0
        for p in self.pets:
            if p["where"] == "guard":
                k = self.c["guard_reach"].get(p["tr"]["G"], 42)
                gn += k
                gc = max(gc, min(1.0, 0.5 + 0.5 * self.strength(p["tr"]["G"])))
        return n, (s / n if n else 0.0), min(1.0, gn / max(1, self.open_sq)), gc

    def buy_eggs(self, t):
        while len(self.incs) < self.lvl["Incubator"]:
            if self.starter_egg:
                self.starter_egg = False
                r = self.roll_rarity(self.c["starter_egg"])
            elif self.free_eggs:
                r = self.roll_rarity(self.M["eggs"][self.free_eggs.pop(0)]["w"])
            else:
                eggs = sorted(((k, e) for k, e in self.M["eggs"].items() if self.egg_open(k)), key=lambda kv: kv[1]["price"])
                kind = None
                for k, e in eggs:  # the dearest egg the fund buys, unless a day of the egg budget buys a dearer one
                    if e["price"] <= self.egg_fund:
                        kind = k
                    elif self.egg_rate() >= e["price"]:
                        kind = None
                if kind is None:
                    return
                self.egg_fund -= self.M["eggs"][kind]["price"]
                self.egg_bought[kind] = self.egg_bought.get(kind, 0) + 1
                self.spent += self.M["eggs"][kind]["price"]
                self.spent_by_day[self.day(t)] += self.M["eggs"][kind]["price"]
                r = self.roll_rarity(self.M["eggs"][kind]["w"])
                w = self.M["eggs"][kind]["w"]
                self.leg_mass(t, w.get("Legendary", 0) / sum(w.values()))
            self.incs.append({"r": r, "end": t + self.c["hatch"][r]})

    def egg_open(self, kind):
        """EG: an egg with an opening crop (PetConfig opensWith) is sold once that crop is open."""
        k = self.M["egg_opens"].get(kind)
        return k is None or k in self.unl

    def leg_mass(self, t, p):
        """Expected Legendaries so far (G9 reads the day this passes 0.5, not one lucky roll)."""
        self.leg_exp += p
        if self.leg_half is None and self.leg_exp >= 0.5:
            self.leg_half = t / DAY

    def egg_rate(self):
        return self.egg_share * self.daily_income()

    def daily_income(self, days=1):
        """Coins per day over the last `days` days of income (whole log window, not a fixed number of entries)."""
        if not self.income_log:
            return 0.0
        t = max(getattr(self, "now", 0.0) or 0.0, max(tt for tt, _ in self.income_log[-50:]))
        lo = t - days * DAY
        tot = 0.0
        for tt, c in self.income_log[-3000:]:  # not strictly in time order (an absence books its harvests at their ripe times)
            if lo <= tt <= t:
                tot += c
        span = min(days * DAY, max(DAY, t - self.income_log[0][0]))
        return tot * DAY / span

    def feed(self):
        if self.food_fund <= 0:
            return
        best = max(self.M["foods"], key=lambda f: f["xp"] / f["price"])
        n = int(self.food_fund // best["price"])
        if n <= 0:
            return
        trainable = [p for p in self.pets if p["where"] == "eq" and ("C" in p["tr"] and p["tr"]["C"] < self.M["apt"]["cap"][p["r"]])]
        if not trainable:
            return
        self.food_fund -= n * best["price"]
        self.spent += n * best["price"]
        self.care(n * best["xp"] / max(1, len([p for p in self.pets if p["where"] == "eq"])))

    # ---- purchases ---------------------------------------------------------------------------------------------
    def can_buy(self, it):
        if it["name"] in self.bought or (not self.stars_on and it["gate"] > self.level):  # EV3: sinks on Coins alone
            return False
        if it["fam"] == "Talent":
            if self.talent[it["tid"]] != it["lvl"] - 1:
                return False
            for k, n in it["crops"].items():
                if self.kept.get(self.M["crops"][k - 1]["id"], 0) < n:
                    return False
            for w, n in it["rare_need"].items():
                if self.kept.get(self.M["rares"][w]["id"], 0) < n:
                    return False
        if it["fam"] == "Square" and self.lvl["Square"] != it["lvl"] - 1:
            return False
        if it["fam"] in ("Growth", "Barn", "Sorter", "Cloches", "Shears") and self.lvl[it["fam"]] != it["lvl"] - 1:
            return False
        if it["fam"] in ("FieldSlot", "EquipSlot", "Incubator") and self.lvl[it["fam"]] != it["lvl"] - 1:
            return False
        if it["fam"] == "Sapling" and (self.free_sq + self.planted_sq() < 1 or self.open_sq - len(self.trees) <= 4):
            return False
        return True

    def planted_sq(self):
        return sum(b["n"] for b in self.batches if not b["crop"]["rare"])

    def do_buy(self, t, it):
        self.spend(t, it["price"])
        self.bought.add(it["name"])
        self.buy_day[it["name"]] = t / DAY
        fam = it["fam"]
        if fam == "Talent":
            self.talent[it["tid"]] = it["lvl"]
            for k, n in it["crops"].items():
                self.kept[self.M["crops"][k - 1]["id"]] -= n
            for w, n in it["rare_need"].items():
                self.kept[self.M["rares"][w]["id"]] -= n
            self.blocked_since.pop(it["tid"], None)
        elif fam == "Square":
            self.lvl["Square"] += 1
            self.open_sq += 1
            self.free_sq += 1
        elif fam == "Sapling":
            if self.free_sq < 1:  # take a square from the batch that ripens last
                b = max((b for b in self.batches if not b["crop"]["rare"]), key=lambda b: b["ready"])
                b["n"] -= 1
                if b["n"] <= 0:
                    self.batches.remove(b)
            else:
                self.free_sq -= 1
            self.trees.append({"id": it["tree"], "grown": 0.0, "at": t, "picked": self.M["trees"][it["tree"]]["t0"]})
        elif fam in ("Growth", "Cloches"):
            self.settle(t)
            self.lvl[fam] += 1
            self.rates()
            self.refresh_ready(t)
        elif fam == "Reserved":
            pass
        else:
            self.lvl[fam] += 1
            if fam in ("EquipSlot", "FieldSlot"):
                self.manage()

    def shop(self, t):
        """Buy in queue order; may skip at most 2 items that are gated or unaffordable (SIM window); required talents first."""
        reserve = self.reserve()  # never spend the seeds for the next replant
        for _ in range(200):
            done = False
            req = [it for it in self.queue if it["fam"] == "Talent" and it["tid"] in self.blocked_since and it["name"] not in self.bought]
            if req and self.can_buy(req[0]) and req[0]["price"] > self.coins - reserve:
                return  # saving for a talent the obby needs
            cand = req + [it for it in self.queue if it["name"] not in self.bought]
            waiting = 0
            for it in cand:
                if it["name"] in self.bought or not self.can_buy(it):
                    continue  # gated (Renown, order, bundle crops not in the barn yet): the next item
                if it["price"] <= self.coins - reserve:
                    self.do_buy(t, it)
                    done = True
                    break
                waiting += 1  # affordable later: at most 2 such items are passed over for a cheaper one behind them
                if waiting > 2:
                    break
            if not done:
                return

    def reserve(self):
        """Coins kept for the next replant: the last crop on every square, or (EV3) the newest crop while its bar is open."""
        seed = self.last_crop["seed"]
        if self.stall_on and not self.st:
            return self.M["crops"][self.c["stall_staples"] - 1]["seed"] * self.open_sq
        if self.st:  # ST: a staple replant, or the newest crop while its bar is open (stall seeds come out of what is left)
            seed = self.M["crops"][self.c["stall_staples"] - 1]["seed"]
        if self.stars_on and self.chain_rule(max(self.unl) + 1):
            new = self.M["crops"][max(self.unl)]
            if self.xp[new["k"]] < unlock_need(new, self.c) - 1e-9:
                seed = max(seed, new["seed"])
        return seed * self.open_sq

    def next_goal(self):
        """The next purchase: the cheapest of the first three items the player can buy once the Coins are there (the shop's window)."""
        win = []
        for it in self.queue:
            if it["name"] not in self.bought and self.can_buy(it):
                win.append(it)
                if len(win) == 3:
                    break
        return min(win, key=lambda it: it["price"]) if win else None

    # ---- requests and streak -----------------------------------------------------------------------------------
    def new_day(self, t):
        d = self.day(t)
        if self.req_day == d:
            return
        self.req_day = d
        self.qrng = random.Random(self.seed * 1000003 + d)  # one stream per day: runs that differ elsewhere see the same requests
        if not self.c["req_auto"]:
            self.requests = []
        want = self.wanted()
        for cid, n in list(self.kept.items()):  # crops kept for yesterday's requests are sold
            extra = n - want.get(cid, 0)
            if extra > 0:
                crop = next((c for c in self.M["crops"] if c["id"] == cid), None) or next(r for r in self.M["rares"].values() if r["id"] == cid)
                self.kept[cid] = n - extra
                self.earn(t, extra * self.sale_of(crop) * self.sale_mult(), "rare" if crop["rare"] else "field")
        self.runs_today = {}
        self.first_today = set()
        self.fill_requests(t)
        self.streak_day(t, d)

    def fill_requests(self, t):
        """The day's requests. req_auto: an unfinished request stays and only finished slots refill; the board opens (fills) on the
        first visit with two eligible crops known, even mid-day (a fresh player's first board on day 0)."""
        d = self.day(t)
        carry = [rq for rq in self.requests if not rq["done"]] if self.c["req_auto"] else []
        self.requests = list(carry)
        crops = [c for c in self.known() if c["t"] <= self.c["req_max_h"] * H and c["k"] >= 2]
        daily = max(self.daily_income(), 2000.0)
        picked = {rq["crop"]["id"] for rq in carry if rq["type"] == "crop"}
        has_run = any(rq["type"] == "run" for rq in carry)
        for slot in range(len(carry), self.c["req_per_day"] if len(crops) >= 2 else 0):
            if slot == self.c["req_per_day"] - 1 and not has_run and self.cleared and self.qrng.random() < self.c["req_run_share"]:
                self.requests.append({"type": "run", "done": False})
                continue
            choices = [c for c in crops if c["id"] not in picked] or crops
            crop = self.qrng.choice(choices)
            picked.add(crop["id"])
            q = max(3, min(self.barn_cap() // 2, round(self.c["req_size"] * daily / max(1, crop["sale"] * self.mult))))
            self.requests.append({"type": "crop", "crop": crop, "q": q, "done": False, "have": 0})
        if len(crops) >= 2:
            self.board_day = d

    def streak_day(self, t, d):
        """The streak (the day's first session)."""
        if self.streak_last != d:
            self.streak_last = d
            self.streak = self.streak % 7 + 1
            if self.streak < 7:
                self.sun = min(self.c["sun_cap"], self.sun + self.c["streak_sun"][self.streak - 1] * 60)
            else:
                w = self.c["streak_pet"]
                self.leg_mass(t, w.get("Legendary", 0) / sum(w.values()))
                self.new_pet(t, self.roll_rarity(w))

    def check_requests(self, t):
        for rq in self.requests:
            if rq["done"] or rq["type"] != "crop":
                continue
            cid = rq["crop"]["id"]
            if self.kept.get(cid, 0) >= rq["q"]:
                self.kept[cid] -= rq["q"]
                rq["done"] = True
                self.earn(t, rq["q"] * self.sale_of(rq["crop"]) * self.c["req_mult"], "request")
                self.add_points(t, rq["crop"]["pts"] * rq["q"])
                self.request_drop(t)
                self.mark(t)

    def req_left(self, cid):
        return sum(rq["q"] - rq["have"] for rq in self.requests if rq["type"] == "crop" and not rq["done"] and rq["crop"]["id"] == cid)

    def track_requests(self, t, crop, n):
        """req_auto: a harvest counts toward the open requests of its crop; a finished one pays its bonus (the crops were sold)."""
        for rq in self.requests:
            if rq["done"] or rq["type"] != "crop" or rq["crop"]["id"] != crop["id"] or n <= 0:
                continue
            use = min(n, rq["q"] - rq["have"])
            rq["have"] += use
            n -= use
            if rq["have"] >= rq["q"]:
                rq["done"] = True
                self.req_done_t.append(t)
                self.earn(t, rq["q"] * self.sale_of(crop) * self.c["req_bonus"], "request")
                self.request_drop(t)
                self.mark(t)

    def request_drop(self, t):
        if self.qrng.random() < self.c["req_drop"]:
            k = self.qrng.randrange(3) if self.c.get("req_drop_sun", True) else 1 + self.qrng.randrange(2)
            if k == 0:
                self.sun = min(self.c["sun_cap"], self.sun + self.c["req_sun"])
            elif k == 1:
                w = max([s["world"] for s in self.cleared if s["world"] >= 1] or [1])
                self.rare_seeds[w] = self.rare_seeds.get(w, 0) + 1
            else:  # EG: a Topaz egg once Pumpkin is open (CropConfig.Requests), a Pearl one before
                self.free_eggs.append(self.c["req_egg_late"] if self.egg_open(self.c["req_egg_late_after"]) else "Basic")

    def mark(self, t):
        i = self.idx(t)
        if i >= 0 and t <= self.ends[i] + 1e-6:
            self.events.append(t)
            self.events_by_day[self.day(t)] += 1

    # ---- garden visit ------------------------------------------------------------------------------------------
    def attend(self, t, online=True, leaving=False):
        self.now = t
        self.settle(t)
        self.apply_sun(t)
        got = self.collect(t, online)
        got = self.try_quest(t) or got
        if self.c["req_auto"] and self.board_day != self.day(t) and self.req_day == self.day(t):
            self.fill_requests(t)  # the board opens as soon as two eligible crops are known
        if got and online:
            self.mark(t)
        self.visit_stall(t)
        self.shop(t)
        self.buy_eggs(t)
        self.feed()
        self.plant(t)
        if leaving:
            self.hook(t)

    def hook(self, t):
        """G2: does an option ripen within x0.6-1.2 of the coming absence (or before the return when the absence is past the cap)?"""
        i = self.idx(t)
        if i + 1 >= len(self.S):
            return
        back = self.starts[i + 1]
        gap = back - t
        crops = self.unlocked()
        if self.stall_on:  # the staples, the seeds in the bag and what was just planted from it
            crops = [c for c in crops if self.avail(c) > 0] + [bt["crop"] for bt in self.batches if bt["at"] >= t and not bt["crop"]["rare"]]
        elif self.price_rule:  # what the player has grown, or could plant on a square now
            crops = [c for c in crops if c["k"] in self.unlock_t or c["seed"] <= self.coins]
        opts = [self.grow_of(c) for c in crops] + [self.M["rares"][w]["t"] for w, n in self.rare_seeds.items() if n > 0]
        for tr in self.trees:  # a tree is a timer too: full (its cap of fruit) at its next fill
            T = self.M["trees"][tr["id"]]
            self.fruits(tr, t)
            opts.append(max(1.0, max(T["t0"], tr["picked"]) + T["cap"] * T["f"] - tr["grown"]))
        ok = False
        for need in opts:
            r = self.ready_at(t, need) - t
            if 0.6 * gap <= r <= 1.2 * gap or (gap > self.cap and r <= gap):
                ok = True
                break
        self.hooks.append((self.day(t), ok))

    def absence(self, a, b):
        """Between sessions: Tending replants ripe crops in its reach, crows eat at most `cap` ripe crops, pets train."""
        if a <= 0:
            return
        self.now = b
        crng = random.Random(self.seed * 9176 + int(a))  # one stream per absence: runs that differ elsewhere see the same crows
        n_t, s_t, g_share, g_ch = self.coverage()
        left = n_t if self.c["tend_mode"] == "replant" else 0
        for bt in sorted(self.batches, key=lambda x: x["ready"]):
            if bt["crop"]["rare"] or bt["ready"] >= b or left <= 0:
                continue
            cover = min(left, bt["n"])
            left -= cover
            g = self.growth(bt["ready"], b)
            m = int(g // bt["need"])
            extra = sum(s_t ** j for j in range(1, m + 1)) * cover
            room = max(0, self.barn_cap() - sum(self.kept.values()))
            extra = min(extra, room)
            if extra > 0:
                crop = bt["crop"]
                self.earn(b, extra * (self.sale_of(crop) * self.sale_mult() - crop["seed"] / self.mult), "field")
                self.add_points(b, crop["pts"] * extra)
                self.add_xp(b, crop, extra)
                self.tend_extra += extra * crop["net"]
        if self.c["rest_per_day"] > 0 and b - a > DAY:  # rested mastery for the days away past the first
            self.rest = min(self.c["rest_cap"], self.rest + (b - a - DAY) / DAY * self.c["rest_per_day"])
        hours = self.growth(a, b, on=self.M["work_rates"][0], off=self.M["work_rates"][1]) / H
        for p in self.pets:
            if p["where"] == "field":
                self.train(p, "T", hours)
            if p["where"] == "guard":
                self.train(p, "G", hours)
        share, chance, cap, block_h, from_lv = self.M["crows"]
        crows_open = self.M["by_id"][self.c["crows_from"]]["k"] <= self.newest() if self.stars_on else self.level >= from_lv
        if self.crows_on and crows_open and cap > 0:
            ripe = [bt for bt in self.batches if not bt["crop"]["rare"] and bt["ready"] < b]
            if ripe:
                k0, k1 = int(max(a, min(bt["ready"] for bt in ripe)) // (block_h * H)), int(b // (block_h * H))
                crows = any(random.Random(7000003 + k).random() < share for k in range(k0, k1 + 1))
                if crows:
                    # guarded squares are safe: crows find only the unguarded ripe crops (a lower chance per crop saturates on a big
                    # field and made a guard nearly worthless)
                    open_share = 1 - g_share * g_ch
                    cap_n = max(cap, round(self.open_sq * open_share) // self.c["crow_per"])
                    for _ in range(cap_n):
                        ripe = [bt for bt in self.batches if not bt["crop"]["rare"] and bt["ready"] < b]
                        n = sum(bt["n"] for bt in ripe) * open_share
                        if not ripe or crng.random() >= 1 - (1 - chance) ** n:
                            break
                        bt = max(ripe, key=lambda x: x["crop"]["sale"])
                        bt["n"] -= 1
                        self.free_sq += 1
                        self.crow_loss += bt["crop"]["sale"]
                        if bt["n"] <= 0:
                            self.batches.remove(bt)

    # ---- obby --------------------------------------------------------------------------------------------------
    def obby(self, a, b):
        """Runs inside [a, b): learning the next stage (first clear pays the one-time Coins), else repeat Gold runs for Sunshine and seeds;
        the garden is checked every `check` minutes."""
        P = self.P
        t = a
        step = self.arch["check"] * 60.0
        nxt_check = a + step
        stages = self.M["stages"]
        while t < b:
            if t >= nxt_check:
                self.attend(t)
                nxt_check = t + step
            st = None
            if self.learn is None and len(self.cleared) < len(stages):
                cand = stages[len(self.cleared)]
                miss = [(tid, lv) for (tid, lv), at in E.PLANNED["required_at"].items() if at <= cand["order"] and self.talent.get(tid, 0) < lv
                        and tid in self.talent]
                if cand["key"] not in self.reach_day:
                    self.reach_day[cand["key"]] = t / DAY
                if miss:
                    for tid, _ in miss:
                        self.blocked_since.setdefault(tid, t)
                else:
                    self.learn = [cand, E.learn_runs(cand)]
            if self.learn:
                s = self.learn[0]
                dt = s["t_base"] * E.SIM["learn_factor"] + E.MODEL["run_overhead_s"]
                t += dt
                self.obby_h_by_day[self.day(t)] += dt / H
                self.learn[1] -= 1
                if self.learn[1] <= 0:
                    self.cleared.append(s)
                    self.learn = None
                    coins, pack, upto = first_clear_coins(self.M, s)
                    rate = self.farm_rate()
                    self.earn(t, coins + E.SIM["coin_capture"] * E.coins_of(P, s), "obby")
                    seed_val = 0
                    if pack:  # a seed pack of the newest unlocked crop (a locked crop's seeds would skip its unlock)
                        crop = self.M["crops"][min(max(self.unl), self.M["by_id"][upto]["k"])]
                        self.pouch[crop["id"]] = self.pouch.get(crop["id"], 0) + pack
                        seed_val = pack * crop["seed"]
                    self.clear_log.append((t, s["key"], coins * self.mult + seed_val, rate))
                    if s["world"] >= 2 and s["world"] >= self.M["obby_seeds"][0]:
                        self.rare_seeds[min(s["world"], 3)] = self.rare_seeds.get(min(s["world"], 3), 0) + self.M["obby_seeds"][1]
                    if s["order"] == 5:  # World 2 opens: Double Jump is the world reward
                        self.talent["DoubleJump"] = max(self.talent["DoubleJump"], 1)
                    self.finish(t, s, 3)
                    self.mark(t)  # a first clear pays its medals: a collect moment
                continue
            if not self.cleared:
                t = b
                break
            # repeat Gold runs: the stage with the most Sunshine per second
            st = max(self.cleared, key=lambda s: self.sun_of(s, 3) / self.run_dt(s))
            dt = self.run_dt(st)
            t += dt
            self.obby_h_by_day[self.day(t)] += dt / H
            self.finish(t, st, 3)
        return t

    def run_dt(self, s):
        return s["t_base"] * E.MODEL["gold_run_factor"] + E.MODEL["run_overhead_s"]

    def sun_of(self, s, medal):
        n = self.runs_today.get(s["key"], 0)
        return max(self.c["sun_floor"], self.c["sun"][medal - 1] * self.c["sun_decay"] ** n)

    def finish(self, t, s, medal):
        """One medal finish: Sunshine, rare-seed meter, the day's first seeds, pet XP (care, Scouting), a timed-run request."""
        P = self.P
        self.now = t
        bonus = self.scout_bonus()
        sun = self.sun_of(s, medal) * (1 + bonus)
        self.sun = min(self.c["sun_cap"], self.sun + sun)
        self.sun_by_day[self.day(t)] += sun
        first = s["key"] not in self.first_today
        self.first_today.add(s["key"])
        self.runs_today[s["key"]] = self.runs_today.get(s["key"], 0) + 1
        fg_world, per_fg, daily, size, pts, fmult, pouch = self.M["obby_seeds"]
        w = min(max(s["world"], 0), 3)
        drop = False
        if w >= 1:
            self.meter[s["key"]] = self.meter.get(s["key"], 0.0) + pts[medal - 1] * (fmult if first else 1) * (1 + bonus)
            while self.meter[s["key"]] >= size:
                self.meter[s["key"]] -= size
                self.rare_seeds[w] = self.rare_seeds.get(w, 0) + 1
                drop = True
            if self.daily_seed_day != self.day(t):
                self.daily_seed_day = self.day(t)
                best = max(x["world"] for x in self.cleared)
                self.rare_seeds[min(best, 3)] = self.rare_seeds.get(min(best, 3), 0) + daily
                drop = True
            if first and pouch:
                cid = self.last_crop["id"]
                room = max(0, self.barn_cap() - sum(self.pouch.values()) - sum(self.kept.values()))
                n = min(room, pouch[medal - 1] + (1 if bonus >= 0.5 - 1e-9 else 0))
                if n > 0:
                    self.pouch[cid] = self.pouch.get(cid, 0) + n
                    drop = True
        studs = E.SIM["move_speed"] * s["t_base"] * E.MODEL["gold_run_factor"] * E.SIM["move_share"]
        self.care(P["medal_xp"][medal - 1] + min(P["max_move_xp"], int(studs // P["studs_per_xp"])))
        secs = s["t_base"] * E.MODEL["gold_run_factor"]
        for p in self.pets:
            if p["where"] == "eq" and "S" in p["tr"]:
                self.train(p, "S", secs / H)
        for rq in self.requests:
            if rq["type"] == "run" and not rq["done"] and self.qrng.random() < 0.15:
                rq["done"] = True
                if self.qrng.random() < 0.5:
                    self.sun = min(self.c["sun_cap"], self.sun + self.c["req_sun"])
                else:
                    self.rare_seeds[max(w, 1)] = self.rare_seeds.get(max(w, 1), 0) + 1
                self.add_points(t, 20)
                drop = True
        if drop:
            self.mark(t)

    # ---- the run -----------------------------------------------------------------------------------------------
    def run(self):
        prev_end = 0.0
        for i, (s, e, os_, oe) in enumerate(self.S):
            if i:
                self.absence(prev_end, s)
            self.new_day(s)
            if self.spender and self.day(s) >= SPENDER["from_day"] and not getattr(self, "spender_given", False):
                self.spender_given = True
                self.lvl["FieldSlot"] = min(5, self.lvl["FieldSlot"] + 1)
                self.lvl["Incubator"] = min(3, self.lvl["Incubator"] + 1)
                self.manage()
            if self.spender and self.batches and getattr(self, "instant_day", -1) != self.day(s):
                self.instant_day = self.day(s)  # instant grow on a few squares a day: crops of the longest batch now
                b = max(self.batches, key=lambda b: b["need"])
                self.harvest(s, b["crop"], min(b["n"], SPENDER["instant_per_day"]))
            self.attend(s)
            t = s
            # garden time before the obby block
            t = self.garden(t, os_)
            if oe > os_:
                t = self.obby(os_, oe)
                t = max(t, oe)
                self.attend(min(t, e))
            self.garden(min(t, e), e)
            self.attend(e, leaving=True)
            self.goal_line(e)
            d = self.day(s)
            self.online_by_day[d] += (e - s) / 60.0
            prev_end = e
        return self

    def goal_line(self, t):
        """G3, at the end of a session after its shopping: hours of income until the next goal is affordable, and how many items the
        player could buy right now but did not (none, when the shop logic works)."""
        ng = self.next_goal()
        rate = self.daily_income(2) / 24.0 * (1 - self.egg_share - self.food_share)  # 2 days: long crops pay every other day
        if ng is None or rate <= 0:
            return
        reserve = self.reserve()
        hrs = max(0.0, ng["price"] - (self.coins - reserve)) / rate
        aff = sum(1 for it in self.queue if it["name"] not in self.bought and it["group"] != "reserved" and self.can_buy(it)
                  and it["price"] <= self.coins)
        self.goal.append((self.day(t), hrs, aff, ng["name"]))

    def garden(self, a, b):
        """Garden mode from a to b: the player reacts to every ripe batch, fruit and egg at once."""
        t = a
        while t < b:
            nxt = min([bt["ready"] for bt in self.batches] + [inc["end"] for inc in self.incs] + [self.next_fruit(t), b])
            if self.stall_on:  # the player looks at every restock while online
                e = self.c["st_every"] if self.st else self.c["stall_every"]
                nxt = min(nxt, (int(t // e) + 1) * e)
            if nxt >= b:
                break
            t = max(nxt, t + 1.0)
            self.attend(t)
        return b

    def next_fruit(self, t):
        """When the player next picks fruit online: once half a tree's cap hangs on it (one tap picks them all)."""
        best = math.inf
        for tr in self.trees:
            T = self.M["trees"][tr["id"]]
            self.fruits(tr, t)
            target = max(T["t0"], tr["picked"]) + T["f"] * max(1, T["cap"] // 2)
            best = min(best, self.ready_at(t, max(1.0, target - tr["grown"])))
        return best


# --------------------------------------------------------------------------------------------------------------------
# Runs, checks, tables.
# --------------------------------------------------------------------------------------------------------------------
_RUNS = {}


SEED = [1]  # the default random seed of a run (`--seed N`)


def run(M, arch, policy="talent-first", days=60, **kw):
    kw.setdefault("seed", SEED[0])
    key = (id(M), arch["name"], policy, days, tuple(sorted(kw.items())))
    if key not in _RUNS:
        _RUNS[key] = Sim(M, arch, policy, days, **kw).run()
    return _RUNS[key]


def arch_by(name):
    return next(a for a in ARCH if a["name"] == name)


def first_hour(M):
    """G7: a fresh player gardening for 60 minutes straight (no obby): first harvest, crops unlocked, the longest wait for something new
    (a crop's star (EV3) or a Renown level, a crop unlocked, the first harvest of a crop kind, a purchase, every hatch), first square,
    first hatch."""
    a = {"name": "First hour", "sessions": [(0.0, 1.0)], "period": 400, "obby_min": 0, "check": 5}
    s = Sim(M, a, "talent-first", days=1).run()
    unl = sorted(t for k, t in s.unlock_t.items() if t <= 3600)
    levels = [t for t, _, _ in s.star_t] if s.stars_on else s.level_t  # a crop's star (EV3) or a Renown level
    news = sorted(set(unl + [d * DAY for d in s.buy_day.values() if d * DAY <= 3600] + [t for t in s.hatch_t if t <= 3600]
                      + [t for t in levels if t <= 3600] + [t for t in s.first_crop_t.values() if t <= 3600]
                      + [t for t in s.first_seed_t.values() if t <= 3600] + [t for t in s.req_done_t if t <= 3600]))
    gaps = [b - a for a, b in zip(news, news[1:] + [3600.0])]
    sq = s.buy_day.get("Square 5")
    return {"first_harvest_s": s.first_harvest_t, "crops_hour1": len(unl), "max_gap_min": round(max(gaps) / 60, 1),
            "unlock_min": [round(t / 60, 1) for t in unl], "first_square_min": None if sq is None else sq * 1440,
            "first_hatch_min": None if s.first_hatch_t is None else s.first_hatch_t / 60, "coins": s.coins, "level": s.level,
            "bought": sorted((round(d * 1440, 1), k) for k, d in s.buy_day.items())}


def checks(M, days=60, verbose=True):
    res = []

    def add(name, ok, text):
        res.append((name, ok, text))

    diff = config_match(M)
    ev3b = ""
    add("EV0 configs carry the proposal (CAND)", not diff,
        ("; ".join(diff[:4]) + (f" ... ({len(diff)} in all)" if len(diff) > 4 else "") or "equal") + ev3b)
    g7 = first_hour(M)
    ok7 = (g7["first_harvest_s"] or 1e9) <= 30 and g7["crops_hour1"] >= 6 and g7["max_gap_min"] <= 10 and (g7["first_square_min"] or 99) <= 15         and (g7["first_hatch_min"] or 99) <= 5
    add("G7 first hour", ok7, f"first harvest {g7['first_harvest_s']:.0f} s, {g7['crops_hour1']} crops (at {g7['unlock_min']} min), longest wait for "
        f"something new {g7['max_gap_min']} min, first square {g7['first_square_min'] and round(g7['first_square_min'], 1)} min, first hatch "
        f"{g7['first_hatch_min'] and round(g7['first_hatch_min'], 1)} min")
    names = ["Obby main", "Casual", "Garden main", "Binge"]
    sims = {(n, p): run(M, arch_by(n), p, days) for n in names for p in POLICIES}
    # G1 ready cadence
    rows = []
    ok1 = True
    for n in names:
        s = sims[(n, "talent-first")]
        gaps = []
        for d in range(days):
            if s.online_by_day[d] > 0:
                gaps.append(s.online_by_day[d] / max(1, s.events_by_day[d]))
        d1 = gaps[0] if gaps else 99
        later = sorted(gaps[1:])
        p90 = later[int(0.9 * (len(later) - 1))] if later else 0
        ok = d1 <= 4 and p90 <= 8
        ok1 &= ok
        rows.append(f"{n} day1 {d1:.1f} / p90 later {p90:.1f}")
    add("G1 ready cadence (min between collects)", ok1, "; ".join(rows))
    # G2 return hook
    rows, ok2 = [], True
    for n in names:
        s = sims[(n, "talent-first")]
        h = [ok for d, ok in s.hooks if d >= 2]
        share = sum(h) / len(h) if h else 1
        ok2 &= share >= 0.9
        rows.append(f"{n} {share:.0%}")
    add("G2 return hook (session ends with a timer for the absence)", ok2, "; ".join(rows))
    # G3 next goal
    rows, ok3 = [], True
    for n in names:
        s = sims[(n, "talent-first")]
        per_day = len(arch_by(n)["sessions"]) / arch_by(n)["period"]
        gap_h = 24.0 / per_day
        g = [(d, h, a) for d, h, a, _ in s.goal if d < 30]
        hrs = sorted(h for _, h, _ in g)
        med = hrs[len(hrs) // 2] / gap_h if hrs else 0
        mx = max(h for _, h, _ in g) / 24 if g else 0
        aff = sorted(a for d, _, a in g if d >= 2)
        p90 = aff[int(0.9 * (len(aff) - 1))] if aff else 0
        ok = (med >= 0.3 or per_day < 1) and med <= 2 and mx <= 3  # a weekly player's next goal may be under a day of income away
        ok3 &= ok
        rows.append(f"{n} median {med:.1f} sessions, max {mx:.1f} d, affordable p90 {p90}")
    add("G3 next goal when leaving (0.3-2 sessions away)", ok3, "; ".join(rows))
    # G4 talents
    P = M["P"]
    obby_w2 = sum(first_clear_coins(M, s)[0] + E.coins_of(P, s) for s in M["stages"] if s["order"] <= 10)
    tree = sum(it["price"] for it in M["items"] if it["fam"] == "Talent" and it["tid"] in ("RunSpeed", "JumpHeight", "QuickRespawn", "DoubleJump", "Dash"))
    share = obby_w2 / tree if tree else 9
    rows = [f"obby-only Coins to World 2 = {share:.0%} of the World 1-2 tree ({E.n(obby_w2)} / {E.n(tree)})"]
    ok4 = share <= 0.40
    for n, lim in (("Obby main", 1), ("Garden main", 1), ("Casual", 2)):
        s = sims[(n, "talent-first")]
        for key, tid, lvl in (("Stage11", "DoubleJump", 2), ("Stage13", "Dash", 2)):
            reach = s.reach_day.get(key)
            got = s.buy_day.get(f"{tid} {lvl}")
            if reach is None:
                rows.append(f"{n} {key} not reached")
                continue
            wait = (got - reach) if got is not None else math.inf
            ok4 &= wait <= lim
            rows.append(f"{n} {tid} {lvl} {wait:.1f} d after reaching {key} (day {reach:.1f})")
    add("G4 talents need the farm, no dead end", ok4, "; ".join(rows))
    # G5 horizon
    rows, ok5 = [], True
    for n, lim in (("Garden main", 45), ("Casual", 90)):
        s = run(M, arch_by(n), "talent-first", max(days, lim + 10))
        last = max((d for k, d in s.buy_day.items() if not k.startswith("Reserved")), default=0)
        left = sum(1 for it in s.queue if it["name"] not in s.bought and it["group"] != "reserved")
        ok = left > 0 or last >= lim
        ok5 &= ok
        rows.append(f"{n} last purchase day {last:.0f}, {left} left at day {max(days, lim + 10)}")
    add("G5 horizon", ok5, "; ".join(rows))
    # G6 expedition
    rows, ok6 = [], True
    for n in ("Casual", "Garden main"):
        s = sims[(n, "talent-first")]
        ok_share = s.obby_after3 / s.after3 if s.after3 else 0
        ok6 &= ok_share <= 0.25
        rows.append(f"{n} obby Coins {ok_share:.0%} after day 3")
    worst = 0.0
    for n in names:
        s = sims[(n, "talent-first")]
        for d in range(days):
            if s.obby_h_by_day[d] > 0.2:
                worst = max(worst, s.sun_by_day[d] / 60 / s.obby_h_by_day[d])
    ok6 &= worst <= 40
    rows.append(f"Sunshine at most {worst:.0f} min per obby hour")
    add("G6 the obby is the expedition", ok6, "; ".join(rows))
    # R rare crops stay a treat (playtest 2026-11-08: the first Golden carrot paid 350 000 on day 1, 58-79 % of day 1's income): on days 0-3 at most 70 % of a day's income, in the
    # first 5 days no single sale above 5x everything earned before it; one World 1 rare from an empty field gives at most 3 Renown levels
    rows, okr = [], True
    for n in names + ["Spender"]:
        s = run(M, arch_by(n), "talent-first", days)
        share = max(s.rare_by_day[d] / s.earned_by_day[d] for d in range(4) if s.earned_by_day[d] > 0)
        jump = max((c / max(1.0, before) for t, c, before in s.rare_sales if t < 5 * DAY), default=0.0)
        okr &= share <= 0.70 and jump <= 5.0
        rows.append(f"{n} top share {share:.0%}, biggest sale {jump:.1f}x earned before")
    if M["mode"] == "renown":
        first_levels = renown_level(M, M["rares"][1]["pts"])
        okr &= first_levels <= 3
        rows.append(f"first World 1 rare = Renown {first_levels}")
    else:
        rows.append("rare crops give no crop XP (EV3)")
    add("R rare crops stay a treat", okr, "; ".join(rows))
    # G8 Spender headroom
    free, paid = run(M, arch_by("Spender"), "talent-first", days, free=True), run(M, arch_by("Spender"), "talent-first", days)
    rows, ok8, ratios = [], True, []
    for goal in ("Dash 2", "Square 20", "Square 28", "Square 36", "Growth 4", "Sorter 3"):
        a = free.legendary_t / DAY if goal == "legendary" and free.legendary_t else free.buy_day.get(sq_name(goal))
        b = paid.legendary_t / DAY if goal == "legendary" and paid.legendary_t else paid.buy_day.get(sq_name(goal))
        if a is None or b is None or b <= 0:
            rows.append(f"{goal}: free {fmt_d(a)} / paid {fmt_d(b)}")
            continue
        ratios.append(a / b)
        rows.append(f"{goal}: {a / b:.2f}x (free day {a:.1f}, paid {b:.1f})")
    if ratios:
        ok8 = 1.2 <= statistics.median(ratios) <= 1.5 and max(ratios) <= 1.6
    add("G8 Spender headroom 1.2-1.5x", ok8, "; ".join(rows))
    # G9 scarcity (Casual, free)
    rows, ok9 = [], True
    for p in POLICIES:
        s = sims[("Casual", p)]
        leg = s.leg_half
        top = s.unlock_t.get(len(M["crops"]) - 1)
        top = top / DAY if top else None
        tool = s.buy_day.get("Shears 3")
        # top crop from day 10 (the user, 2026-11-21: the quicker pace of the flatter ladder, ECONOMY.md → Findings (FL); was 14)
        top_ok = top is None or (10 <= top <= 28 if p == "talent-first" else top >= 10)
        ok = (leg is None or leg >= 14) and top_ok and (tool is None or tool >= 14)
        ok9 &= ok
        rows.append(f"{p}: Legendary odds reach 50 % {fmt_d(leg)} (first rolled {fmt_d(s.legendary_t and s.legendary_t / DAY)}), top crop {fmt_d(top)}, "
                    f"last tool {fmt_d(tool)}")
    add("G9 scarcity (Casual)", ok9, "; ".join(rows))
    # EG a new egg costs >= 2 h (target 2-4 h median) of the buying archetype's income in the 24 h after its crop opens
    rows, okeg = [], True
    for egg, k in M["egg_opens"].items():
        price, hours, cells = M["eggs"][egg]["price"], [], []
        for n in names:
            s = sims[(n, "talent-first")]
            t0 = s.unlock_t.get(k)
            if t0 is None:
                cells.append(f"{n} -")
                continue
            inc = sum(c for tt, c in s.income_log if t0 <= tt < t0 + DAY)
            h = price / (inc / 24.0) if inc > 0 else float("inf")
            hours.append(h)
            bought = s.egg_bought.get(egg, 0)
            okeg &= h >= 2 or not bought
            cells.append(f"{n} day {t0 / DAY:.1f} {h:.1f} h ({bought} bought)")
        med = statistics.median(hours) if hours else None
        rows.append(f"{egg} {E.n(price)}: median {med and round(med, 1)} h; " + ", ".join(cells))
    add("EG new eggs cost >= 2 h of the opening day's income", okeg, "; ".join(rows))
    # B Tending pays
    rows, okb = [], True
    for n in ("Casual", "Garden main", "Obby main"):
        # crows off too: faster ripening leaves ripe crops longer in a long absence and unguarded crows eat them (a finding; B2 covers guards)
        a = run(M, arch_by(n), "talent-first", days, guards=False, crows=False)
        b = run(M, arch_by(n), "talent-first", days, tending=False, guards=False, crows=False)
        fa, fb = a.income["field"] + a.income["request"], b.income["field"] + b.income["request"]
        okb &= fa >= fb
        rows.append(f"{n} {fa / max(1, fb):.3f}x")
    add("B Tending pets earn more (no guards or crows in either run)", okb, "; ".join(rows))
    # B2 a guard pays: one field pet slot for the best guard instead of a tender
    a, b = sims[("Casual", "talent-first")], run(M, arch_by("Casual"), "talent-first", days, guard_first=True)
    fa, fb = a.income["field"] + a.income["request"], b.income["field"] + b.income["request"]
    add("B2 a guard pays (Casual, one slot guard-first)", fb >= fa, f"guard-first {fb / max(1, fa):.3f}x; crows take {E.n(a.crow_loss / days)} / day "
        f"without, {E.n(b.crow_loss / days)} with the guard")
    # C sink share
    rows, okc = [], True
    for n in names:
        s = sims[(n, "talent-first")]
        e30, s30 = sum(s.earned_by_day[:30]), sum(s.spent_by_day[:30])
        e60, s60 = sum(s.earned_by_day[:60]), sum(s.spent_by_day[:60])
        ok = s30 / max(1, e30) >= 0.6 and (days < 60 or s60 / max(1, e60) >= 0.78)
        okc &= ok
        rows.append(f"{n} {s30 / max(1, e30):.0%} / {s60 / max(1, e60):.0%}")
    add("C sinks absorb the faucet (day 30 / 60)", okc, "; ".join(rows))
    if M["mode"] == "stars":
        for r in ev3_checks(M, sims, names, days):
            add(*r)
    if verbose:
        for name, ok, text in res:
            print(f"{'PASS' if ok else 'FAIL'}  {name}: {text}")
        print(f"{sum(ok for _, ok, _ in res)} / {len(res)} EV checks pass")
    return res


POLICIES = ("talent-first", "pets-first")
_OLD = {}


def old_model():
    """The game as built (Renown gates), for EV3's old -> new comparisons."""
    if "M" not in _OLD:
        _OLD["M"] = build(dict(CAND, mode="renown"))
    return _OLD["M"]


def old_share(s, d0=3, d1=30):
    """Share of square-harvests on days d0..d1-1 that are crops >= 3 steps below the newest unlocked one (G11)."""
    h = [s.harv.get(d, [0, 0]) for d in range(d0, d1)]
    return sum(o for _, o in h) / max(1, sum(a for a, _ in h))


def w1_clears(M, s):
    """(stage key, minutes of the farm's online income) of a sim's Tutorial / World 1 first clears (G10)."""
    w1 = {st["key"] for st in M["stages"] if st["world"] <= 1}
    return [(k, v / r) for t, k, v, r in s.clear_log if k in w1 and r > 0]


def ev3_checks(M, sims, names, days):
    """G10-G12 and U (EV3a, bands provisional)."""
    out, c = [], M["c"]
    # G10 a first clear of the Tutorial / World 1 pays <= 3 min of the Casual farm's income (Coins + the seed pack at its seed price)
    mins = w1_clears(M, sims[("Casual", "talent-first")])
    ok = bool(mins) and all(m <= 3.0 for _, m in mins)
    rows = ["Casual " + ", ".join(f"{k} {m:.1f}" for k, m in mins)]
    for n in names:
        mm = w1_clears(M, sims[(n, "talent-first")]) if n != "Casual" else []
        if mm:
            k, m = max(mm, key=lambda x: x[1])
            rows.append(f"{n} at most {m:.1f} ({k})")
    out.append(("G10 a Tutorial / World 1 first clear <= 3 min of the farm (Casual)", ok, "; ".join(rows)))
    # G11 (revised 2026-11-17: the harvest share passed the Renown model too): days 3-30, >= 15 % of the crop levels earned are on crops
    # >= 3 steps below the newest unlocked one (old crops get levelled, not only planted); the harvest share is printed for reference
    rows, ok = [], True
    for n in names:
        s = sims[(n, "talent-first")]
        st = [(k, nw) for t, k, nw in s.star_newest if 3 * DAY <= t < 30 * DAY]
        sh = sum(1 for k, nw in st if k <= nw - 3) / len(st) if st else 0.0
        ok &= sh >= 0.15
        rows.append(f"{n} {sh:.0%} of {len(st)} levels (harvests {old_share(s):.0%})")
    out.append(("G11 old crops are levelled (days 3-30, >= 15 % of levels)", ok, "; ".join(rows)))
    # G12 the first crop fully upgraded not before day 7 (Garden main); Casual has >= 25 % of all stars still to earn on day 60
    gm, cas = sims[("Garden main", "talent-first")], sims[("Casual", "talent-first")]
    full = [(t / DAY, k) for t, k, L in gm.star_t if L == M["levels"]]
    total = len(M["crops"]) * M["levels"]
    earned = sum(1 for t, _, _ in cas.star_t if t < 60 * DAY)
    left = 1 - earned / total
    ok = (not full or full[0][0] >= 7) and (days < 60 or left >= 0.25)
    first = f"day {full[0][0]:.1f} ({cfg_id(M['crops'][full[0][1]]['id'])})" if full else "none"
    out.append(("G12 crop stars are a long goal", ok, f"Garden main first crop maxed {first}, {len(set(k for _, k in full))} maxed by day {days}; "
                f"Casual {earned} / {total} stars on day 60 ({left:.0%} left)"))
    # U a maxed crop matches a fresh crop 2-3 steps up (EV3 rule 2)
    mm = maxed_mult(c)
    steps = math.log(mm) / math.log(c["r"])
    tiers = "" if c["tier_of"] is None else f", {math.log(mm) / math.log(c['r_tier']):.2f} of a price tier"
    worst = min(maxed_mult(c, pts=p) for p in pt_allocations(c))
    wsteps = math.log(worst) / math.log(c["r"])
    out.append(("U maxed crop = a fresh crop 2-3 steps up (x1.2 ladder steps), however its points are spent",
                2 - 1e-9 <= wsteps and steps <= 3 + 1e-9,
                f"best x{mm:.2f} net per square-hour = {steps:.1f} steps{tiers}, worst x{worst:.2f} = {wsteps:.1f} steps (per point: Value "
                f"+{c['pt_value']:.0%}, Size +{c['pt_size']:.0%}, Speed -{c['pt_speed']:.0%}; {c['pt_total'] or 3 * c['pt_cap']} points, "
                f"up to {c['pt_cap']} per line)"))
    return out


def sq_name(goal):
    return goal


def fmt_d(x):
    return "-" if x is None else f"day {x:.1f}"


# The model's crop ids -> CropConfig ids (EV2a named the Future plants).
CFG_ID = {"FP1": "Lettuce", "FP2": "Onion", "FP3": "Garlic", "FP4": "Tomato", "FP5": "Cucumber", "FP6": "Pepper", "FP7": "Broccoli",
          "FP8": "Eggplant", "FP9": "Blueberry", "FP10": "SweetPotato", "FP11": "Sunflower", "FP12": "Pineapple"}


def cfg_id(model_id):
    return CFG_ID.get(model_id, model_id)


def config_match(M):
    """EV2a: the configs must carry the proposal (CAND) exactly; a list of differences (empty = equal)."""
    P, out = M["P"], []
    cc = P["crop_cfg"]
    cfg = {c[0]: c for c in cc["crops"]}
    C = M["c"]
    for c in M["crops"] + list(M["rares"].values()):  # EV3b: grow hours, sale, seed, step (the next crop's count), quest
        o = cfg.get(cfg_id(c["id"]))
        rare = c.get("rare")
        want = [c["t"] / 3600, round(c["sale"]), round(c["seed"]), None if rare else round(c["star1"]),
                None if rare or not c["quest"] else {cfg_id(k): n for k, n in c["quest"].items()}]
        have = None if o is None else [o[1], o[2], o[3], o[4], o[5]]
        if have is None or any(a != b if not isinstance(a, float) else abs(a - b) > 1e-6 for a, b in zip(want, have)):
            out.append(f"crop {cfg_id(c['id'])}: config {have} vs proposal {want}")
    levels, rest_day, rest_cap, _, pts, bands = cc["mastery"]
    if [list(levels), rest_day, rest_cap] != [list(C["m_levels"]), C["rest_per_day"], C["rest_cap"]]:
        out.append(f"mastery: config {[levels, rest_day, rest_cap]} vs proposal {[list(C['m_levels']), C['rest_per_day'], C['rest_cap']]}")
    want_bands = [[u, list(lv)] for u, lv in C.get("m_bands") or ()]  # FL: level counts by grow time
    if bands != want_bands:
        out.append(f"mastery bands (UpTo, Levels): config {bands} vs proposal {want_bands}")
    want_pts = [C["pt_value"], C["pt_size"], C["pt_speed"], C["pt_cap"]]  # EV3c: the size of a point per line, then the points per line
    total = C["pt_total"] or 3 * C["pt_cap"]
    if list(pts) != want_pts or total != len(levels):
        out.append(f"crop points (Value, Size, Speed, PerLine): config {list(pts)} vs proposal {want_pts} (proposal {total} points per "
                   f"crop, the game {len(levels)} levels)")
    want_stall = [C["st_every"], C["stall_staples"], C["st_p"], C["st_pity"], C["st_n"], C.get("st_long")]  # FL: + LongSeconds  # ST: the rotating stall (the game always has it)
    if not C["st"] or list(cc["stall"]) != want_stall or not C["st_newest"]:
        out.append(f"stall (Seconds, Staples, Chance, Pity, Count, LongSeconds): config {list(cc['stall'])} vs proposal {want_stall} (st {C['st']}, "
                   f"st_newest {C['st_newest']}: the game has both)")
    if cc["crows"][4] != cfg_id(C["crows_from"]) or cc["cart"][1][2] != cfg_id(C["crows_from"]):
        out.append(f"crows / cart taste from: config {cc['crows'][4]} / {cc['cart'][1][2]} vs proposal {cfg_id(C['crows_from'])}")
    for s in M["stages"]:  # EV3 rule 6: the Tutorial / World 1 first clears
        o = C["obby_first"].get(s["key"])
        want_fc = None if o is None else [o[0], o[1], cfg_id(o[2])]
        if s.get("first_clear") != want_fc:
            out.append(f"first clear {s['key']}: config {s.get('first_clear')} vs proposal {want_fc}")
    items = {it["name"]: it for it in M["items"]}
    def want(name):  # EV3b: sinks are priced in Coins alone (the model's `gate` is the Renown game, kept for the old-model tables)
        it = items.get(name)
        return None if it is None else round(it["price"])
    for i, price in enumerate(cc["expansions"]):
        if want(f"Square {5 + i}") != price:
            out.append(f"Square {5 + i}: config {price} vs proposal {want(f'Square {5 + i}')}")
    for uid, step, prices in cc["upgrades"]:
        for k, p in enumerate(prices):
            if want(f"{uid} {k + 1}") != p:
                out.append(f"{uid} {k + 1}: config {p} vs proposal {want(f'{uid} {k + 1}')}")
    for tid, eff, prices in cc["tools"]:
        for k, p in enumerate(prices):
            if want(f"{tid} {k + 1}") != p:
                out.append(f"{tid} {k + 1}: config {p} vs proposal {want(f'{tid} {k + 1}')}")
    for fam, prices in (("FieldSlot", cc["pet_slots"]), ("EquipSlot", P["slot_prices"]), ("Incubator", P["incubator_prices"])):
        for k, p in enumerate(prices[1:], start=2):
            w = want(f"{fam} {k}")
            if w != p:
                out.append(f"{fam} {k}: config {p} vs proposal {w}")
    for tid, levels in M["talents"].items():  # EV2b: Coins + crop bundle per level (world rewards: None)
        o = P["talents"].get(tid)
        if o is None or not o["built"]:
            continue
        for n, lv in enumerate(levels, start=1):
            if lv is None:
                continue
            want_crops = {cfg_id(M["crops"][k - 1]["id"]): c for k, c in lv["crops"].items()}
            want_crops.update({M["rares"][w]["id"]: c for w, c in lv["rare"].items()})
            have = [o["costs"][n - 1] if n <= len(o["costs"]) else None, o["crops"].get(n, {})]
            if have != [lv["price"], want_crops]:
                out.append(f"{tid} {n}: config {have} vs proposal {[lv['price'], want_crops]}")
    for k, e in M["eggs"].items():
        o = P["eggs"].get(k)
        if o is None or round(e["price"]) != o["price"] or {r: w for r, w in e["w"].items() if w} != {r: w for r, w in o["weights"].items() if w}:
            out.append(f"egg {k}: config {o and [o['price'], o['weights']]} vs proposal {[e['price'], e['w']]}")
        elif o.get("opens") != M["c"]["egg_opens"].get(k):
            out.append(f"egg {k}: config opensWith {o.get('opens')} vs proposal {M['c']['egg_opens'].get(k)}")
    if P["hatch_by_rarity"] != M["c"]["hatch"]:
        out.append(f"hatch times: config {P['hatch_by_rarity']} vs proposal {M['c']['hatch']}")
    return out


def proposal(M, days=60):
    """The proposal table (since EV2a the "config" columns show what the game's configs hold)."""
    P = M["P"]
    old_crops = {c[0]: c for c in P["crop_cfg"]["crops"]}
    print("## Crops (net = sale - seed; v = net Coins per square-hour of growth; Future plants are model-only)")
    rows = []
    for c in M["crops"] + list(M["rares"].values()):
        o = old_crops.get(cfg_id(c["id"]))
        old = f"{E.n(o[1] * 3600)} s / {E.n(o[2])} / {E.n(o[3])} / {o[4] if o[4] is not None else '-'}" if o else "-"
        rows.append([cfg_id(c["id"]), fmt_t(c["t"]), E.n(c["sale"]), E.n(c["seed"]), E.n(c["v"]), str(c["pts"]), f"R{c['gate']}", old])
    print(E.table(["crop", "grow", "sale", "seed", "net/sq-h", "Renown pts", "old gate", "config: grow / sale / seed / step"], rows))
    print(f"\nRenown (the old model only, EV3b took it out of the game): level L needs {M['c']['renown_k']} x L^{M['c']['renown_p']} points.")
    print("\n## Perennials (model-only)")
    print(E.table(["tree", "first growth", "fruit every", "held", "fruit sale"],
                  [[t["id"], fmt_t(t["t0"]), fmt_t(t["f"]), str(t["cap"]), E.n(t["fruit"])] for t in M["trees"].values()]))
    sims = {n: run(M, arch_by(n), "talent-first", days) for n in ("Casual", "Garden main", "Obby main", "Binge", "Spender")}
    old_prices = old_price_map(P)
    print("\n## Sinks and talents (day bought, talent-first policy; - = not within the run)")
    rows = []
    for it in sorted(M["items"], key=lambda it: (it["group"] == "reserved", it["price"])):
        if it["fam"] == "Reserved" and it["lvl"] > 3:
            continue
        bundle = ""
        if it["fam"] == "Talent":
            bundle = ", ".join(f"{n} {M['crops'][k - 1]['id']}" for k, n in it["crops"].items())
            bundle += "".join(f", {n} {M['rares'][w]['id']}" for w, n in it["rare_need"].items())
        days_s = [fmt_short(sims[n].buy_day.get(it["name"])) for n in sims]
        rows.append([it["name"], E.n(it["price"]), bundle, f"R{it['gate']}", old_prices.get(it["name"], "-")] + days_s)
    print("(columns per archetype: when it is bought; 'h' = hours on day 1, otherwise the day)")
    print(E.table(["item", "price", "crops", "gate", "config price"] + list(sims), rows))
    print("\n## Eggs (rolled at purchase; hatch time by rarity)")
    print(E.table(["egg", "price", "weights", "mean hatch", "config price / hatch"],
                  [[k, E.n(e["price"]), " ".join(f"{r[0]}{w}" for r, w in e["w"].items()), fmt_t(mean_hatch(M, e["w"])),
                    (f"{E.n(P['eggs'][k]['price'])} / {fmt_t(P['eggs'][k]['hatch_s'])}" if k in P["eggs"] else "- (model only)")]
                   for k, e in M["eggs"].items()]))
    print("hatch by rarity: " + ", ".join(f"{r} {fmt_t(s)}" for r, s in M["c"]["hatch"].items()))
    c = M["c"]
    print(f"\n## Obby\nrepeat medal finish: Sunshine {c['sun']} s (Bronze / Silver / Gold) x {c['sun_decay']}^n per stage and day, at least "
          f"{c['sun_floor']} s, stored up to {fmt_t(c['sun_cap'])}; repeat Coins 0 (old {P['rr_base']} x factor x medal x {P['rr_decay']}^n, floor {P['rr_floor']}).")
    print(f"Scouting: XP = timer seconds while equipped, level 1->2 in {c['scout_first_h']} h, x {c['scout_ratio']} per level; bonus min({c['scout_cap']}, "
          f"{c['scout_per']} x strength) on Sunshine, meter and pouch (old: {E.n(P['crop_cfg']['scouting'][0] * 60)} min per medal finish on the Tending curve).")
    print(f"Requests: {c['req_per_day']} a day, crops pay {c['req_mult']}x the sale, 1 in {round(1 / c['req_drop'])} also a drop; slot 3 a timed run "
          f"{c['req_run_share']:.0%} of days. Streak: Sunshine {c['streak_sun']} min, day 7 an Epic+ pet {c['streak_pet']}.")
    print("\n## Per archetype (talent-first, day %d)" % days)
    rows = []
    for n, s in sims.items():
        lvl = f"{sum(s.star.values())} stars" if s.stars_on else f"R{s.level}"
        rows.append([n, E.n(sum(s.earned_by_day[:days]) / days), f"{s.income['obby'] / max(1, sum(s.income.values())):.0%}", lvl,
                     str(s.open_sq), str(len(s.trees)), str(len(s.pets)), fmt_short(s.legendary_t / DAY if s.legendary_t else None), f"{s.mult:.2f}"])
    print(E.table(["archetype", "Coins / day", "obby share", "Renown / stars", "squares", "trees", "pets", "1st Legendary", "multiplier"], rows))
    if M["mode"] == "stars":
        ev3_tables(M, days)


def ev3_tables(M, days=60):
    """EV3a's output: crops old -> new (Renown gate -> star 1 / quest), each unlock's day per archetype old vs new, crop stars by day, the
    sinks that lose their gate, and the Tutorial / World 1 first clears."""
    c, OM = M["c"], old_model()
    names = ("Casual", "Garden main", "Obby main", "Binge")
    new = {n: run(M, arch_by(n), "talent-first", days) for n in names}
    old = {n: run(OM, arch_by(n), "talent-first", days) for n in names}
    L = M["levels"]
    cnt = c["mastery"] == "count"
    print("\n## EV3: crops, old -> new (" + ("levels in plants of that crop" if cnt else
          f"star 1 in square-harvests: XP = grow minutes; star {L} in square-hours of that crop") + ")")
    rows = []
    for cr in M["crops"]:
        k = cr["k"]
        if k == 0:
            how = "start crop"
        elif cr["quest"]:
            how = "quest: " + " + ".join(f"{q} {cfg_id(cid)}" for cid, q in cr["quest"].items())
        else:
            prev = M["crops"][k - 1]
            how = (f"{round(unlock_need(prev, c))} {cfg_id(prev['id'])}" if cnt and c["m_levels"]
                   else f"{cfg_id(prev['id'])} star 1")
        levels = " / ".join(E.n(star_need(cr, x, c)) for x in range(1, L + 1)) if cnt else E.n(star_need(cr, L, c) / 60.0)
        rows.append([cfg_id(cr["id"]), fmt_t(cr["t"]), str(cr["tier"] + 1), E.n(cr["seed"]), E.n(cr["sale"]), f"R{cr['gate']}", how,
                     levels])
    print(E.table(["crop", "grow", "tier", "seed", "sale", "old gate", "new: opens at",
                   "levels (plants)" if cnt else f"star {L} (sq-h)"], rows))
    policy = (f"Speed for crops up to {fmt_t(c['pt_fast'])}, else Value" if c["pt_order"] == "auto" else " > ".join(c["pt_order"]))
    print(f"Points: a star = 1 point, up to {c['pt_cap']} per line (Value +{c['pt_value']:.0%} sale, Size +{c['pt_size']:.0%} size factor, "
          f"Speed -{c['pt_speed']:.1%} grow time each; policy {policy}); maxed: net per square-hour x{maxed_mult(c):.2f} at best, "
          f"x{min(maxed_mult(c, pts=p) for p in pt_allocations(c)):.2f} at worst. Unlock bar policy: the newest crop on just enough squares while it earns >= {c['chase']} x the best.")
    print("\n## EV3: unlock day per archetype, old (Renown) -> new (stars); h = hours on day 0")
    rows = []
    for cr in M["crops"]:
        k = cr["k"]
        rows.append([cfg_id(cr["id"])] + [f"{fmt_short(old[n].unlock_t.get(k) and old[n].unlock_t[k] / DAY) if k else '0'} -> "
                                          f"{fmt_short(new[n].unlock_t.get(k) and new[n].unlock_t[k] / DAY) if k else '0'}" for n in names])
    print(E.table(["crop"] + list(names), rows))
    print(f"\n## EV3: crop stars by day (all crops; maxed = star {L})")
    rows = []
    for d in (1, 3, 7, 14, 30, 60):
        if d > days:
            continue
        cells = []
        for n in names:
            st = [(k, L) for t, k, L in new[n].star_t if t < d * DAY]
            best = {}
            for k, L in st:
                best[k] = L
            cells.append(f"{len(st)} stars, {sum(1 for L in best.values() if L == M['levels'])} maxed, {len(new[n].unlock_t)} open"
                         if d >= days else f"{len(st)} / {sum(1 for L in best.values() if L == M['levels'])} / "
                         f"{sum(1 for k, t in new[n].unlock_t.items() if t < d * DAY)}")
        rows.append([f"day {d}"] + cells)
    print("(stars earned / crops maxed / crops open)")
    print(E.table(["by"] + list(names), rows))
    print("\n## EV3: sinks on Coins alone (old Renown gates removed; prices unchanged)")
    fams = {}
    for it in M["items"]:
        if it["gate"] > 0:
            fams.setdefault(it["fam"], []).append(it["gate"])
    print(E.table(["family", "levels", "old gates"], [[f, str(len(g)), f"R{min(g)}-R{max(g)}"] for f, g in fams.items()]))
    print("\n## EV3: Tutorial / World 1 first clears (finish + medals; challenge coins unchanged); minutes of the farm's online income "
          "when the archetype clears it, old -> new")
    rows = []
    for st in M["stages"]:
        if st["world"] > 1:
            continue
        old_c = E.first_finish(M["P"], st) + E.stage_medal_total(M["P"], st)
        coins, pack, upto = first_clear_coins(M, st)
        cells = []
        for n in names:
            om = dict(w1_clears(OM, old[n])).get(st["key"])
            nm = dict(w1_clears(M, new[n])).get(st["key"])
            cells.append(f"{om:.1f} -> {nm:.1f}" if om is not None and nm is not None else "-")
        rows.append([st["key"], E.n(old_c), E.n(coins) + (f" + {pack} seeds (up to {cfg_id(upto)})" if pack else "")] + cells)
    print(E.table(["stage", "old", "new"] + list(names), rows))


def old_price_map(P):
    m = {}
    exps = P["crop_cfg"]["expansions"]
    for i, price in enumerate(exps):
        m[f"Square {5 + i}"] = E.n(price)
    for uid, step, prices in P["crop_cfg"]["upgrades"]:
        for k, p in enumerate(prices):
            m[f"{uid} {k + 1}"] = E.n(p)
    for tid, eff, prices in P["crop_cfg"]["tools"]:
        for k, p in enumerate(prices):
            m[f"{tid} {k + 1}"] = E.n(p)
    for k, p in enumerate(P["crop_cfg"]["pet_slots"]):
        m[f"FieldSlot {k + 1}"] = E.n(p)
    for k, p in enumerate(P["slot_prices"]):
        m[f"EquipSlot {k + 1}"] = E.n(p)
    for k, p in enumerate(P["incubator_prices"]):
        m[f"Incubator {k + 1}"] = E.n(p)
    for tid, t in P["talents"].items():
        for k, p in enumerate(t["costs"]):
            m[f"{tid} {k + 1}"] = E.n(p) + ("" if t["built"] else " (P)")
    return m


def mean_hatch(M, w):
    tot = sum(w.values())
    return sum(M["c"]["hatch"][r] * x for r, x in w.items()) / tot


def fmt_t(s):
    if s < 60:
        return f"{s:.0f} s"
    if s < 3600:
        return f"{s / 60:.0f} m"
    return f"{s / 3600:.0f} h" if (s / 3600).is_integer() else f"{s / 3600:.1f} h"


def fmt_short(d):
    return "-" if d is None else (f"{d * 24:.1f}h" if d < 1 else f"{d:.1f}")


def main(argv):
    cmd = argv[0] if argv else "evcheck"
    days = 60
    over = {}
    for i, a in enumerate(argv):
        if a == "--days":
            days = int(argv[i + 1])
        if a == "--seed":
            SEED[0] = int(argv[i + 1])
        if a == "--set":  # a probe: --set key=python-literal (e.g. --set "mastery='count'")
            k, v = argv[i + 1].split("=", 1)
            over[k] = ast.literal_eval(v)
    unknown = [k for k in over if k not in CAND]
    if unknown:
        print(f"unknown CAND keys: {unknown}")
        return 2
    M = build(dict(CAND, **over))
    if cmd in ("evcheck", "ev"):
        res = checks(M, days)
        return 0 if all(ok for _, ok, _ in res) else 1
    if cmd == "proposal":
        proposal(M, days)
        print()
        res = checks(M, days)
        return 0
    if cmd == "hour1":
        print(first_hour(M))
        return 0
    print("usage: economy_ev.py evcheck | proposal | hour1 [--days N]")
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
