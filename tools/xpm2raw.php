#!/usr/bin/env php
<?php
  if ($argc < 4)
  {
    echo "No filenames specified" . PHP_EOL;
    echo "Usage: xpm2raw input.xpm output.dat palette.php [--offset|--mask]" . PHP_EOL;
    exit;
  }

  // open file
  $file = fopen($argv[1], 'r');
  $outfile = fopen($argv[2], 'wb');

  $argv4 = (isset($argv[4])) ? $argv[4] : NULL;
  $argv5 = (isset($argv[5])) ? $argv[5] : NULL;


  $offset_mode = ($argv4 == '--offset' | $argv5 == '--offset') ? true : false;
  $mask_mode = ($argv4 == '--mask' | $argv5 == '--mask') ? true : false;

  $palette_file = './tools/' . $argv[3];

  require($palette_file);

  $colormap = $pal;

  $line = fgets($file);
  $line = substr($line,0,9);

  // confirm file is XPM file
  if ($line != "/* XPM */")
  {
    echo 'File is not an XPM file. Expected: /* XPM */, received '.$line.PHP_EOL;
    exit;
  }

  // skip static char line
  $line = fgets($file);

  // get height / width into vars
  $line = fscanf($file, "\"%d\t%d\t%d\t%d\",\n", $width, $height, $depth, $flag);

//  echo "Height: $height, Width: $width, Depth: $depth, Flag: $flag" . PHP_EOL;

  // colormap/palette
  $palette = array();
  for ($i = 0; $i < $depth; $i++)
  {
    $line = fscanf($file, "\"%c\tc\t%7s\",\n", $char, $string);
    if (!$char) $char = ' ';
    if ($string == 'None",') $string = 'None';
    $palette[$char] = $string;
    //echo "Char: $char, String: $string" . PHP_EOL;

  }
  // match to bit patterns
  foreach($palette as $char => $string)
  {
    $palette[$char] = $colormap[$string];
  }

  //print_r($palette);

  // read lines of data
  $pixelmap = array();
  for ($i = 0; $i < $height; $i++)
  {
    $line = fgets($file);
    $line = substr($line, 1, $width);
    $pixelmap[] = $line;
  }

  // convert to bits
  $bitmap = array();
  foreach ($pixelmap as $pixels)
  {
    $pixelrow = str_split($pixels);
    if (count($pixelrow) % 2 != 0)
    {
    	$pixelrow[] = ' ';
    }
    $bitrow = '';
    foreach ($pixelrow as $pixel)
    {
      //echo "Pixel is '$pixel'" . PHP_EOL;
      $bitrow .= $palette[$pixel];
    }
    if ($offset_mode)
    {
      // move everything one nibble to the right, ignoring last nibble
      $bitrow = substr($bitrow, 0, -4);
      $bitrow = '0000' . $bitrow;
    }
    $bitmap[] = $bitrow;
  }
  
//  print_r($bitmap);

  foreach ($bitmap as $bitrow)
  {
    $line = str_split($bitrow, 8);
    $formatted = '';
    foreach ($line as $bits)
    {
      //$formatted .= "%" . $bits . ",";
      if ($mask_mode)
      {
        $mask  = (substr($bits, 0, 4) == '0000') ? '1111' : '0000';
        $mask .= (substr($bits, 4, 4) == '0000') ? '1111' : '0000';
        fwrite($outfile, chr(bindec($mask)),1);
      }
      fwrite($outfile, chr(bindec($bits)),1);
    }
    //$formatted = rtrim($formatted,',');
    //echo "\tFCB $formatted" . PHP_EOL;
  }
  fclose($outfile);

