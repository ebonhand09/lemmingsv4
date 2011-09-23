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


$ground_file = "/home/david/projects/lemmings/resources/dat/ground0.dat";
//$terrain_file = "/home/david/projects/lemmings/resources/dat/terrain0.dat";
$objects_file = "/home/david/projects/lemmings/resources/dat/objects0.dat";

$number_of_chunks = 16;

$ground_handle = fopen($ground_file, 'rb');
$objects_handle = fopen($objects_file, 'rb');

// object index starts at 0x00 in $ground_handle
fseek($ground_handle, 0x00);

for ($chunk_index = 0; $chunk_index < $number_of_chunks; $chunk_index++)
{

	$chunk_def = array();
	$chunk_def['animation_flags'] = readData(2, $ground_handle);
	$chunk_def['start_animation_frame_index'] = readData(1, $ground_handle);
	$chunk_def['end_animation_frame_index'] = readData(1, $ground_handle);
	$chunk_def['width'] = readData(1, $ground_handle);
	$chunk_def['height'] = readData(1, $ground_handle);
	$chunk_def['animation_frame_data_size'] = readData(2, $ground_handle);
	$chunk_def['mask_offset_from_image'] = readData(2, $ground_handle);
	$chunk_def['unknown1'] = readData(2, $ground_handle);
	$chunk_def['unknown2'] = readData(2, $ground_handle);
	$chunk_def['trigger_left'] = readData(2, $ground_handle);
	$chunk_def['trigger_top'] = readData(2, $ground_handle);
	$chunk_def['trigger_width'] = readData(1, $ground_handle);
	$chunk_def['trigger_height'] = readData(1, $ground_handle);
	$chunk_def['trigger_effect_id'] = readData(1, $ground_handle);
	$chunk_def['animation_frames_base_loc'] = readData(2, $ground_handle);
	$chunk_def['preview_image_index'] = readData(2, $ground_handle);
	$chunk_def['unknown3'] = readData(2, $ground_handle);
	$chunk_def['trap_sound_effect_id'] = readData(1, $ground_handle);


	if ($chunk_def['width'] == 0 || $chunk_def['width'] == 255)
	{
		$number_of_chunks = $chunk_index;
		break;
	}

	$bytes_per_line = $chunk_def['width'] / 8;

	// read terrain chunk 0 from terrain0.dat

	$line_bytes = array_fill(0, $chunk_def['width'], 0);
	$data = array_fill(0, $chunk_def['height'], array_fill(0, $chunk_def['width'], 0));

	$val = 1;

	fseek($objects_handle, $chunk_def['animation_frames_base_loc']);

	for ($c = 0; $c < 4; $c++)
	{
		// first loop
		for ($v = 0; $v < $chunk_def['height']; $v++)
		{
			$line_raw = array_map("ord", str_split(readString($bytes_per_line, $objects_handle)));

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
}
$html = '<link rel="stylesheet" media="screen" href="terrain0.css"/>';
$html .= '<link rel="stylesheet" media="screen" href="style.css"/>';

for ($chunk_index = 0; $chunk_index < $number_of_chunks; $chunk_index++)
{
	$html .= "Chunk Number : " . $chunk_index . "<br />" . PHP_EOL;
	$html .= '<table class="terrain" border="0" cellspacing="0" cellpadding="0">';

	$chunk_def = $chunks[$chunk_index]['def'];
	$data = $chunks[$chunk_index]['data'];

	for ($y = 0; $y < $chunk_def['height']; $y++)
	{
		$html .= PHP_EOL . '<tr>' . PHP_EOL;
		for ($x = 0; $x < $chunk_def['width']; $x++)
		{
			$color = $data[$y][$x];
			//imagesetpixel($im, $x, $y, $color);

			$style = "color-" . $color;

			$html .= '<td class="' . $style . '">&nbsp;</td>';
		}
		$html .= PHP_EOL . '</tr>' . PHP_EOL;

	}

	$html .= '</table>';
}
file_put_contents('/home/david/projects/lemmings/previews/objects-set-0.html', $html);
//imagegif($im, "/home/david/projects/lemmings/tools/chunk.gif");
echo "Done" . PHP_EOL;

