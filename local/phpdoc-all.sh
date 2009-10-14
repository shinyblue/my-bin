#!/bin/bash
output=/smb/maui/web/one/d
input_root=/smb/maui/web/rich.dev
inputs="$input_root/webdevshared,$input_root/one,$input_root/peopleandplanet.org"
ignores=".git*,$input_root/$input_root/php/custompage_bottom.php,$input_root/php/custompage_top.php,$input_root/php/inc_top.php,$input_root/publicphp/page.php,$input_root/php/adminpage_top.php,$input_root/custom_shared_php/database_secrets.php"
executable=~/PhpDocumentor-1.4.3/phpdoc
format='HTML:Smarty:PHP'
#format='HTML:Frames:phpedit'

# -is = ignore symlinks (otherwise peopleandplanet.org gets to documenting 
# webdevshared etc.)
$executable -is --parseprivate -o "$format" -t "$output" -d "$inputs" -i "$ignores"
