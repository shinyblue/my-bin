#!/bin/bash
cd /var/www/shinyblue/
if svn info | fgrep URL | fgrep svn+ssh >/dev/null
then	
	echo "currently using ssh"
	if ping maui -c1 >/dev/null 2>&1
	then
		svn switch --relocate svn+ssh://rich@maui.work/svn/cms/branches/shinyblue svn://maui/svn/cms/branches/shinyblue 
	else
		echo "Couldn't ping maui.work, so not attempting to change" >&2
	fi
else
	echo "currently using svn"
	export SVN_SSH="ssh -p22622"
	svn switch --relocate svn://maui/svn/cms/branches/shinyblue svn+ssh://rich@maui.work/svn/cms/branches/shinyblue
fi
echo "New repository:"
svn info | fgrep URL 
