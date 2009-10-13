#!/usr/bin/php
<?php
if (!isset($argv[1])) {
	echo <<<EOF
Usage: pmm2cnm.php <filename> [<filename>...]

Splits Pegasus folder files into multiple Pegasus inbox files
(which are individual emails)

EOF;
	exit;
}

unset($argv[0]); //this is the program name

$fileno=1;
$filesdone=0;

// main loop for filenames
foreach ($argv as $filename) {
	$pmm = fopen($filename, 'r');
	echo "processing $filename\n";
	
	//first line includes folder name which must be removed
	$buffer = fgets($pmm, 4096); 
	$buffer = substr($buffer, strpos($buffer,'Return-Path'));
	
	// loop for emails within pmm files:
	while (!feof($pmm)) {
			
		//get free file for output
		while (file_exists("out$fileno.cnm")) $fileno++;
		$out = fopen("out$fileno.cnm",'w');
		
		//write out email
		$endofemail = false;
		while (!$endofemail) {
			fwrite($out,$buffer);
		   	$buffer = fgets($pmm, 4096);
			//emails start with ctrl-Z
			if (ord(substr($buffer,0,1))==26) {
				$buffer = substr($buffer,1); // lop off ctrl-z
				$endofemail = true;
			}
		}
		fclose($out);
		$filesdone++;
		echo "Written file $filesdone (out$fileno.cnm)\n";
	}
	echo "\n";
	fclose ($pmm);
}
?>
