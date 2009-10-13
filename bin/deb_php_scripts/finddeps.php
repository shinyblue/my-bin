<?php
$do = $argv[1];
if ($do!='pkgs' && $do!='files' )
	exit ("usage: $argv[0] pkgs|files <packagename>\n");

$pack = $argv[2];
$pkgs = file( 'pkgs' );
$rqd = array();
$rqdfiles = array();
function go( $pack, & $pkgs, & $rqd, & $rqdfiles ) 
{
//	echo "called with $pack\n";
	$pack_strlen = strlen( $pack );
	$pack_count = sizeof( $pkgs );
	for ($key=0;$key<$pack_count;$key++)
	{
	$line = $pkgs[ $key ];
//	echo "?=" . (substr( $line, 0, $pack_strlen )) . "=\n?=$pack= \n\n";
	if (substr( $line, 0, $pack_strlen+1 ) == "$pack " )
	{
		//find dependencies
		$line = substr($line, 0, strlen($line)-1);
		$deps=explode(' ', $line );
		$rqd[] = $deps[0];
		$newpack = $deps[0];
		$rqdfiles[] = $deps[1];
//		echo "Found pack: $newpack\n";
		$deps=explode(';', $deps[2] );
		foreach ($deps as $deppack) 
		{
			/*			echo "array search for dep: $deppack in ";
						print_r($rqd);
						echo (in_array( $deppack, $rqd)?"yes":"no");
						echo "\n";*/
			if ( $deppack && ! in_array( $deppack, $rqd ) ) 
				go( $deppack, $pkgs, $rqd, $rqdfiles );
		}
		break;
	}
	}
}

go( $pack, $pkgs, $rqd, $rqdfiles );

if ($do=='files') echo implode( "\n", $rqdfiles);
else echo implode( "\n", $rqd);
echo "\n";
?>
