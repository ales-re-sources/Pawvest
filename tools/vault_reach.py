"""2D reachability model of the Stage 14 Key Vault (u = -213 - x, h = y - 78; docs/STAGES.md -> "Vault lanes").
Unified BFS over (u, feet h, vh, air jumps left, dash available, dash phase) with dominance pruning: optimal play
within the talents of a profile ("max": Jump Height 3 + Run Speed 5, slim body, 2-stud ledge snap = shortcut hunting;
"base": Triple Jump + Long Dash only, wide body = feasibility). Jump rises are the measured ones (7.29 / 9.03 per
jump; a Triple Jump 21.8 / 27.0). Prints which targets are reachable and the landing chain of the first (fastest)
path to each. One run takes 1-3 minutes; run variants in parallel. Re-run after moving any vault part.
RIGHT=1 models the right half (green key, the ledge tower): see solids_right(); tools/vault_right_checks.sh runs its checks."""
import sys, os, math
from collections import deque

G = 196.2
DT = 1 / 60
DECIDE = 3  # decide every 3 physics steps (0.05 s)

def solids():
    """The vault as built on 2026-10-28 (Floor_9 and the teal gate on Pillar_Lock after the first playtest) (docs/STAGES.md -> "Vault lanes"). (u0, u1, h0, h1) boxes; lane z ignored.
    Env flags: B1 / B2 = "open" ghosts a switch barrier, POST = 1 is the state after the teal key (hatches open, the
    barrier behind the key shut, the dash corridor plugged so any way to the right floor that remains skips it),
    DROP = comma list of solids to remove (e.g. Block_Top2: is the stepping stone needed?)."""
    TOP = 98.0
    S = {
        "Floor": (40, 240, -4, 0),
        "Ceiling": (100.7, 220, 64, 68),
        "CeilingTall": (40, 100.7, TOP, TOP + 4),
        "WallLeft": (36, 44, 8, TOP),  # door below h 8
        "WallRightUpper": (216, 220, 8, 64),
        "RightWall": (96.82, 100.7, 32.8, TOP),
        "LedgeL1": (44.1, 48.0, 20.4, 24.3),
        "LedgeL2": (44.1, 48.0, 30.8, 32.5),
        "PlatformA": (64.4, 96.8, 15.4, 19.2),
        "PlatformB": (68.5, 96.8, 32.8, 36.6),
        "PlatformB_LegL": (68.5, 72.5, 28.6, 32.8),
        "PlatformB_LegR": (84.9, 88.7, 28.6, 32.8),
        "Lid": (68.5, 84.0, 46.0, 48.0),
        "Block_Top2": (85.0, 91.0, 48.74, 52.6),
        "Block_Top1": (71.0, 77.0, 64.74, 68.6),
        "Block_Float1": (105.2, 109.1, 8.3, 12.1),
        "Block_Float2": (121.4, 129.3, 4.2, 8.1),
        "Pillar_Lock": (154.0, 157.8, 0, 12.1),
        "Gate_Teal": (154.9, 156.9, 12.14, 64),  # on top of Pillar_Lock
        "Hatch_Low": (44.0, 64.4, 15.4, 19.2),
        "Hatch_High": (44.0, 68.5, 46.0, 48.0),
        "Bar_Lane1": (90.5, 91.5, 19.2, 32.8),
        "Bar_Lane2": (76.0, 77.0, 36.6, 46.0),
    }
    K = {  # KitKill hit boxes
        "Hang_7": (69.6, 71.4, 26.6, 28.6),
        "Hang_8": (85.9, 87.7, 26.6, 28.6),
        "Top1_9": (71.6, 73.0, 68.6, 69.9),
        "Top2_10": (85.6, 87.0, 52.6, 54.0),
        "Float2_11": (121.8, 123.0, 8.1, 9.0),
        "PlatA_Big_5": (77.6, 79.8, 19.2, 21.6),
        "PlatA_Tiny_6": (93.3, 94.5, 19.2, 20.1),
        "Floor_1": (85.7, 87.8, 0, 2.1),
        "Floor_2": (89.7, 91.9, 0, 2.1),
        "Floor_3": (93.8, 96.0, 0, 2.1),
        "Floor_4": (97.9, 100.1, 0, 2.1),
        "Floor_9": (81.7, 83.8, 0, 2.1),
        "LidKill": (68.5, 84.0, 48.0, 48.5),
        "HatchKill": (44.0, 68.5, 48.0, 48.5),
    }
    T = {  # touch targets: pickups and the two switch pads
        "Key_Teal": (58.0, 65.0, 88.0, 94.0),
        "Coin_2": (85.8, 88.2, 38.8, 41.2),
        "Switch_Lane1": (125.7, 129.3, 8.1, 8.6),
        "Switch_Lane2": (44.1, 48.0, 32.5, 33.0),
    }
    if os.environ.get("B1") == "open":
        del S["Bar_Lane1"]
    if os.environ.get("B2") == "open":
        del S["Bar_Lane2"]
    if os.environ.get("POST") == "1":
        for n in ("Hatch_Low", "Hatch_High", "Gate_Teal", "Pillar_Lock"):
            del S[n]
        del K["HatchKill"]
        S["Gate_TealBehind"] = (96.82, 98.82, 19.2, 32.8)
        S["CorridorPlug"] = (83.0, 101.0, 0.0, 15.4)
        T = {"RightFloor": (101.5, 158.0, 0.0, 3.0)}
    for n in filter(None, os.environ.get("DROP", "").split(",")):
        S.pop(n, None)
    return S, K, T


