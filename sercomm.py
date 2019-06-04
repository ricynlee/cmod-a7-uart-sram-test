# -*- encoding : utf8 -*-

import serial
from sys import argv
#from threading import Thread
#from Queue import Queue as queue
from re import sub as replace, M as MULTILINE

## Cmdline arg parser
PORT = "COM14" #LOCATOR# #DO NOT MANUALLY MODIFY
BAUD = 12000000 #LOCATOR# #DO NOT MANUALLY MODIFY
DATA = ""

def parse_port(arg):
    global PORT, BAUD
    def parse_port_name(s):
        if "COM" == s[:3].upper() and s[3:].isdigit():
            if int(s[3:])<64:
                return s.upper()
            else:
                # "Invalid com number"
                return None
        else:
            # "Cannot recognize port name"
            return None
    
    def parse_port_baud(s):
        try:
            baud = int(s)
        except:
            # "Unrecognizable baud"
            return None
            
        if baud in [9600, 57600, 115200, 921600, 1843200, 12000000]:
            return baud
        else:
            # "Invalid baud"
            return None
    
    arg = arg.split(',')
    port = parse_port_name(arg[0])
    if port:
        PORT = port
    else:
        return False

    if len(arg)>1:
        baud = parse_port_baud(arg[1])
        if baud:
            BAUD = baud
    
    return True
    
def parse_data(arg):
    global DATA
    try: # array
        if arg[0]=='(' and arg[-1]==')':
            arg = arg[1:-1]
            data = bytearray([eval(b) for b in arg.split(',')])
        else:
            raise Exception
    except: # string
        data = arg
            
    DATA = data

## Parse cmdline args
if len(argv)>1:
    if parse_port(argv[1]):
        try: # try remembering ser port cfg
            pyfile = open(argv[0], "r")
            pycode = pyfile.read()
            pyfile.close()
            pycode = replace(r"PORT = \"\w+\" #LOCATOR#", "PORT = \"%s\" #LOCATOR#" % PORT, pycode, flags=MULTILINE)
            pycode = replace(r"BAUD = \d+ #LOCATOR#", "BAUD = %d #LOCATOR#" % BAUD, pycode, flags=MULTILINE)
            pyfile = open(argv[0], "w")
            pycode = pyfile.write(pycode)
            pyfile.close()
        except:
            pass
    parse_data(argv[-1])
else:
    print "Usage:\033[31m %s [COMn[,BAUD]] DATA\033[0m" % argv[0]
    print "      \033[31m DATA can be \"string\" or (0x55,123,077,0b11001010)\033[0m"
    print "      \033[31m Valid COMn,BAUD combinations will be remembered\033[0m"
    print "       Now the combination is %s,%d" % (PORT, BAUD)
    exit()
    
## Port operations
ser = serial.Serial(PORT, BAUD, timeout=3)
ser.write(DATA)

print "Wait...",
echo = ""
while True:
    r = ser.read(1)
    if r:
        echo += r
    else:
        break

print "\033[2K\033[0G\033[93m" + "Got \033[91m" + str(len(echo)) + "\033[93m byte(s):\033[91m",
print ' '.join([hex(ord(c)) for c in list(echo)])
print "\033[93m" + "In text form:\033[91m",echo, "\033[0m"

ser.close()
