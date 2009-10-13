DIR=/mnt/bulk/pictures/
# count pictures
pics=$(locate -c "$DIR*jpg")
# generate random number within this range
pic=$RANDOM
let "pic %= $pics"
pic=$((1 + pic ))

# now slice locate results
newpic=$(locate "$DIR*jpg" | head -n$pic | tail -n1)
#echo newpic: $newpic
cd ~/.kde/share/config/
#perl -pe "s{^(Wallpaper=).*$}{\$1$newpic}" kdesktoprc >new_kdesktoprc
#chown --reference=kdesktoprc new_kdesktoprc
#mv new_kdesktoprc kdesktoprc
# 8 = scale and crop
dcop kdesktop KBackgroundIface setWallpaper "$newpic" 8
echo `date` : $newpic >>/home/rich/desktop_pic_log
