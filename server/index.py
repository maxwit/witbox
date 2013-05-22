import os;
from mod_python import apache

def handler(req):
	handler = req.uri[1:];
	if handler[-3:] == ".py" :
		handler = handler[0:-3];
		if not handler == "index" :
			req.add_handler("PythonHandler", handler);
	return apache.OK;
