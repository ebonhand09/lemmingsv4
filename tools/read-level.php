#!/usr/bin/env php
<?php

  class LevelData
  {
    public $title; //char * 32
    public $lemsToLetOut; // byte
    public $lemsToBeSaved; // byte
    public $releaseRate; // byte
    public $playingTime; // byte
    public $maxClimbers; // byte
    public $maxFloaters; // byte
    public $maxBombers; // byte
    public $maxBlockers; // byte
    public $maxBuilders; // byte
    public $maxBashers; // byte
    public $maxMiners; // byte
    public $maxDiggers; // byte
    public $screenStart; // word
    public $graphicSet; // byte
    public $graphicSetExtension; // byte
    public $totalObjects; // word
    public $objectArray; // array
    public $totalTerrain; // word
    public $terrainArray; // array
    public $totalSteel; // word
    public $steelArray; // array
  }

  class tObject
  {
    public $id; // byte
    public $x_offset; // word
    public $y_offset; // word 
    public $notOverlap; // bool(word)
    public $onTerrain; // bool(word)
    public $upsideDown; // bool(word)
    //public $pvFrameIdxCur; // byte
    //public $pvFrameIdxMax; // byte
    //public $pvLoop;
  }

  class tTerrainPiece
  {
    public $id; // byte
    public $x_offset; // in bytes
    public $y_offset; // in lines
    public $notOverlap; // byte
    public $black; // byte
    public $upsideDown; // byte
    
    function setID($id)
    {
    	$this->id = $id;
    }
    
    function setXOffset($xoff)
    {
	echo $xoff . PHP_EOL;
	if ($xoff > 32767) { $xoff = $xoff - 65535; }
    	$this->x_offset = floor($xoff / 2);
    }
    
    function adjustXOffset($adjust)
    {
    	//$this->x_offset = $this->x_offset - $adjust;
    }
    
    function setYOffset($yoff)
    {
    	$yoff = $yoff % 256;
    	$this->y_offset = $yoff;
    }
    
    function setNotOverlap($in)
    {
    	$this->notOverlap = ($in > 0) ? 255 : 0;
    }
    
    function setBlack($in)
    {
    	$this->black = ($in > 0) ? 255 : 0;
    }
    
    function setUpsideDown($in)
    {
    	$this->upsideDown = ($in > 0) ? 255 : 0;
    }
    
  }

  class tSteelArea
  {
    public $x_start; // word
    public $y_start; // word
    public $x_end; // word
    public $y_end; // word
  }

  function readData($bytes = 1, $handle = NULL)
  {
    global $level_file;
    if ($handle === NULL) $handle = $level_file;

    $first_byte = fgetc($handle);
    $second_byte = ($bytes == 2) ? fgetc($handle) : NULL;

    // remember, files are (small-byte) (large-byte)
    return ($second_byte != NULL) 
      ? (ord($second_byte) * 256) + ord($first_byte)
      : ord($first_byte);
  }

  function readString($bytes = 32, $handle = NULL)
  {
    global $level_file;
    if ($handle === NULL) $handle = $level_file;

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
  		fwrite($handle, chr(($data & 65280) / 256), 1);
  		fwrite($handle, chr(($data % 256)),1);
  	}
  }
  
  function writeString($data, $bytes, $handle = NULL)
  {
  	global $out_file;
  	if ($handle === NULL) $handle = $out_file;
  	
  	fwrite($handle, $data, $bytes);
  }
  
  if ($argc < 3)
  {
    echo "No filenames specified" . PHP_EOL;
    echo "Usage: read-level.php xxxx.dat yyyy.lvl" . PHP_EOL;
    exit;
  }

  // open file
  $level_file = fopen($argv[1], 'r');
  $out_file = fopen($argv[2], 'wb');
  
  $level = new LevelData();

  $level->title = readString();
  $level->lemsToLetOut = readData();
  $level->lemsToBeSaved = readData();
  $level->releaseRate = readData();
  $level->playingTime = readData();
  $level->maxClimbers = readData();
  $level->maxFloaters = readData();
  $level->maxBombers = readData();
  $level->maxBlockers = readData();
  $level->maxBuilders = readData();
  $level->maxBashers = readData();
  $level->maxMiners = readData();
  $level->maxDiggers = readData();
  $level->screenStart = readData(2);
  $level->graphicSet = readData();
  $level->graphicSetExtension = readData();
  $level->totalObjects = readData(2);

  for ($i = 0; $i < $level->totalObjects; $i++)
  {
    $level->objectArray[$i] = new tObject();
    $level->objectArray[$i]->id = readData();
    $level->objectArray[$i]->x_offset = readData(2);
    $level->objectArray[$i]->y_offset = readData(2);
    $level->objectArray[$i]->notOverlap = readData(2);
    $level->objectArray[$i]->onTerrain = readData(2);
    $level->objectArray[$i]->upsideDown = readData(2);
  }

  $level->totalTerrain = readData(2);

  for ($i = 0; $i < $level->totalTerrain; $i++)
  {
    $level->terrainArray[$i] = new tTerrainPiece();
    $level->terrainArray[$i]->setID(readData());
    $level->terrainArray[$i]->setXOffset(readData(2));
    $level->terrainArray[$i]->setYOffset(readData(2));
    $level->terrainArray[$i]->setNotOverlap(readData(2));
    $level->terrainArray[$i]->setBlack(readData(2));
    $level->terrainArray[$i]->setUpsideDown(readData(2));
  }

  $level->totalSteel = readData(2);

  for ($i = 0; $i < $level->totalSteel; $i++)
  {
    $level->steelArray[$i]->x_start = readData(2);
    $level->steelArray[$i]->y_start = readData(2);
    $level->steelArray[$i]->x_end = readData(2);
    $level->steelArray[$i]->y_end = readData(2);
  }

  //var_dump($level);
  echo PHP_EOL;
  echo "Stats" . PHP_EOL;
  echo "-----" . PHP_EOL;
  echo "Level name: " . $level->title . PHP_EOL;
  echo "Total Objects: " . $level->totalObjects . PHP_EOL;
  echo "Total Terrain: " . $level->totalTerrain . PHP_EOL;
  echo "Total Steel: " . $level->totalSteel . PHP_EOL;

  $eof = fgetc($level_file);
  if ($eof === FALSE) echo "End of file reached!" . PHP_EOL;

  /* Explore some information here */

  $min_x = 99999;
  $max_x = -999999;

  for ($i = 0; $i < $level->totalTerrain; $i++)
  {
    $min_x = min($min_x, $level->terrainArray[$i]->x_offset);
    $max_x = max($max_x, $level->terrainArray[$i]->x_offset);
  }

  foreach ($level->terrainArray as $key => $val)
  {
    if ($val->x_offset == $max_x)
    {
      echo "Right-most piece found: id " . $val->id . PHP_EOL;
    }
  }

  echo "Smallest Terrain X Value: " . $min_x . PHP_EOL;
  echo "Largest Terrain X Value: " . $max_x . PHP_EOL;
  echo "Total width (not including width of right-most terrain piece): " . ($max_x - $min_x) . PHP_EOL;
  
  //echo "Adjusting X offsets based upon smallest terrain X Value..." . PHP_EOL;
  
  foreach ($level->terrainArray as $key => $val)
  {
  	$level->terrainArray[$key]->adjustXOffset($min_x);
  }

