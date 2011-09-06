				SECTION .payload_terrain_physical_map	; ORG	$FFA3
				FCB	$0F,$10,$11
				ENDSECTION
				
				SECTION .payload_terrain		; ORG	$6000
TerrainData			EXPORT
TerrainData			INCLUDEBIN	"../bin/gfx/terrain0.bin" 
				ENDSECTION
				
				SECTION	.payload_level_physical_map	; ORG	$FFA4
				FCB	$12
				ENDSECTION
				
				SECTION	.payload_level			; ORG	$8000
LevelData			EXPORT
LevelData			INCLUDEBIN	"../bin/lvl/0001.lvl"
				ENDSECTION

				SECTION .payload_terrain_offset_physical_map ; ORG $FFA5
				FCB	$16
				ENDSECTION

				SECTION	.payload_terrain_offset		; ORG $A000
TerrainOffsetData		EXPORT
TerrainOffsetData		INCLUDE		"terrain-offset-table.asm"
				ENDSECTION
