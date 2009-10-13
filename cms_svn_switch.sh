#!/bin/bash
cd /var/www/cms/
if svn info | fgrep URL | fgrep svn+ssh >/dev/null
then	
	echo "currently using ssh"
	if ping maui -c1 >/dev/null 2>&1
	then
		svn switch --relocate svn+ssh://maui.work/svn/cms/trunk svn://maui/svn/cms/trunk
	else
		echo "Couldn't ping maui.work, so not attempting to change" >&2
	fi
else
	echo "currently using svn"
	export SVN_SSH="ssh -p22622"
	svn switch --relocate svn://maui/svn/cms/trunk svn+ssh://rich@maui.work/svn/cms/trunk
fi
echo "New repository:"
svn info | fgrep URL 