# Right half (green key), docs/STAGES.md -> "Vault tower": a switchback of six ledges, hung alternately from RightMass
# (right, gap at the left end) and from the E's stem (left, gap at the right end), 9.5 studs apart (7.5 headroom: a
# ledge-up is a double jump through the gap, a ledge's spike a jump + Long Dash), so every ledge roofs the lane below
# except at its gap; an even count puts the top ledge on the stem side, flush with the stem's top. The top lane (8 high
# under the ceiling) also has a spike hanging from the ceiling (walk under it). Then the slot between E_Bar and the stem,
# the key in a notch of E_Bar at the slot floor, and a green hatch as the slot floor (with the bottom spike on it) that
# opens once the key is held (the way back down). The room is 65 high (ceiling h 65-69), the left half's ceiling 64.
TOWER_LEFT, TOWER_RIGHT, TOWER_GAP = 174.2, 200.2, 5.0
CEIL_U = float(os.environ.get("CEIL_U", 189.0))  # left edge of Ceiling_21's hit
TOWER_LEDGES = [  # (name, top, attached side); thickness 2
    ("Block_Right2", 9.5, "R"),
    ("Block_Right1", 19.0, "L"),
    ("Slab_Step", 28.5, "R"),
    ("Base_L", 38.0, "L"),
    ("Column_1", 47.5, "R"),
    ("E_ArmTop", 57.0, "L"),
]


def ledge_box(top, side):
    if side == "L":
        return (TOWER_LEFT, TOWER_RIGHT - TOWER_GAP, top - 2, top)
    return (TOWER_LEFT + TOWER_GAP, TOWER_RIGHT, top - 2, top)


def gap_box(top, side):
    if side == "L":
        return (TOWER_RIGHT - TOWER_GAP, TOWER_RIGHT, top - 2, top)
    return (TOWER_LEFT, TOWER_LEFT + TOWER_GAP, top - 2, top)


def solids_right():
    """Env: PLUG = k (fill the gap of ledge k, 1-6: is that lane needed?), HATCH = open (the key is held).
    Targets: Key_Green, SlotFloor (standing left of the bottom spike), LockZone_Green, onK_<ledge> (standing on ledge k)."""
    S = {
        "Floor": (148, 240, -4, 0),
        "ModelBound": (146, 148, 0, 69),
        "OldCeiling": (148, 157.8, 64, 68),  # the left half's ceiling; Pillar_Lock / Gate_Teal are open by now
        "E_BarLower": (157.8, 162.0, 7.5, 41),
        "E_BarNotchBack": (157.8, 159.0, 41, 45.5),
        "E_Bar": (157.8, 162.0, 45.5, 65),
        "E_Stem": (172.2, 174.2, 7.5, 57),  # 2 thick: the slot is 10.2 wide
        "SlotHatch": (162.0, 172.2, 39, 41),  # the whole slot floor; EBottom_18 stands on it and goes with it
        "RightMass": (200.2, 216, 7.5, 65),
        "WallRightUpper": (216, 220, 8, 65),
        "Gate_Green": (216, 220, 0, 8),
        "Ceiling": (157.8, 220, 65, 69),
    }
    K = {  # one spike in the middle of the walk along every ledge, one hanging in the top lane, two in the slot
        "Right2_13": (187.30, 188.86, 9.50, 10.89),
        "Right1_12": (182.30, 183.86, 19.00, 20.33),
        "Slab_23": (187.30, 188.86, 28.50, 29.89),
        "BaseTiny_15": (182.30, 183.50, 38.00, 38.90),
        "Column1_19": (187.30, 188.50, 47.50, 48.43),
        "ArmTop_24": (182.30, 183.50, 57.00, 57.90),
        "Ceiling_21": (CEIL_U, CEIL_U + 1.46, 63.46, 65.00),  # the old spike at 0.7 scale: a walking head passes under its tip
        "EBarSide_22": (161.97, 162.87, 55.60, 56.80),
        "EBottom_18": (166.80, 168.13, 41.00, 42.39),
    }
    T = {
        "Key_Green": (159.0, 162.4, 41, 45.5),
        "SlotFloor": (162.0, 166.8, 41, 41.3),
        "LockZone_Green": (206.0, 216.0, 0.0, 14.0),
    }
    for i, (name, top, side) in enumerate(TOWER_LEDGES):
        S[name] = ledge_box(top, side)
        T[f"on{i + 1}_{name}"] = (S[name][0], S[name][1], top, top + 0.3)
    if os.environ.get("PLUG"):
        k = int(os.environ["PLUG"])
        name, top, side = TOWER_LEDGES[k - 1]
        S[f"Plug{k}"] = gap_box(top, side)
    if os.environ.get("HATCH") == "open":
        del S["SlotHatch"]
        del K["EBottom_18"]
    for name in filter(None, os.environ.get("DROP", "").split(",")):
        S.pop(name, None)
    return S, K, T