/*
  foreach ($level->terrainArray as $terrain)
  {
    if ($terrain->id == 0)
    {
      echo "Terrain piece id {$terrain->id} is at " . ($terrain->x_offset) . ", {$terrain->y_offset}. NotOverlap: {$terrain->notOverlap}, Black: {$terrain->black}, UpsideDown: {$terrain->upsideDown}" . PHP_EOL;
    }
  }
*/
 
	// WRITE OUT LEVEL
	writeString($level->title, 32);
	writeData($level->lemsToLetOut);
	writeData($level->lemsToBeSaved);
	writeData($level->releaseRate);
	writeData($level->playingTime);
	writeData($level->maxClimbers);
	writeData($level->maxFloaters);
	writeData($level->maxBombers);
	writeData($level->maxBlockers);
	writeData($level->maxBuilders);
	writeData($level->maxBashers);
	writeData($level->maxMiners);
	writeData($level->maxDiggers);
	writeData(floor($level->screenStart/2), 2);
	writeData($level->graphicSet);
	writeData($level->graphicSetExtension);
	//writeData($level->totalObjects);
	writeData(0,2); // hack - will fix when there's actually objects in the game
	writeData($level->totalTerrain);
	//writeData($level->totalSteel);
	writeData(0,2); // hack - will fix when there's actually steel in the game
	
	// WRITE OUT TERRAIN
	foreach($level->terrainArray as $key => $val)
	{
		writeData($val->id);
		writeData($val->x_offset,2);
		writeData($val->y_offset);
		writeData($val->notOverlap);
		writeData($val->black);
		writeData($val->upsideDown);
	}

	
	fclose($out_file);

  
