#!/usr/bin/perl -w
use 5.010;
use File::Basename;

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
	die "usage: createinstallmedia [iso path] <mount point>";
}

$root =~ s:/+$::;
my $part = "";

open my $fh, '<', "/proc/mounts" or die "fail to open mounts!\n";

foreach (<$fh>) {
	my @mnt = split /\s/;
	if ($mnt[1] eq $root) {
		$part = $mnt[0];
		last;
	}
}

close $fh;

if ($part eq "") {
	die "No such mount point found! ($root)\n";
}

my $disk = $part =~ s/\d+$//r;
my $index = $part =~ s/^$disk//r;

my $boot = "$root/boot";
my $root_iso = "$root/iso";
system("mkdir -vp $boot $root_iso");

################ copy ISO ###############
my @iso_list;
if ( -f $repo ) {
	@iso_list = $repo;
} elsif ( -s $repo ) {
	@iso_list = `ls $repo/*.iso`;
} else {
	die "$repo is invalid!";
}

foreach (@iso_list) {
	my $iso=$_;
	chomp($iso);
	my $fn = basename $iso;
	if ( ! -e "$root_iso/$fn") {
		system("cp -vp $iso $root_iso");
	}
}

############## install grub #############
print "installing grub to $boot for $disk ...\n";

my $grub_cmd = `which grub2-install`;
my $grub_cfg;

if ($grub_cmd eq "") {
    $grub_cmd = "grub-install";
    $grub_cfg = "$boot/grub/grub.cfg";
} else {
    $grub_cmd = "grub2-install";
    $grub_cfg = "$boot/grub2/grub.cfg";
}

my $table = dev_tag($disk, 'PTTYPE');  

if ( $table eq "gpt" ) {
	$grub_cmd .= " --target=x86_64-efi";

		foreach (`parted $disk print`) {
			my @mnt = split /\s+/;
			if ( $mnt[8] eq "esp" ) {
				$esp = $mnt[1]
			}
		}
	
	if ( $esp eq " " ) {
		die "ESP partition not found!";
	}
	
	system("umount $disk$esp 2>/dev/null");
	system("mkdir -p $boot/efi");
	system("mount $disk$esp $boot/efi");
} else {
	$grub_cmd = "$grub_cmd --target=i386-pc";
}

system("$grub_cmd --boot-directory=$boot $disk");

print "Generating $grub_cfg ...\n";

open $fh, '>', "$grub_cfg"; 

print $fh "GRUB_TIMEOUT=5\n";
if ($table eq "gpt") {
	print $fh "insmod part_gpt\n";
}

foreach (`ls $root_iso/*.iso`) {
	$iso=$_;
	my $fn = basename $iso;
	my $dist = dev_tag($iso, 'LABEL');
	
	if ($dist eq "") {
		print "$iso is NOT a valid ISO image!\n";
		next;
	}

	print "generating menuentry for $dist ...\n";

	my $linux;
	my $initrd;

	if ($dist =~ /RHEL|Centos|Fedora/) {
		my $uuid = dev_tag($part, 'UUID');
		$linux = "isolinux/vmlinuz repo=hd:UUID=$uuid:/iso/";
		$initrd = "isolinux/initrd.img";
	} elsif ($dist =~ /Ubuntu|Deiban/) {
		$linux = "casper/vmlinuz.efi boot=casper iso-scan/filename=/iso/$fn";
		$initrd = "casper/initrd.lz";
	} else {
		print "Warning: distribution $dist not supported (skipped)!\n";
		next;
	} 

	print $fh "menuentry '$dist' {\n";
	print $fh "    set root='hd0,$index'\n";
	print $fh "    loopback lo /iso/$fn\n";
	print $fh "    linux (lo)/$linux\n";
  	print $fh "    initrd (lo)/$initrd\n";
    print $fh "}\n";
	print $fh "\n";
}

close $fh;

sub dev_tag {
	my $dev = shift;
	my $tag = shift;
	my $value = `blkid -s $tag $dev`;
	chomp($value);
	$value =~ s/.*="(.*?)".*/$1/r;
}

