#!/usr/bin/env python3

import os
from optparse import OptionParser
import re
import shutil
import subprocess

# if os.getuid() != 0:
#     print('must run as super user!')
#     exit(1)

parser = OptionParser()
parser.add_option('-p', '--isopath', dest='isopath',
                  help='path to ISO image')
parser.add_option('-m', '--volume', dest='volume',
                  help='mount point')

(opts, args) = parser.parse_args()

if opts.isopath != None:
    repo = opts.isopath
else:
    repo = os.getcwd()

if opts.volume == None:
    parser.print_help()
    exit(1)

root = opts.volume
part = ""

root = re.sub("/+$", '', root)

if root == "" or not os.path.exists(repo):
    parser.print_help()
    exit(1)

for line in open('/proc/mounts').readlines():
    mnt = line.split()
    if root == mnt[1]:
        part = mnt[0]
        break

if part == "":
    print("No such mount point found:", root)
    exit(1)

# FIXME: sdXN, mmcMpN, nvmeMpN
disk = re.sub('\d+$', '', part)
index = part.replace(disk, '')

boot = root + '/boot'
boot_iso = root + '/iso'

# mkdir -p boot
if not os.path.exists(boot):
    os.mkdir(boot)
if not os.path.exists(boot):
    os.mkdir(boot_iso)

# ############### copy ISO ###############
if os.path.isdir(repo):
    src_list = os.listdir(repo)
    i = 0
    while i < len(src_list):
        if not src_list[i].endswith('.iso'):
            del src_list[i]
        i += 1
    if len(src_list) == 0:
        print('no iso')
        exit(1)
elif os.path.exists(repo):
    src_list = [repo]
else:
    print("'$repo' is invalid!")
    exit(1)

iso_list = []

count = 0
for iso in src_list:
    count += 1
    print('[{}/{}]'.format(count, len(src_list)))

    iso_fn = os.path.basename(iso)
    iso_list.append(iso_fn)

    if os.path.exists(iso_fn):
        print('{}/{} already exists!'.format(boot_iso, iso_fn))
    else:
        shutil.copyfile(iso, boot_iso)

############# install grub #############

print("installing grub to {} for {} ...".format(boot, disk))

grub_cfg = None
for grub in ['grub', 'grub2']:
    grub_cmd = grub + '-install'
    if shutil.which(grub_cmd) != None:
        grub_cfg = boot + '/' + grub + '/grub.cfg'
        break

if grub_cfg == None:
	print("No grub installer found!")
	exit(1)

def blk_tag(tag, dev):
    r = subprocess.check_output(["blkid", "-s", tag, dev])
    return r.strip().split('=')[1].replace('"', '')

pttype = blk_tag('PTTYPE', disk)
print("{} partition type: {}".format(disk, pttype))

if pttype == 'gpt':
    grub_cmd += ' --target=x86_64-efi'

    fd = os.popen('parted ' + disk + ' print')
    for line in fd:
        fields = line.strip().split()
        

# if [ $pttype = "gpt" ]; then
# 	grub_cmd="$grub_cmd --target=x86_64-efi"

# 	esp=`parted $disk print | awk '/boot.*esp/{print $1}'`
# 	num='^[0-9]+$'
# 	if ! [[ "$esp" =~ $num ]]; then
# 		echo "ESP partition not found!"
# 		exit 1
# 	fi
# 	umount $disk$esp 2>/dev/null
# 	mkdir -p $boot/efi
# 	mount $disk$esp $boot/efi
# 	#rm -rf $boot/efi/EFI
# else
# 	grub_cmd="$grub_cmd --target=i386-pc"
# fi

# rm -rf $boot/grub $boot/grub2

# $grub_cmd --boot-directory=$boot $disk || exit 1

# echo "Generating $grub_cfg ..."
# echo "GRUB_TIMEOUT=5" > $grub_cfg
# if [ $pttype = "gpt" ]; then
# 	echo "insmod part_gpt" >> $grub_cfg
# fi
# echo "insmod ext2" >> $grub_cfg

# for iso_fn in ${iso_list[@]}
# do
# 	label=`blk_tag LABEL $boot_iso/$iso_fn`
# 	if [ -z "$label" ]; then
# 		echo "'$boot_iso/$iso_fn' is NOT a valid ISO image!"
# 		#rm -vf $boot_iso/$iso_fn
# 		echo
# 		continue
# 	fi

# 	echo "generating menuentry for $label ..."
# 	case "$label" in
# 		RHEL* | CentOS* | OL* | Fedora*)
# 			uuid=`blk_tag UUID $part`
# 			linux="isolinux/vmlinuz repo=hd:UUID=$uuid:/iso/"
# 			initrd="isolinux/initrd.img"
# 			;;

# 		Ubuntu* | Deiban*)
# 			linux="casper/vmlinuz.efi boot=casper iso-scan/filename=/iso/$iso_fn"
# 			initrd="casper/initrd.lz"
# 			;;
# 		*)
# 			echo "Warning: distribution '$label' not supported (skipped)!"
# 			continue
# 			;;
# 	esac

# 	cat >> $grub_cfg << _OEF_

# menuentry 'Install $label' {
# 	set root='hd0,$index'
# 	loopback lo /iso/$iso_fn
# 	linux (lo)/$linux
# 	initrd (lo)/$initrd
# }
# _OEF_

# done

# if [ $pttype = "gpt" ]; then
# 	umount $boot/efi
# fi

# echo
