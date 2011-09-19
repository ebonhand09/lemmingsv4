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

function convertPaletteEntryToCocoFormat($byte)
{ // convert from 00rgbRGB format to 00RGBrgb
	$coco_upper = ($byte & 0x07) << 3;	// get last three bits
	$coco_lower = ($byte & 0x38) >> 3; // get upper three bits
	$coco = $coco_upper + $coco_lower;
	return $coco;
}

function convertCocoPaletteToHTML($byte)
{ // convert from 00RGBrgb to #RRGGBB
	$red = (($byte & 0x20) >> 4) | (($byte & 0x04) >> 2 );
	$green = (($byte & 0x10) >> 3) | (($byte & 0x02) >> 1);
	$blue = (($byte & 0x08) >> 2) | $byte & 0x01;

	$table = array('00', '55', 'AA', 'FF');

	return '#' . $table[$red] . $table[$green] . $table[$blue];
}

if ($argc < 2)
{
echo "No filenames specified" . PHP_EOL;
echo "Usage: extract-palette.php groundXo.dat" . PHP_EOL;
exit;
}

// open file
$data_file = fopen($argv[1], 'r');
fseek($data_file, 448 + 512); // Object Data size (448 bytes) + Terrain Data size (512)

$ega_palette['custom'] = array();
for ($i = 0; $i <= 7; $i++)
{
	$ega_palette['custom'][$i] = readData(); // get a byte from data file
}

$ega_palette['standard'] = array();
for ($i = 0; $i <= 7; $i++)
{
	$ega_palette['standard'][$i] = readData(); // get a byte from data file
}

$ega_palette['preview'] = array();
for ($i = 0; $i <= 7; $i++)
{
	$ega_palette['preview'][$i] = readData(); // get a byte from data file
}

$coco = convertPaletteEntryToCocoFormat($ega_palette['custom'][0]);
$html = convertCocoPaletteToHTML($coco);

/*
echo sprintf("Original: %02X Decimal: %s Binary: %06b Converted: %06b Hex: %02X HTML: %s\n",
	$ega_palette['custom'][0], $ega_palette['custom'][0],$ega_palette['custom'][0], $coco, $coco, $html);
*/

$ega_palette['standard'][7] = $ega_palette['custom'][0];

foreach ($ega_palette['standard'] as $index => $color)
{
//	printf("Index: %s\tColor: %s\tHTML: %s\n", 
echo sprintf("td.color-%s { background-color: %s; }\n", $index, convertCocoPaletteToHTML(convertPaletteEntryToCocoFormat($color)));
/*
		$index, 
		convertPaletteEntryToCocoFormat($color),
		convertCocoPaletteToHTML(convertPaletteEntryToCocoFormat($color)));
		*/
}
foreach ($ega_palette['custom'] as $index => $color)
{
//	printf("Index: %s\tColor: %s\tHTML: %s\n", 
/*		$index+8, 
		convertPaletteEntryToCocoFormat($color),
		convertCocoPaletteToHTML(convertPaletteEntryToCocoFormat($color)));
		*/
echo sprintf("td.color-%s { background-color: %s; }\n", $index+8, convertCocoPaletteToHTML(convertPaletteEntryToCocoFormat($color)));
}
