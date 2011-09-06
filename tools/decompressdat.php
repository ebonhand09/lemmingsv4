#!/usr/bin/env php
<?php

  if ($argc < 3)
  {
    die('No input/output files specified!' . PHP_EOL);
  }

  $input_file = fopen($argv[1] ,'rb');

  $save_file = fopen($argv[2], 'wb');

  $outloc = 0;

  $current_byte = ord(fgetc($input_file));
  echo "I got $current_byte, which should be written to $outloc\n"; 

  while (false !== ($data = fgetc($input_file)))
  { 
    $last_byte = $current_byte;
    $current_byte = ord($data);

    fwrite($save_file, chr($last_byte), 1);
    echo "Writing single byte $last_byte to $outloc on line 21\n";
    $outloc++;
    
    if (($current_byte == 255))
    { // following byte says how many times to output $last_byte
      $repeat = ord(fgetc($input_file));
      echo "$current_byte on line 27 says to write $last_byte out $repeat times\n";
      for ($i = 0; $i < $repeat; $i++)
      {
        fwrite($save_file, chr($last_byte), 1);
        echo "Writing $last_byte to $outloc\n";
        $outloc++;
      }
      $current_byte = ord(fgetc($input_file));
    }
    elseif (($current_byte & 240) == 240)
    { // second half of byte says how many times to repeat + 1
      $repeat = ($current_byte & 15);
      echo "$current_byte on line 39 says to write $last_byte out $repeat + 1 times\n";
      $repeat++;
      for ($i = 0; $i < $repeat; $i++)
      {
        fwrite($save_file, chr($last_byte), 1);
        echo "Writing $last_byte to $outloc\n";
        $outloc++;
      }
      $current_byte = ord(fgetc($input_file));
    }
  }
  if (($current_byte & 240) == 0) 
  {
    fwrite($save_file, chr($current_byte),1);
    echo "Writing $current_byte out as last byte to $outloc\n";
  }
  fclose($save_file);
