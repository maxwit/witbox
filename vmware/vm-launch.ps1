$vmdk = "d:\vmdk"

$args = @("-n", "-q", "-x", "")

foreach ($dir in Get-ChildItem $vmdk) {
    foreach ($vmx in Get-ChildItem $vmdk\$dir) {
       if ($vmx.Extension.Equals('.vmx')) {
           $args[-1] =  $vmx.FullName # "-n -q -x $vmx.FullName"
           & "C:\Program Files (x86)\VMware\VMware Workstation\vmware.exe" $args
           break
       }
    }
}
