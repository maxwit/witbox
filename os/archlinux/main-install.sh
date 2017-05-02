#!/usr/bin/env bash

user=archuser
pass=ArchLinux`date +%Y`

function usage {
  # echo "install.sh [options]"
  echo "options:"
  echo "  -u user          default is '$user'"
  echo "  -p password      default is '$pass'"
  # echo "  -h hostname"
  echo "  -h this help"
  echo
}

while [[ $# -gt 0 ]]; do
	case $1 in
		-u|--user )
			user=$2
			shift
			;;
    -p|--password )
      pass=$2
      shift
      ;;
    # -f|--full-name )
    #   name="$2"
    #   ;;
		-h )
			usage
			exit 0
			;;
		* )
			echo "invalid option '$1'"
			usage
			exit 1
			;;
	esac

	shift
done

if [ $UID != 0 ]; then
	echo "must run as root!"
	exit 1
fi

# TODO: check chroot env

name=${user^} # FIXME

ln -svf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hwclock --systohc --utc
sed -i 's/^#\(en_US.UTF-8\)/\1/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

pkg_list=(base-devel openssh syslog-ng grub vim bash-completion alsa-utils)

if [ -d /sys/firmware/efi ]; then
  mkdir -p /boot/efi
  mount LABEL=ESP /boot/efi
  pkg_list+=(efibootmgr)
fi

pkg_list+=(xorg xorg-xinit xorg-twm xterm mesa-demos mesa-vdpau)
pkg_list+=(gnome gnome-extra gnome-tweak-tool)

for (( i = 0; i < 10; i++ )); do
  pacman -S --noconfirm ${pkg_list[@]} && break
  echo
done

# pacman -R --noconfirm vi
# ln -sf vim /bin/vi

echo -e "$pass\n$pass" | passwd

useradd -m -G wheel -c "$name" $user && \
  echo -e "$pass\n$pass" | passwd $user

# TODO
sed -i 's/^#\s\(%wheel.*NOPASSWD\)/\1/' /etc/sudoers

mkinitcpio -p linux

hn=WitBox
# hostnamectl set-hostname $hn
echo $hn > /etc/hostname
sed -i "s/\(^127.0.0.1.*localhost$\)/\1 $hn/" /etc/hosts

# auto login
grep AutomaticLoginEnable /etc/gdm/custom.conf > /dev/null || \
  sed -i "/^\[daemon\]/a AutomaticLoginEnable=true\nAutomaticLogin=$user" /etc/gdm/custom.conf

systemctl enable syslog-ng dhcpcd
systemctl enable gdm NetworkManager

# FIXME
vmware='1'
if [[ $vmware == '1' ]]; then
  for (( i = 0; i < 10; i++ )); do
    pacman -S --noconfirm xf86-input-vmmouse xf86-video-vmware gtkmm open-vm-tools && break
    echo
  done

  cat /proc/version > /etc/arch-release
  sed -i 's/^#\(WaylandEnable\)/\1/' /etc/gdm/custom.conf

  requires=vmware-vmblock-fuse
  temp=`mktemp`
  cat > $temp << __EOF__
[Unit]
Description=VMware Shared Folders
Requires=$requires.service
After=$requires.service
ConditionPathExists=/mnt/hgfs
ConditionVirtualization=vmware

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/vmhgfs-fuse -o allow_other -o auto_unmount .host:/ /mnt/hgfs

[Install]
WantedBy=multi-user.target
__EOF__

  mkdir -p /mnt/hgfs
  cp $temp /etc/systemd/system/hgfs.service
  rm $temp
  systemctl enable hgfs
fi

grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

# __END_OF_MAIN_INSTALL_SCRIPT__
