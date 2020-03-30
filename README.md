# jupyterhub
This repo will give you the basics to install Jupyterhub 
using pure flashblade as a file system to mount all PVC from.

more instructions to come. 


step 1

run the jhubpvc.yaml to create a Persistant volume and Persistant volume claim

note you need to edit the files to point to your flashblade data vip, and your 

file system. 


Step 2

edit the values in your config.yaml to reflect entries in your PVC


Step 3

run the jhub installer to install jupyterhub using the config file

Step 4

run the Python patch to address python bugs associated with jhub



