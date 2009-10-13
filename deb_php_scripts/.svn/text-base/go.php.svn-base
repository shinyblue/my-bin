<?php
$f= fopen('Packages','r');
$out = fopen('pkgs','w');

while ( ! feof( $f ) )
{
	$line = fgets( $f, 4096);
	if ( substr($line,0,9)=='Package: ' )
	{
		$line = substr( $line, 0, strlen( $line ) - 1 );
		$package = substr( $line, 9 );
	}
	elseif ( substr( $line, 0,9 ) == 'Depends: ' )
	{
		$line = substr( $line, 0, strlen( $line ) - 1 );
		$dependspkgs = explode( ', ', substr( $line, 9 ) );
		foreach ( $dependspkgs as $key=>$val )
		{
			$val = explode( ' ', $val );
			$dependspkgs[ $key ] = $val[0];
		}
	}
	elseif ( substr( $line, 0,10) == 'Filename: ' )
	{
		$line = substr( $line, 0, strlen( $line ) - 1 );
		$filename = substr( $line, 10);
	}
	elseif ( $line == "\n" )
	{
		$s = "$package $filename " . implode( ';', $dependspkgs ) . "\n";
//		echo $s;
		fwrite( $out, $s );
		$s = '';
		$dependspkgs = array();
		$package = '';
		$filename = '';
	}
}
fclose( $out );
fclose( $f );
echo "done\n";
$f = file( 'pkgs' );
echo "read ok";
?>
