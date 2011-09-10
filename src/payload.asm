				INCLUDE	"defines.asm"

				SECTION .payload_terrain_physical_map	; ORG	$FFA3
				FCB	Block_TerrainData,Block_TerrainData+1,Block_TerrainData+2
				ENDSECTION
				
				SECTION .payload_terrain		; ORG	$6000
TerrainData			EXPORT
TerrainData			INCLUDEBIN	"../bin/gfx/terrain0.bin" 
				ENDSECTION
				
				SECTION	.payload_level_physical_map	; ORG	$FFA4
				FCB	Block_LevelData
				ENDSECTION
				
				SECTION	.payload_level			; ORG	$8000
LevelData			EXPORT
LevelData			INCLUDEBIN	"../bin/lvl/test.lvl"
				ENDSECTION

				SECTION .payload_terrain_offset_physical_map ; ORG $FFA5
				FCB	Block_TerrainOffset
				ENDSECTION

				SECTION	.payload_terrain_offset		; ORG $A000
TerrainOffsetTable		EXPORT
TerrainOffsetTable		INCLUDE		"terrain-offset-table.asm"
				ENDSECTION
