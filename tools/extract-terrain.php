#!/usr/bin/env php
<?php

function readData($bytes = 1, $handle = NULL)
{
	global $data_file;
	if ($handle === NULL) $handle = $data_file;

	$first_byte = fgetc($handle);
	$second_byte = ($bytes == 2) ? fgetc($handle) : NULL;

	// remember, files are (small-byte) (large-byte)
	return ($second_byte != NULL) 
	  ? (ord($second_byte) * 256) + ord($first_byte)
	  : ord($first_byte);
}

function readString($bytes = 32, $handle = NULL)
{
	global $data_file;
	if ($handle === NULL) $handle = $data_file;

	return fread($handle, $bytes);  
}

function writeData($data, $bytes = 1, $handle = NULL)
{
	global $out_file;
	if ($handle === NULL) $handle = $out_file;

	if ($bytes == 1)
	{
		fwrite($handle, chr($data % 256), 1);
	}
	elseif ($bytes == 2)
	{
		fwrite($handle, chr(($data & 255) / 256), 1);
		fwrite($handle, chr(($data % 256)),1);
	}
}

function writeString($data, $bytes, $handle = NULL)
{
	global $out_file;
	if ($handle === NULL) $handle = $out_file;

	fwrite($handle, $data, $bytes);
}

$tileset = 1;
$ground_file = "/home/david/projects/lemmings/resources/dat/ground".$tileset.".dat";
$terrain_file = "/home/david/projects/lemmings/resources/dat/terrain".$tileset.".dat";
$adjustment_file = "/home/david/projects/lemmings/resources/terrain-adjustment".$tileset.".php";
$output_dir = "/home/david/projects/lemmings/bin/gfx/extracted_terrain/";
$lookup_table = "/home/david/projects/lemmings/include/terrain-offset-table.asm";

$number_of_chunks = 64;

$ground_handle = fopen($ground_file, 'rb');
$terrain_handle = fopen($terrain_file, 'rb');

// get width in pixels of the first terrain piece, from ground0 file at 0x1C0
fseek($ground_handle, 0x1c0);

for ($chunk_index = 0; $chunk_index < $number_of_chunks; $chunk_index++)
{

	$chunk_def = array();
	$chunk_def['width_bits'] = readData(1, $ground_handle);
	$chunk_def['height_px'] = readData(1, $ground_handle);
	$chunk_def['start_offset'] = readData(2, $ground_handle);
	$chunk_def['mask_offset'] = readData(2, $ground_handle);
	$chunk_def['unknown'] = readData(2, $ground_handle);

	if ($chunk_def['width_bits'] == 0 || $chunk_def['width_bits'] == 255)
	{
		$number_of_chunks = $chunk_index;
		break;
	}

	$bytes_per_line = $chunk_def['width_bits'] / 8;

	// read terrain chunk 0 from terrain0.dat

	$line_bytes = array_fill(0, $chunk_def['width_bits'], 0);
	$data = array_fill(0, $chunk_def['height_px'], array_fill(0, $chunk_def['width_bits'], 0));

	$val = 1;

	for ($c = 0; $c < 4; $c++)
	{
		// first loop
		for ($v = 0; $v < $chunk_def['height_px']; $v++)
		{
			$line_raw = array_map("ord", str_split(readString($bytes_per_line, $terrain_handle)));

			for ($j = 0; $j < $bytes_per_line; $j++)
			{
				$byte = $line_raw[$j];
				$bit_base = $j * 8;

				if (($byte & 0x80)) $data[$v][$bit_base + 0] += $val;
				if (($byte & 0x40)) $data[$v][$bit_base + 1] += $val;
				if (($byte & 0x20)) $data[$v][$bit_base + 2] += $val;
				if (($byte & 0x10)) $data[$v][$bit_base + 3] += $val;
				if (($byte & 0x08)) $data[$v][$bit_base + 4] += $val;
				if (($byte & 0x04)) $data[$v][$bit_base + 5] += $val;
				if (($byte & 0x02)) $data[$v][$bit_base + 6] += $val;
				if (($byte & 0x01)) $data[$v][$bit_base + 7] += $val;
			}
		}

		$val = ($val << 1);
	}
	$chunks[$chunk_index]['def'] = $chunk_def;
	$chunks[$chunk_index]['data'] = $data;
	$chunks[$chunk_index]['left'] = 0;
	$chunks[$chunk_index]['right'] = 0;
}

for ($chunk_index = 0; $chunk_index < $number_of_chunks; $chunk_index++)
{
	$chunk_def = $chunks[$chunk_index]['def'];
	$data = $chunks[$chunk_index]['data'];

	$least_left = 999;
	$most_right = 000;

	for ($y = 0; $y < $chunk_def['height_px']; $y++)
	{
		for ($x = 0; $x < $chunk_def['width_bits']; $x++)
		{
			$color = $data[$y][$x];
			if (($color != 0) && ($x < $least_left))
			{
				$least_left = $x;
			}
			if (($color != 0) && ($x > $most_right))
			{
				$most_right = $x;
			}
		}
	}
	$chunks[$chunk_index]['left'] = $least_left;
	$chunks[$chunk_index]['right'] = $most_right+1;
}
$counter = 0;
echo ";; Terrain Lookup Table" . PHP_EOL;
foreach ($chunks as $index => $chunk)
{
	$total_nibbles = $chunk['right'] - $chunk['left'];
	if ($chunk['left'] % 2) $chunk['left']--;	
	if ($chunk['right'] % 2)  $chunk['right']++;
	$total_bytes = ceil($total_nibbles / 2);
	$left_start_byte = $chunk['left'] / 2;
	$left_start_nibble = $chunk['left'];
	//printf("Chunk %s  \t Left %s \t Right %s \t Width %s \t Correction Nibble %s\n", $index, $chunk['left'], $chunk['right'], $total_nibbles, ($total_nibbles % 2));

	$filename = $output_dir . sprintf("ter_%s_%02s.dat", $tileset, $index);
	//echo $output_dir.$filename . PHP_EOL;
	$chunk_file = fopen($filename, 'wb');

	$line_bytes = '';
	foreach ($chunk['data'] as $line_number => $data)
	{
		for ($k = 0; $k < $total_nibbles; $k = $k + 2)
		{
			$line_bytes .= chr(($data[$k+$left_start_nibble] << 4) + ($data[$k+1+$left_start_nibble]));
		}
	}
	fputs($chunk_file, $line_bytes);
	fclose($chunk_file);
	$total_size = $total_bytes*$chunk['def']['height_px'];
	echo sprintf("%s\t\t\t\tFDB\t$%04X+TerrainData\n", "Ter_".$tileset."_".sprintf("%02s", $index), $counter);
	echo sprintf("\t\t\t\t\tFCB\t%02s,%02s\n", $total_bytes, $chunk['def']['height_px']);
	$counter += $total_size;

}


