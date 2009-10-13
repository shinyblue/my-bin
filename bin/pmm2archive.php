#!/usr/bin/php
<?php
if (!isset($argv[1]) ||
	$argv[1]=='--help' || 
	$argv[1]=='-h' ) {
	echo <<<EOF
Usage: pmm2archive.php <filename> [<filename>...]

Splits Pegasus folder files into separate emails in text files
named: date_from_subject, puts them in a directory with the 
same name as the pegasus folder.

Rich Lott 26 Jan 13:33. GPL2 ; )
EOF;
	exit;
}


function get_name_from_headers( & $headers ) { //{{{
		//from name
		preg_match('/^From:\s+(.+)$/m', $headers, $matches);
		$from = $matches[1];
		if ( preg_match('/"?(.+?)"?\s+<(.+@.+)>/', $from, $matches ) ) {
			$from = $matches[1]; //just get name
		}
		$from = preg_replace('/<.+?>/','',$from); //strip emails

		if (strlen( $from )>30 ) $from = substr( $from, 0,27) . '..' ;
	
		//date
		preg_match('/^Date:\s+(.+)$/m', $headers, $matches);
		$date = $matches[1];
		$date = date('Y-m-d', strtotime($date));
	
		//subject
		preg_match('/^Subject:\s+(.+)$/m', $headers, $matches);
		$subject = $matches[1];
		$subject = substr($subject,0,strlen($subject) -1 );
		if (strlen( $subject )>30 ) $subject = substr( $subject, 0,28) . '..';
		

		$filename = "${date}_${from}_${subject}";
		$filename = preg_replace('/([ :]|_+)/','_',$filename);
		$filename = preg_replace('/[^A-Za-z0-9-_]/','',$filename);
		
		if (file_exists( $filename ) ){
			$fileno=1;
			while (file_exists("${filename}_$fileno")) $fileno++;
			$filename = "${filename}_$fileno";
		}
		return $filename;

} // }}}

// --------------------------

unset($argv[0]); //this is the program name

$fileno=1;
$filesdone=0;

// main loop for filenames
foreach ($argv as $filename) {
	$pmm = fopen($filename, 'r');
	echo "processing $filename\n";
	
	//first line includes folder name which must be removed
	$buffer = fgets($pmm, 4096); 
	$start = strpos($buffer,chr(0));
	if ($start>0) $foldername = substr($buffer,0,$start);
	else $foldername = 'unknown folder';
	
	$foldername = strtr($foldername, ' ?&+\\\'"','_______' );
	if (file_exists( $foldername)) {
		$fileno=1;
		while (file_exists( $foldername . "_$fileno" ) ) $fileno++;
		$foldername = $foldername . "_$fileno";
	}
	
	mkdir ($foldername);
	chdir ($foldername);
	echo "Created Folder $foldername\n";
	
	$start=strpos($buffer,'Return-Path');
	if ($start) $buffer = substr($buffer, $start);
	else $buffer = '';
	
	// loop for emails within pmm files:
	while (!feof($pmm)) {
		
		//first get headers
		$gotheaders = false;
		$endofemail = false;
		
		//create variable to hold email headers.
		$headers = $buffer; //buffer contains first line
		
		//write out email...
		while (!$endofemail && !feof($pmm) ) {
		
			if (!$gotheaders) {
				$headers .= $buffer;
				
				if ($buffer == "\r\n") {
					//blank line means end of headers.
					
					$filename = get_name_from_headers( $headers );
					$out = fopen( "$filename" , 'w' );
					fwrite ($out, $headers);
					
					$gotheaders = true;
				}
				
			}
			else {//write out rest of email without looking at it.
				fwrite( $out, $buffer );
			}
			//fwrite($out,$buffer);
		   	$buffer = fgets($pmm, 4096); // reads one line
			//emails start with ctrl-Z
			if (ord(substr($buffer,0,1))==26) {
				$buffer = substr($buffer,1); // lop off ctrl-z
				$endofemail = true;
			}
		}
		//fclose($out);
		$filesdone++;
		echo "Written file $filesdone to $filename \n";
	}
	echo "\n";
	fclose ($pmm);
	chdir ('..'); // go up level
}
?>
