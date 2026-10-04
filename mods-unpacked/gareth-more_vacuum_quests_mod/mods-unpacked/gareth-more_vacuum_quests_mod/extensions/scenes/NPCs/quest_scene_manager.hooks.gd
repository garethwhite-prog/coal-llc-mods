extends Object

const QUEST_POINT_SCENE = preload("res://scenes/NPCs/quest_point.tscn")
const CUST_REWARD_SCRIPT = preload("res://mods-unpacked/gareth-more_vacuum_quests_mod/scripts/custom_vacuum_reward.gd")

func _ready(chain: ModLoaderHookChain) -> void:
	chain.execute_next([])
	var qsm := chain.reference_object as QuestSceneManager
	if not qsm:
		return
	_setup_extended_mermaid_quests(qsm)

func refresh_all_quest_points(chain: ModLoaderHookChain) -> void:
	var qsm := chain.reference_object as QuestSceneManager
	if qsm:
		_setup_extended_mermaid_quests(qsm)
	chain.execute_next([])

func _setup_extended_mermaid_quests(qsm: QuestSceneManager) -> void:
	var qm := Gvars.quest_manager
	var bem := Gvars.bonus_equipment_manager
	if not qm or not bem:
		return

	# 1. Initialize quest entries in QuestManager
	var custom_ids := [100, 101, 102, 103]
	for q_id in custom_ids:
		if not qm.quests.has(q_id):
			qm.quests[q_id] = {
				"state": QuestManager.States.UNAVAILABLE_CHAIN,
				"count_so_far": 0
			}

	# 2. Check Diamond completion
	var diamond_done := false
	if qm.quests.has(QuestManager.Quests.MERMAID_05):
		diamond_done = (qm.quests[QuestManager.Quests.MERMAID_05]["state"] == QuestManager.States.COMPLETE)

	if int(bem.current_vacuum) >= 4 or diamond_done:
		if qm.quests[100]["state"] == QuestManager.States.UNAVAILABLE_CHAIN:
			qm.quests[100]["state"] = QuestManager.States.AVAILABLE

	# 3. Synchronize with bonus shop purchases
	if int(bem.current_vacuum) >= 5:
		qm.quests[100]["state"] = QuestManager.States.COMPLETE
		if qm.quests[101]["state"] == QuestManager.States.UNAVAILABLE_CHAIN:
			qm.quests[101]["state"] = QuestManager.States.AVAILABLE
	if int(bem.current_vacuum) >= 6:
		qm.quests[101]["state"] = QuestManager.States.COMPLETE
		if qm.quests[102]["state"] == QuestManager.States.UNAVAILABLE_CHAIN:
			qm.quests[102]["state"] = QuestManager.States.AVAILABLE
	if int(bem.current_vacuum) >= 7:
		qm.quests[102]["state"] = QuestManager.States.COMPLETE
		if qm.quests[103]["state"] == QuestManager.States.UNAVAILABLE_CHAIN:
			qm.quests[103]["state"] = QuestManager.States.AVAILABLE
	if int(bem.current_vacuum) >= 8:
		qm.quests[103]["state"] = QuestManager.States.COMPLETE

	# 4. Locate Tabatha (MermaidNPC)
	var tree := qsm.get_tree()
	var mermaid: NPC = null
	for node in tree.get_nodes_in_group("npcs"):
		if node is NPC and node.name == "MermaidNPC":
			mermaid = node
			break
	if not mermaid:
		for node in tree.get_nodes_in_group("quest_points"):
			if node is QuestPoint and node.quest_giver and node.quest_giver.name == "MermaidNPC":
				mermaid = node.quest_giver
				break

	if not mermaid:
		return

	var quests_node := mermaid.get_parent().get_node_or_null("../Quests")
	if not quests_node:
		quests_node = mermaid.get_parent()

	# 5. Inject QuestPoints
	_build_quest_point(qsm, quests_node, mermaid, 100, 5, 101,
		"res://resources/Items/Gems/Uranium.tres", 60,
		"RADIOACTIVE SHINES !!! I NEED 60 URANIUM GEMS PLEASE !!! I WILL MAKE YOUR VACUUM EVEN LONGER TO REACH DEEP GREEN ROCKS !!!",
		"WAHOO !!! SPARKLY AND DANGEROUS !!! YOUR VACUUM REACHES 220 TILES DEEP NOW !!!")

	_build_quest_point(qsm, quests_node, mermaid, 101, 6, 102,
		"res://resources/Items/Gems/Moonstone.tres", 75,
		"CAN YOU BRING ME 75 MOONSTONES PLEASE ??? SHINY BLUE GLOW WILL POWER A SUPER VACUUM FOR DEEP CAVERNS !!!",
		"WAHOO !!! MOON MAGIC POWERS YOUR HOSE !!! NOW YOU CAN REACH 300 TILES DEEP !!!")

	_build_quest_point(qsm, quests_node, mermaid, 102, 7, 103,
		"res://resources/Items/Gems/Onyx.tres", 100,
		"BLACK AS NIGHT !!! BRING ME 100 ONYX GEMS PLEASE !!! ALMOST AT THE CORE OF THE EARTH !!!",
		"WAHOO !!! IT'S SO HEAVY AND STRONG !!! VACUUM REACH EXTENDED TO 420 TILES !!!")

	_build_quest_point(qsm, quests_node, mermaid, 103, 8, -1,
		"res://resources/Items/Gems/PinkDiamond.tres", 150,
		"ULTIMATE CHALLENGE !!! 150 PINK DIAMONDS FOR THE LEGENDARY ABYSSAL VACUUM !!! REACH THE VERY BOTTOM OF THE WORLD !!!",
		"UNBELIEVABLE !!! THE ULTIMATE VACUUM IS YOURS !!! 600 TILES OF RAW SUCTION POWER !!! THANK YOU BEST FRIEND !!!")

func _build_quest_point(qsm: QuestSceneManager, parent_node: Node, mermaid: NPC, q_id: int, target_lvl: int, next_q: int, gem_path: String, count_req: int, start_txt: String, end_txt: String) -> void:
	var qp_name := "QuestPointTabatha%d" % (q_id - 94)
	if parent_node.has_node(qp_name):
		return

	var qp: QuestPoint = QUEST_POINT_SCENE.instantiate()
	qp.name = qp_name
	qp.quest = q_id
	qp.quest_giver = mermaid
	qp.quest_start_dialogue = start_txt
	qp.quest_complete_dialogue = end_txt
	qp.quest_item = load(gem_path)
	qp.count_required = count_req

	var rew = CUST_REWARD_SCRIPT.new()
	rew.target_vacuum_level = target_lvl
	rew.next_quest_id = next_q
	qp.quest_reward = rew

	var qm = Gvars.quest_manager
	if qm and qm.quests.has(q_id):
		qp.state = qm.quests[q_id]["state"]
		qp.count_so_far = qm.quests[q_id]["count_so_far"]
	else:
		qp.state = QuestManager.States.UNAVAILABLE_CHAIN
		qp.count_so_far = 0

	parent_node.add_child(qp)
	qp.add_to_group("quest_points")
	qsm.all_quest_points[q_id] = qp
	mermaid.no_dialogue_left.connect(qp.interact_with_quest)
	qp.refresh_state()