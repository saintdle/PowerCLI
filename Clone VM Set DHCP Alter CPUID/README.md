## PowerCLI with a GUI – Clone a machine, add DHCP Reservations, alter CPUID

This script loads a GUI that is used to clone and existing virtual machine, set a DHCP reservation based on the new VM's MAC Address, and finally configure the new VM's CPUID to mask the CPU that is known to the guest OS. 

You can read more about this script the decisions made in its design here: 
 - https://veducate.co.uk/powercli-gui-clone-machine-dhcp-cpuid/