class Model:
    def __init__(self, S, K, T, rise_per_jump, walk, dash_time, half_w, height, step):
        self.S, self.K, self.T = S, K, T
        self.v0 = math.sqrt(2 * G * rise_per_jump)
        self.walk = walk
        self.dash_steps = round(dash_time / DT)
        self.w = half_w
        self.hgt = height
        self.step = step

    def overlap(self, u, h, r):
        return u + self.w > r[0] and u - self.w < r[1] and h + self.hgt > r[2] and h < r[3]

    def blocked(self, u, h):
        for n, r in self.S.items():
            if self.overlap(u, h, r):
                return n
        return None

    def killed(self, u, h):
        for n, r in self.K.items():
            if self.overlap(u, h, r):
                return n
        return None

    def support(self, u, h):
        # part whose top is at h (within 0.05) under the body
        for n, r in self.S.items():
            if abs(r[3] - h) < 0.06 and u + self.w > r[0] and u - self.w < r[1]:
                return n
        return None

    def move(self, u, h, vu, vh):
        """one physics step; returns (u, h, vh, landed_on or None, dead)"""
        # horizontal
        nu = u + vu * DT
        if self.blocked(nu, h):
            # step-up: a top within self.step above the feet
            stepped = False
            for dh in (0.25, 0.5, 1.0, 1.5, 2.0):
                if dh > self.step:
                    break
                if not self.blocked(nu, h + dh):
                    h = h + dh
                    stepped = True
                    break
            if not stepped:
                nu = u
            elif self.killed(nu, h - 0.25):
                return nu, h, 0.0, None, "step-kill"
        u = nu
        # vertical
        nvh = vh - G * DT
        nh = h + vh * DT
        landed = None
        if vh * DT < 0 or nh < h:
            b = self.blocked(u, nh)
            if b:
                top = self.S[b][3]
                if not self.blocked(u, top):
                    nh, nvh, landed = top, 0.0, b
                else:
                    nh, nvh = h, 0.0
        else:
            b = self.blocked(u, nh)
            if b:
                nh, nvh = h, 0.0  # bonk
        k = self.killed(u, nh)
        return u, nh, nvh, landed, k


