import subprocess

#for i in range(255):
#    command=['ping', '-c', '1','-W','100', '10.5.0.'+str(i)]
#    subprocess.call(command)

arpa = subprocess.check_output(("arp", "-a")).decode("ascii")
n_devices=len([x for x in arpa.split('\n') if '10.0.0.' in x and  
    all(y not in x for y in ['10.0.0.1 ','10.0.0.255']) ])
print(n_devices)