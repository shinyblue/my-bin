#!/usr/bin/php
<?php
/* remove lines found in one file from another.
*/
if (!($toremove = file( $argv[1] ))) exit( "Cannot open $argv[1]" );
if (!($removefrom = file( $argv[2] ))) exit( "Cannot open $argv[2]" );
$out= str_replace( $toremove, '', $removefrom);
foreach ($out as $key=>$val) if ($val!='' && $val!="\n") fwrite(STDOUT, $val); 
?>
