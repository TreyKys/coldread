extends Node
## Centralized colors and styling for different districts.

const DISTRICTS = {
	"market_mile": {
		"light_color": Color(1.0, 0.9, 0.8),    # Sunset / dusk
		"light_energy": 1.0,
		"floor_color": Color(0.15, 0.12, 0.1),
		"wall_color": Color(0.25, 0.18, 0.15),
		"fog_color": Color(0.3, 0.2, 0.1, 1.0),
		"fog_density": 0.01,
		"bg_color": Color(0.1, 0.05, 0.05),
		"low_obs": Color("#8B4513"),            # Crate brown
		"high_obs": Color(0.9, 0.8, 0.2),       # Awning yellow
		"scenery": Color(0.4, 0.3, 0.25)
	},
	"the_stacks": {
		"light_color": Color(0.6, 0.9, 0.7),    # Night time, green traffic lights
		"light_energy": 0.6,
		"floor_color": Color(0.08, 0.1, 0.12),
		"wall_color": Color(0.1, 0.15, 0.18),
		"fog_color": Color(0.1, 0.2, 0.15, 1.0),
		"fog_density": 0.02,
		"bg_color": Color(0.02, 0.04, 0.05),
		"low_obs": Color(0.2, 0.4, 0.3),        # Dark green/cyan metallic
		"high_obs": Color(0.8, 0.1, 0.1),       # Red neon signs
		"scenery": Color(0.15, 0.2, 0.25)
	},
	"portside": {
		"light_color": Color(0.6, 0.7, 0.9),    # Dawn, rain, overcast
		"light_energy": 0.7,
		"floor_color": Color(0.1, 0.12, 0.15),
		"wall_color": Color(0.2, 0.25, 0.3),
		"fog_color": Color(0.4, 0.5, 0.6, 1.0),
		"fog_density": 0.03,
		"bg_color": Color(0.05, 0.08, 0.1),
		"low_obs": Color(0.3, 0.35, 0.4),       # Grey crates
		"high_obs": Color(0.8, 0.4, 0.1),       # Orange containers
		"scenery": Color(0.2, 0.3, 0.4)
	}
}

func get_district(id: String) -> Dictionary:
	if DISTRICTS.has(id):
		return DISTRICTS[id]
	return DISTRICTS["market_mile"]

func apply_environment(env: Environment, light: DirectionalLight3D, district_id: String) -> void:
	var d = get_district(district_id)
	
	if light:
		light.light_color = d["light_color"]
		light.light_energy = d["light_energy"]
		
	if env:
		env.background_mode = Environment.BG_COLOR
		env.background_color = d["bg_color"]
		env.fog_enabled = true
		env.fog_light_color = d["fog_color"]
		env.fog_density = d["fog_density"]
