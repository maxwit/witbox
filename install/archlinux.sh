#!/bin/sh

# Bridge

# VPN
# /usr/lib/networkmanager/nm-l2tp-service --debug

ip addr 
ping debug.live
ls /sys/firmware/efi
date
systemctl start sshd
passwd

ssh localhost
exit

ssh root@ip
cp -v /etc/pacman.d/mirrorlist{,.orig}
sed -n '/China/{p;n;p}' /etc/pacman.d/mirrorlist.orig > /etc/pacman.d/mirrorlist

cat /etc/pacman.d/mirrorlist

pacman -Sy
cfdisk /dev/sda

fdisk -l /dev/sda

mkswap -L SWAP /dev/sda2
mkfs.ext4 -L ROOT /dev/sda3

blkid

swapon LABEL=SWAP
swapon
mount LABEL=ROOT /mnt

mount

pacstrap /mnt base

ls /mnt

genfstab -U -p /mnt
genfstab -U -p /mnt >> /mnt/etc/fstab

cat /mnt/etc/fstab

arch-chroot /mnt

mount

ln -svf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hwclock --systohc --utc
sed -i 's/^#\(en_US.UTF-8\)/\1/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

locale
cat /etc/locale.conf

pacman -S openssh syslog-ng
systemctl enable sshd syslog-ng dhcpcd

systemctl list-unit-files | grep sshd

passwd

ssh localhost
exit

mkinitcpio -p linux
pacman -S grub
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

ls /boot/grub
cat /boot/grub/grub.cfg

exit
umount /mnt
reboot




ip addr
ping debug.live
systemctl status sshd
localectl status
cat /var/log/syslog.log
u=myname
useradd -G wheel -c 'Full Name' -m $u
passwd $u

ssh $u@localhost
exit

pacman -S sudo
nano /etc/sudoers
su - $u
sudo ls
exit
ssh myname@ip
sudo su -
hn=myhostname
hostnamectl set-hostname $hn
sed -i "s/\(^127.0.0.1.*localhost$\)/\1 $hn/" /etc/hosts

hostname
ping $hn

pacman -S vim
rm /bin/vi
cp /usr/bin/vim /bin/vi

vi

pacman -S base-devel git

gcc -v
git

exit
git clone https://aur.archlinux.org/package-query.git
cd package-query
makepkg -si
cd ..
git clone https://aur.archlinux.org/yaourt.git
cd yaourt
makepkg -si

yaourt tree



pacman -S xorg xorg-xinit xorg-twm xterm

startx

pacman -S gnome gnome-extra gnome-tweak-tool
systemctl enable gdm NetworkManager
reboot
