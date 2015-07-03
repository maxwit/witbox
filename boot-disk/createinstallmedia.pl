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
	if ($mnt[1] eq $root) {
		$part = $mnt[0];
		print "$part\n";
		last;
	}
}

close $fh;

if ($part eq "") {
	die "No such mount point found! $root\n";
}

my $disk = $part;
$disk =~ s/\d+$//g;
print "$disk\n";

my $index = $part;
$index =~ s/^\D+//g;
print "$index\n";

my $boot = "$root/boot";
my $root_iso = "$root/iso";
system("mkdir -vp $boot $root_iso");
print "$boot\n";
print "$root_iso\n";

################ copy ISO ###############

if ( -f $repo ) {
	my $iso_list = $repo;
} elsif ( -s $repo ) {
	my @iso_list = `ls $repo/*.iso`;
} else
	die "$repo is invalid!";

use File::Basename;

foreach my $iso (@iso_list) {
	my $fn = basename $iso;
	if ( ! -e "$root_iso/$fn" )
		system("cp -v $iso $root_iso");
}

############## install grub #############
print "installing grub to $boot for $disk ...";

`which grub2-install`;
if ( $? = 1 ) {
    my $grub_cmd = "grub2-install";
    my $grub_cfg = "$boot/grub2/grub.cfg";
} else {
    my $grub_cmd = "grub-install";
    my $grub_cfg = "$boot/grub/grub.cfg";
}

my @parted = `parted $disk print`;
my @tbl = split /\s+/, $parted[3];
print "$tbl[2]\n";
my $table = $tbl[2];  

if ( $table eq "gpt" ) {
	$grub_cmd = "$grub_cmd --target=x86_64-efi";
  
	@tbl = split /\s+/, $parted[8];
	print "$tbl[10]\n";
	my $esp = $tbl[10];  
	if ( -z $esp ) {
	die "ESP partition not found!";
	}
	system("umount $disk$esp 2>/dev/null");
	system("mkdir -p $boot/efi");
	system("mount $disk$esp $boot/efi");
} else {
	$grub_cmd = "$grub_cmd --target=i386-pc";
}
system("$grub_cmd --boot-directory=$boot $disk");

print "Generating $grub_cfg ...";
system("echo 'GRUB_TIMEOUT=5' > $grub_cfg");
if ( $table eq "gpt" ) {
	system("echo 'insmod part_gpt' >> $grub_cfg");
}

foreach $iso (`ls $root_iso/*.iso`) {
	$fn = basename $iso;

	my $dist = `blkid $iso`;
	$dist =~ s/.*\sLABEL="(.*?)".*/\1/;
	if ( $dist eq "") {
		print "$iso is NOT a valid ISO image!";
		print "\n";
		next;
	}

	print "generating menuentry for $dist ...";

	if ( $dist =~ "RHEL*" || $dist =~ "Centos*" || $dist =~ "OL*" || $dist =~ "Fedora*" ) {
		my $uuid = `blkid $part`;
		$uuid =~ s/.*\sUUID="(.*?)".*/\1/;
		my $linux = "isolinux/vmlinuz repo=hd:UUID=$uuid:/iso/";
		my $initrd = "isolinux/initrd.img";
	} elsif ( $dist =~ "Ubuntu*" || $dist =~ "Deiban*" ) {
		my $linux = "casper/vmlinuz.efi boot=casper iso-scan/filename=/iso/$fn";
		my $initrd = "casper/initrd.lz";
		#	*)
	} 
	print "Warning: distribution $dist not supported (skipped)!";
	next;

	use 5.010;
   	open $fh, '>', "$grub_cfg";

	say $fh "menuentry '$dist' {";
	say $fh	"        set root='hd0,$index'";
	say $fh "	     loopback lo /iso/$fn";
	say $fh "        linux (lo)/$linux";
  	say $fh "        initrd (lo)/$initrd";
    say $fh "}";
}

print "\n";