def run(model, start, targets, max_states=int(os.environ.get("MAX_STATES", 4_000_000))):
    """BFS. State: (u, h, vh, jumps, dash_avail, dash_rem, dash_dir, grounded)."""
    q = deque()
    seen = {}
    parent = {}
    first_hit = {}
    reached_parts = {}

    def key(s):
        u, h, vh, j, da, dr, dd, g = s
        return (round(u * 2), round(h * 2), 0 if g else round(vh / 3), dr, dd)

    def dominated(s):
        k = key(s)
        best = seen.get(k)
        cand = (s[3], s[4])
        if best:
            for b in best:
                if b[0] >= cand[0] and b[1] >= cand[1]:
                    return True
            best[:] = [b for b in best if not (cand[0] >= b[0] and cand[1] >= b[1])] + [cand]
        else:
            seen[k] = [cand]
        return False

    u0, h0 = start
    s0 = (u0, h0, 0.0, 2, 1, 0, 0, True)
    dominated(s0)
    q.append(s0)
    parent[s0] = (None, "start")
    n = 0
    while q:
        s = q.popleft()
        n += 1
        if n > max_states:
            print("state cap hit")
            break
        u, h, vh, j, da, dr, dd, g = s
        for name, r in targets.items():
            if name not in first_hit and model.overlap(u, h, r):
                first_hit[name] = s
        if g:
            sup = model.support(u, h)
            if sup and sup not in reached_parts:
                reached_parts[sup] = s
        # options
        opts = []
        if dr > 0:
            opts.append(("dash", dd, 0, 0))
        else:
            for d in (-1, 0, 1):
                if g:
                    opts.append(("walk", d, 0, 0))
                    opts.append(("jump", d, 0, 0))
                else:
                    opts.append(("air", d, 0, 0))
                    if j > 0:
                        opts.append(("ajump", d, 0, 0))
                    if da and d != 0:
                        opts.append(("dash0", d, 0, 0))
        for kind, d, _, _ in opts:
            cu, ch, cvh, cj, cda, cdr, cdd, cg = u, h, vh, j, da, dr, dd, g
            if kind == "jump":
                cvh, cg = model.v0, False
            elif kind == "ajump":
                cvh, cj = model.v0, j - 1
            elif kind == "dash0":
                cda, cdr, cdd = 0, model.dash_steps, d
            dead = None
            for _ in range(DECIDE):
                if cdr > 0:
                    vu, cvh_use = 50 * cdd, 0.0
                    nu = cu + vu * DT
                    if model.blocked(nu, ch):
                        nu = cu
                    cu = nu
                    cdr -= 1
                    cvh = 0.0
                    if cdr == 0:
                        cvh = 0.0
                    k = model.killed(cu, ch)
                    if k:
                        dead = k
                        break
                    continue
                vu = d * model.walk if cdr == 0 else 0
                if cg:
                    nu = cu + vu * DT
                    b = model.blocked(nu, ch)
                    if b:
                        stepped = False
                        for dh in (0.25, 0.5, 1.0, 1.5, 2.0):
                            if dh > model.step:
                                break
                            if not model.blocked(nu, ch + dh):
                                ch += dh
                                stepped = True
                                break
                        if not stepped:
                            nu = cu
                    cu = nu
                    if not model.support(cu, ch):
                        # walked off: falling, keeps air jumps (coyote double jump)
                        cg, cvh, cj = False, 0.0, 2
                    k = model.killed(cu, ch)
                    if k:
                        dead = k
                        break
                    continue
                cu, ch, cvh, landed, k = model.move(cu, ch, vu, cvh)
                if k:
                    dead = k
                    break
                if landed:
                    cg, cvh, cj, cda, cdr = True, 0.0, 2, 1, 0
                    break
                if ch < -1:
                    dead = "fell"
                    break
            if dead:
                continue
            ns = (round(cu, 3), round(ch, 3), round(cvh, 2), cj, cda, cdr, cdd if cdr else 0, cg)
            if dominated(ns):
                continue
            parent[ns] = (s, kind)
            q.append(ns)
    return first_hit, reached_parts, parent, n


def chain(model, parent, s):
    """landing chain: parts stood on along the path"""
    out = []
    while s is not None:
        p, kind = parent.get(s, (None, "?"))
        u, h, vh, j, da, dr, dd, g = s
        if g:
            sup = model.support(u, h) or "?"
            if not out or out[-1][0] != sup:
                out.append((sup, round(u, 1)))
        s = p
    return list(reversed(out))


PROFILES = {
    # name: rise per jump, walk speed, dash time, half width, height, step
    "max": (9.0, 20.8, 0.32, 0.6, 5.0, 2.0),   # Jump Height 3, Run Speed 5, Long Dash, slim body, generous step-up
    "base": (7.27, 16.0, 0.32, 1.0, 5.2, 1.0),  # TJ + Long Dash only, wide body, small step-up
}

if __name__ == "__main__":
    # python tools/vault_reach.py [profile=max|base] [start u] [start h] [part ...]  (env flags: see solids())
    prof = sys.argv[1] if len(sys.argv) > 1 else "max"
    start = (float(sys.argv[2]) if len(sys.argv) > 2 else 46.0, float(sys.argv[3]) if len(sys.argv) > 3 else 0.0)
    S, K, T = solids_right() if os.environ.get("RIGHT") == "1" else solids()
    m = Model(S, K, T, *PROFILES[prof])
    hits, parts, parent, n = run(m, start, T)
    flags = " ".join(f"{k}={os.environ[k]}" for k in ("B1", "B2", "POST", "DROP", "RIGHT", "PLUG", "HATCH") if os.environ.get(k))
    print(f"profile={prof} start={start} {flags} states={n}")
    for name in T:
        if name in hits:
            print(f"  {name}: REACHED via", " > ".join(f"{p}@{u}" for p, u in chain(m, parent, hits[name])))
        else:
            print(f"  {name}: not reached")
    print("  parts stood on:", ", ".join(sorted(parts)))
    for p in sys.argv[4:]:
        if p in parts:
            print(f"  first path onto {p}:", " > ".join(f"{a}@{u}" for a, u in chain(m, parent, parts[p])))
