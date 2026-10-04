extends Object

func adjust_level_bonus(chain: ModLoaderHookChain, lvl: int, rank: int) -> int:
	if lvl < 0:
		return lvl

	var chunk = chain.reference_object
	if not chunk or not ("upgrade_table" in chunk):
		return chain.execute_next([lvl, rank])

	var table: Array = chunk.upgrade_table
	if lvl >= table.size():
		return 19

	var row: Array = table[lvl]
	var max_vanilla_rank: int = row.size() - 1

	# Ranks 0-5 use the vanilla table directly
	if rank <= max_vanilla_rank:
		return row[rank]

	# Ranks 6-12 extend progression smoothly toward layer 19 (deepest rock)
	var extra_shift: int = rank - max_vanilla_rank
	var base_val: int = row[max_vanilla_rank]
	var calculated_lvl: int = mini(19, base_val + extra_shift)
	return calculated_lvl