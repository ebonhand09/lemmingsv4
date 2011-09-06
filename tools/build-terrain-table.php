#!/usr/bin/env php
<?php
class TerrainChunk
{
	public $filename; // including path
	public $name;	// string
	public $size;	// in bytes
	public $width;	// in bytes
	public $height; // in lines
}

$chunks = array();

foreach (glob('resources/gfx/terrain/ter_0_??.xpm') as $filename)
{
	$chunk = new TerrainChunk();
	$chunk->filename = $filename;
	$chunk->name = basename($filename, '.xpm');

	// open file
	$file = fopen($chunk->filename, 'r');

	// confirm file is XPM file
	$line = fgets($file);
	$line = substr($line,0,9);

	if ($line != "/* XPM */")
	{
		echo "File {$chunk->filename} is not an XPM file. Expected: /* XPM */, received " . $line . PHP_EOL;
		exit;
	}

	// skip static char line
	$line = fgets($file);

	// get height / width into vars
	$line = fscanf($file, "\"%d\t%d\t%d\t%d\",\n", $width, $height, $depth, $flag);

	$chunk->width = ($width % 2) ? (($width + 1) / 2) : ($width / 2);
	$chunk->height = $height;
	$chunk->size = $chunk->width * $chunk->height;
	
	fclose($file);
	
	$chunks[] = $chunk;
}

echo ";*** Terrain Chunk Lookup Table" . PHP_EOL;
//echo " section .terrain_offset_table_physical_map" . PHP_EOL;
//echo " fcb $2F" . PHP_EOL;
//echo " endsection" . PHP_EOL;
//echo " section .terrain_offset_table" . PHP_EOL;
//echo "TerrainOffsetTable EXPORT" . PHP_EOL;
//echo "TerrainOffsetTable" . PHP_EOL;

$counter = 0;
foreach ($chunks as $chunk)
{
	echo sprintf("%s\t\t\t\tFDB\t$%04X+TerrainData\n", ucfirst($chunk->name), $counter);
	echo sprintf("\t\t\t\t\tFCB\t%02s,%02s\n", $chunk->width, $chunk->height);
	$counter += $chunk->size;
}
echo	"; End of TerrainData is at " . sprintf("$%04X", $counter) . PHP_EOL;
//echo	" endsection" . PHP_EOL;





//print_r($chunks);


