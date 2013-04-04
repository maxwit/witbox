from mod_python import apache

def handler(req):
	req.write("Helo, MaxWiters!\n")
	return apache.OK

apache2_mod_python
