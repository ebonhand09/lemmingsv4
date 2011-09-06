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
    	if ($xoff > 32677)
    	{
    		$xoff = 32767 - $xoff;
    	}
    	//$this->x_offset = floor($xoff / 2);
    	$this->x_offset = $xoff;
    }
    
    function adjustXOffset($adjust)
    {
    	$this->x_offset = $this->x_offset - $adjust;
    	if ($this->x_offset < 0)
    	{
    		die(sprintf("tTerrainPiece %s X Offset error. Adjusted to %s by value %s\n", $this->id, $this->x_offset, $adjust));
    	}
    }
    
    function setYOffset($yoff)
    {
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
  
  if ($argc < 2)
  {
    echo "No filename specified" . PHP_EOL;
    exit;
  }

  // open file
  $level_file = fopen($argv[1], 'r');
  
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
  echo "Graphic set: " . $level->graphicSet . PHP_EOL;
  echo "Total Objects: " . $level->totalObjects . PHP_EOL;
  echo "Total Terrain: " . $level->totalTerrain . PHP_EOL;
  echo "Total Steel: " . $level->totalSteel . PHP_EOL;

  $eof = fgetc($level_file);
  if ($eof === FALSE) echo "End of file reached!" . PHP_EOL;

  /* Explore some information here */

  $min_x = 99999;
  $max_x = 0;
  $min_y = 99999;
  $max_y = 0;

  for ($i = 0; $i < $level->totalTerrain; $i++)
  {
    $min_x = min($min_x, $level->terrainArray[$i]->x_offset);
    $max_x = max($max_x, $level->terrainArray[$i]->x_offset);
    
    
    $y = $level->terrainArray[$i]->y_offset;
    if ($y > 512) $y = 0;
    $min_y = min($min_y, $y);
    $max_y = max($max_y, $y);
  }

  foreach ($level->terrainArray as $key => $val)
  {
    if ($val->x_offset == $max_x)
    {
      echo "Right-most piece found: id " . $val->id . PHP_EOL;
    }
    
    if ($val->y_offset == $max_y)
    {
      echo "Lower-most piece found: id " . $val->id . PHP_EOL;
    }
  }

  echo "Smallest Terrain X Value: " . $min_x . PHP_EOL;
  echo "Largest Terrain X Value: " . $max_x . PHP_EOL;
  echo "Smallest Terrain Y Value: " . $min_y . PHP_EOL;
  echo "Largest Terrain Y Value: " . $max_y . PHP_EOL;
  echo "Total width (unadjusted, not including right-most piece): " . $max_x . PHP_EOL;
  echo "Total width (not including width of right-most terrain piece): " . ($max_x - $min_x) . PHP_EOL;
  echo "Total height (not including height of bottom-most terrain piece): " . ($max_y - $min_y) . PHP_EOL;
  
  foreach ($level->terrainArray as $key => $val)
  {
  	$level->terrainArray[$key]->adjustXOffset($min_x);
  }

  foreach ($level->terrainArray as $terrain)
  {
    if ($terrain->x_offset > 600)
    {
      echo "Terrain piece id {$terrain->id} is at " . ($terrain->x_offset) . ", {$terrain->y_offset}. NotOverlap: {$terrain->notOverlap}, Black: {$terrain->black}, UpsideDown: {$terrain->upsideDown}" . PHP_EOL;
    }
  }

 

  
