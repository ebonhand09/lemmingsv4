#!/usr/bin/env php
<?php

  if ($argc < 3)
  {
    die('No input/output files specified!' . PHP_EOL);
  }

  $input_file = fopen($argv[1] ,'rb');

  $save_file = fopen($argv[2], 'wb');

  $current_byte = ord(fgetc($input_file));

  while (false !== ($data = fgetc($input_file)))
  { 
    $last_byte = $current_byte;
    $current_byte = ord($data);

    // look-ahead
    $i = 0;

    while ($current_byte === $last_byte)
    {
      $current_byte = ord(fgetc($input_file));
      if (feof($input_file)) {
        break;     
      }
      $i++;
      if ($i == 255) break;
    }

    if ($i > 0)
    {
      fwrite($save_file, chr($last_byte),1);
      //echo "Wrote from line 28: $last_byte\n";
      // repeated bytes found
      if ($i > 15)
      {
        fwrite($save_file, chr(bindec('11111111')), 1);
        fwrite($save_file, chr($i), 1);
        //echo "Wrote from line 33 and 34: '11111111' and $i\n";
      }
      else
      {
        $output = '1111' . sprintf("%04b", $i-1);
        fwrite($save_file, chr(bindec($output)), 1);
        //echo "Wrote from line 40: '1111', {$i}-1\n";
      }
    }
    else
    {
      fwrite($save_file, chr($last_byte),1);
      //echo "Wrote from line 46: $last_byte\n";
    }
  }

  $final_byte = ord(fgetc($input_file));
  if (!$final_byte) $final_byte = $last_byte;
  fwrite($save_file, chr($final_byte),1);
  //echo "Wrote from line 53: $final_byte\n";
  fclose($save_file);
