#!/bin/sh

sudo add-apt-repository ppa:mactel-support && \
sudo apt-get update && \
sudo apt-get dist-upgrade -y && \
#nvidia-current nvidia-settings v86d
sudo apt-get install -y bcm5974-dkms xserver-xorg-input-synaptics || \
{
	echo "$0: update failed!"
	exit 1
}

grep "GRUB_CMDLINE_LINUX_DEFAULT.*reboot" /etc/default/grub || \
{
	cp -v /etc/initramfs-tools/modules /tmp/init-modules
	echo "uvesafb mode_option=1280x800-24 mtrr=3 scroll=ywrap" >> /tmp/init-modules
	sudo cp -v /tmp/init-modules /etc/initramfs-tools/modules

	echo FRAMEBUFFER=y | sudo tee /etc/initramfs-tools/conf.d/splash

	cp -v /etc/default/grub /tmp/
	sudo sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT="\).*"/\1nomodeset video=uvesafb:mode_option=1280x800-24,mtrr=3,scroll=ywrap reboot=pci"/' /etc/default/grub
	sudo update-grub

	sudo update-initramfs -u
}

grep mbp55 /etc/modprobe.d/alsa-base.conf || \
{
	cp -v /etc/modprobe.d/alsa-base.conf /tmp
	echo "options snd-hda-intel model=mbp55" >> /tmp/alsa-base.conf
	sudo cp -v /tmp/alsa-base.conf /etc/modprobe.d/
}
