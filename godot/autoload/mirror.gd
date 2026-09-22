extends Node
## The Mirror — records how the player plays across the whole game.
##
## Ported from the greybox `S.mirror`. This is load-bearing for the Act 3
## payoff: the villain (Ada Voss) leans her route AI away from these habits
## and quotes the real numbers back at the player ("You block bridges first.
## Seven times out of ten.").
##
## RULE for anyone extending the game: every new mechanic that involves a
## player choice of *how* (not just whether) must call one of the record_*
## methods below. If a Case 4-10 mechanic doesn't feed the Mirror, Act 3
## lands hollow. See BUILD_PLAN.md § The Mirror.

# roadblock placement, by route kind
var roadblocks := {"bridge": 0, "back": 0, "highway": 0, "docks": 0}
# search style
var smashed := 0   # smashed everything (brute force)
var precise := 0   # worked precisely (few taps)
# decisions
var hesitate := 0  # let a choice timer run out
# movement bias
var swipe := {"left": 0, "right": 0, "up": 0, "down": 0}
# which squad abilities the player leans on, by ability id (nitro/trace/eye/ram/hold/...)
var abilities := {}

func record_block(kind: String) -> void:
	if roadblocks.has(kind):
		roadblocks[kind] += 1
	else:
		roadblocks[kind] = 1

func record_search(did_smash_everything: bool) -> void:
	if did_smash_everything:
		smashed += 1
	else:
		precise += 1

func record_hesitation() -> void:
	hesitate += 1

func record_swipe(dir: String) -> void:
	if swipe.has(dir):
		swipe[dir] += 1

func record_ability(id: String) -> void:
	abilities[id] = int(abilities.get(id, 0)) + 1

## The profile Ada uses in Act 3, and the debrief shows from Case 3 on.
func profile() -> Dictionary:
	var favourite_block := "bridge"
	var best := -1
	for k in roadblocks:
		if roadblocks[k] > best:
			best = roadblocks[k]
			favourite_block = k
	var swipe_bias := "right" if swipe["right"] >= swipe["left"] else "left"
	return {
		"favourite_block": favourite_block,
		"smash_vs_precise": [smashed, precise],
		"hesitations": hesitate,
		"swipe_bias": swipe_bias,
		"roadblocks": roadblocks.duplicate(),
		"abilities": abilities.duplicate(),
	}

func to_dict() -> Dictionary:
	return {
		"roadblocks": roadblocks.duplicate(),
		"smashed": smashed,
		"precise": precise,
		"hesitate": hesitate,
		"swipe": swipe.duplicate(),
		"abilities": abilities.duplicate(),
	}

func from_dict(d: Dictionary) -> void:
	roadblocks = d.get("roadblocks", roadblocks)
	smashed = int(d.get("smashed", 0))
	precise = int(d.get("precise", 0))
	hesitate = int(d.get("hesitate", 0))
	swipe = d.get("swipe", swipe)
	abilities = d.get("abilities", {})

func reset() -> void:
	roadblocks = {"bridge": 0, "back": 0, "highway": 0, "docks": 0}
	smashed = 0
	precise = 0
	hesitate = 0
	swipe = {"left": 0, "right": 0, "up": 0, "down": 0}
	abilities = {}
