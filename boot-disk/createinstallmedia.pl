#!/usr/bin/perl -w

if ($> != 0) {
 	die "must run as root!"
}

my $root;
my $repo;

if ($#ARGV == 0) {
	$root = shift(@ARGV);
	$repo = "$root/iso";
} elsif ($#ARGV == 1) {
	$repo = shift(@ARGV);
	$root = shift(@ARGV);
} else {
	die "usage: createinstallmedia [iso path] <mount point>"
}

$root =~ s:/+$::;
my $part = "";

open my $fh, '<', "/proc/mounts" or die "fail to open mounts!\n";

foreach (<$fh>) {
	my @mnt = split /\s/;
	if ($mnt[1] =~ $root) {
		$part = $mnt[0];
		print "$part\n";
		last;
	}
}

close $fh;
#--------------------------------------
#--------------------------------------
if ($part eq "") {
	die "No such mount point found! $root\n";
}

$disk = $part;
$disk =~ s/\d//g;
print "$disk\n";

$index = $part;
$index =~ s/\D//g;
print "$index\n";

$boot = "$root/boot";
$root_iso = "$root/iso";
system("mkdir -vp $boot $root_iso");
print "$boot\n";
print "$root_iso\n";

################ copy ISO ###############
if ( -f $repo ) {
	$iso_list = $repo;
} elsif ( -s $repo ) {
	@iso_list=`ls $repo/*.iso`;
} else
	die "$repo is invalid!";

use File::Basename;

foreach $iso (@iso_list) {
	$fn = basename $iso;
	if ( ! -e "$root_iso/$fn" )
		system("cp -v $iso $root_iso");
}

############## install grub #############
print "installing grub to $boot for $disk ...";

`which grub2-install`;
if ( $? = 1 ) {
    $grub_cmd = "grub2-install";
    $grub_cfg = "$boot/grub2/grub.cfg";
} else {
    $grub_cmd = "grub-install";
    $grub_cfg = "$boot/grub/grub.cfg";
}

#table=`parted $disk print | awk '{if ($1 == "Partition") {print $3}}'`
if ( $table eq "gpt" ) {
	$grub_cmd = "$grub_cmd --target=x86_64-efi";

#	esp=`parted $disk print | awk '{if ($1 >= 1 && $1 <=128 && $8 == "esp") {print $1} }'`
	if ( -z $esp ) {
	die "ESP partition not found!";
	}
#	umount $disk$esp 2>/dev/null
system("mkdir -p $boot/efi");
system("mount $disk$esp $boot/efi");
} else {
	$grub_cmd = "$grub_cmd --target=i386-pc";
}
system("$grub_cmd --boot-directory=$boot $disk");

print "Generating $grub_cfg ...";
#echo "GRUB_TIMEOUT=5" > $grub_cfg
if ( $table eq "gpt" ) {
#	echo "insmod part_gpt" >> $grub_cfg
}
for $iso in `ls $root_iso/*.iso` {
	$fn = basename $iso;

#	$dist = `blkid $iso | perl -p -e 's/.*\sLABEL="(.*?)".*/\1/'`
#	if [ -z "$dist" ]; then
#		echo "'$iso' is NOT a valid ISO image!"
#		echo
#		continue
#	fi
#
#	echo "generating menuentry for $dist ..."
#	case "$dist" in
#	RHEL* | CentOS* | OL* | Fedora*)
#		uuid=`blkid $part | perl -p -e 's/.*\sUUID="(.*?)".*/\1/'`
#		linux="isolinux/vmlinuz repo=hd:UUID=$uuid:/iso/"
#		initrd="isolinux/initrd.img"
#		;;
#
#	Ubuntu* | Deiban*)
#		linux="casper/vmlinuz.efi boot=casper iso-scan/filename=/iso/$fn"
#		initrd="casper/initrd.lz"
#		;;
#	*)
#		echo "Warning: distribution $dist not supported (skipped)!"
#		continue
#		;;
#	esac
#
#cat >> $grub_cfg << OEF
#
#menuentry '$dist' {
#	set root='hd0,$index'
#	loopback lo /iso/$fn
#	linux (lo)/$linux
#	initrd (lo)/$initrd
#}
#OEF
#
#done
#
#echo
