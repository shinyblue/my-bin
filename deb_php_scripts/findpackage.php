<?php
$do = $argv[1];
if ( $do == '-f' ) { $file = true ; $do = $argv[2] ; }
if (! $do  )
	exit ("usage: $argv[0] [-f] <text>\n".
		"Searches for package names containing text\n".
		"returns package names unless -f given in which case \n".
		"returns filenames");

$pkgs = fopen( 'pkgs' ,'r');
while (! feof( $pkgs ) )
{
		$deps=explode(' ', fgets( $pkgs ) );
		if (strpos( $deps[0], $do )!==false) {
			if ($file) $output = $deps[1];
			else $output = $deps[0] ;
			echo $output . "\n";
		}
}
fclose( $pkgs );
?>
