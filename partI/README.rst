===========
Heat Basics
===========

Prerequisites
=============

This part of the tutorial requires a predefined network, subnet, and a publicly 
accessible machine connected to the previously mentioned network. All of the 
deployments in this part of the tutorial will deploy instances connected to 
that private network and we will utilize the publicly accessible machine as a 
jump host to the other instances. 

Setup
=====

The reader can either choose to deploy their own prerequisite 
resources or they can use the setup.yaml stack template to automatically do so. 
By default the setup definition expects a keypair named heat_key to be 
available on this tenant and it also expects the public network id to be 
supplied as input to the stack create command. The setup file can be deployed 
as follows: 

.. code:: bash

  $ openstack stack create -t setup.1.yaml --parameter public_network_id=$PUBLIC_NETOWRK_ID setup

You can now monitor the stack status with:
  
.. code:: bash

  $ openstack stack list 

When the stack status reaches *CREATE_COMPLETE*, run the following command to 
determine the floating IP for the *jumphost*:

.. code:: bash

  $ openstack stack output show setup jumphost_ip

Lastly, check if you can ssh into the instance and if so use scp to put the 
heat_key private key onto that server as we'll need it to log in to other 
instances we'll be deploying throughout this part of the tutorial. 

Training Templates
==================

ex1.1.yaml
---------------
  
This template aims to introduce the basic syntax for a HOT template in its most 
simple form. This is a single instance deployment with hard coded values for 
every attribute and does not use any intrinsic functions. 

**Notes**

This template contains three template sections as described below: 

`heat_template_version <http://docs.openstack.org/developer/heat/template_guide/hot_spec.html#hot-spec-template-version>`_
  This template section specifies which version of features (and format) this 
  template is describing. This tutorial will use the 2015-10-15 version 
  (liberty). Each version date is directly correlated with each Openstack 
  release cycle, and will support different features based on that version. 

`description <http://docs.openstack.org/developer/heat/template_guide/hot_spec.html#template-structure>`_
  This template section simply serves as a short paragraph describing what the 
  template is for 

`resources <http://docs.openstack.org/developer/heat/template_guide/hot_spec.html#resources-section>`_
  This template section is a mandatory attribute and it contains the 
  specifications for each resource this template will deploy alongside any 
  configuration details that each resource will require to be deployed

Within the resource section, there is a resource definition of type 
`OS::Nova::Server <http://docs.openstack.org/developer/heat/template_guide/openstack.html#OS::Nova::Server>`_. 
Each resource definition has a number of properties; some are required and some 
are optional as described in the documentation for each resource type. In this 
particular exercise we define a Nova Server instance with a particular 
key name, image, flavor, network and security group. All the values for these 
properties are hard coded. 

Upon successful deployment of this template, the reader can validate the 
instance was deployed by using the *nova list* command to identify the IP 
address of the deployed instance and using the jumphost to ssh or ping the 
deployed instance. 

**Deployment** 

This template can be deployed as follows:

.. code:: bash

  $ openstack stack create -t ex1.1.yaml ex1.1


ex1.2.yaml
----------

This template introduces parameters and intrinsic functions and how one can use 
this to formulate more flexible templates. It will showcase most of the 
parameter properties and how to supply them from command line as well as the 
`get_param <http://docs.openstack.org/developer/heat/template_guide/hot_spec.html#get-param>`_ 
intrinsic function. 

**Notes**

This template contains the following new template section:

`parameters <http://docs.openstack.org/developer/heat/template_guide/hot_spec.html#parameters-section>`_
  This template section allows for the user to specify input parameters to the 
  template while creating the stack. It's purpose is to allow for writing 
  generic templates that can be customized at run time via user input. 

Each parameter definition in the parameters section contains a number of 
attributes, some optional and some required. The *type* and *parameter name* 
are required attributes. Within this exercise, the *label* (human readable name 
for the parameter), *description* (human readable description for the 
parameter), and *default* (a default value attribute for the parameter) are 
also used. The reader is encouraged to read the documentation for the 
parameters section. Parameters are supplied as switches to the *stack create* 
command in the following format:

.. code:: bash

  $ openstack stack create -t template.yaml --parameter param1=param1_value --parameter param2=param2_value stack_name

Within the resource definition the `get_param 
<http://docs.openstack.org/developer/heat/template_guide/hot_spec.html#get-param>`_ 
intrinsic function is used to reference the parameters defined in the 
parameters section and resolve to their value in the resource definition. 
Generally, `intrinsic functions 
<http://docs.openstack.org/developer/heat/template_guide/hot_spec.html#intrinsic-functions>`_ 
are used to perform specific tasks, such as getting the value of a resource 
attribute at runtime. Each intrinsic function will be documented upon its first 
appearance in the tutorial. 

Within this exercise all parameters except the *security_group* parameter have 
default values. Attempting to deploy this template without specifying this 
parameter will result in a failure before the stack is even created, namely: 
*The Parameter (security_group) was not provided.*. 

Following a successful deployment of this template with the correct parameters 
the reader is encouraged to delete the stack (*openstack stack delete ex1.2*), 
and attempt to redeploy with an invalid input value for the *security_group* 
parameter (ie. a non existent security group). This action will cause the 
*stack create* command to succeed however the stack status will result in a 
*CREATE_FAILED* state. Using the *stack show <stack name>* command, the reason 
for this failure can be found in the *stack_status_reason* attribute of the 
command output, namely: *Unable to find security_group with name <bad name>*. 

**Deployment**

This template can be deployed as follows:

.. code:: bash

  $ openstack stack create -t ex1.2.yaml --parameter image="Centos 7" ex1.2

ex1.3.yaml
----------

This template introduces the constraints attribute of the parameters section 
and how they can be used to validate the template parameters pre-deployment. It 
also aims to illustrate that a resource is not necessarily an Openstack object 
(ie. Nova instance, Cinder volume) but it can also be an association between 
two resources (ie. assigning a cinder volume to an instance). Lastly, the 
template outputs section is also used here.

**Notes**

The following new template section is introduced in this exercise:

`outputs <http://docs.openstack.org/developer/heat/template_guide/hot_spec.html#outputs-section>`_
  The outputs section specifies which resource attributes should be available 
  to the user post deployment. The value of the output is usually resolved with 
  the get_attr function.

This exercise deploys an instance with a cinder volume attached. The instance 
has the typical definition, while the volume definition is of type 
`OS::Cinder::Volume <http://docs.openstack.org/developer/heat/template_guide/openstack.html#OS::Cinder::Volume>`_. 
The reader should notice that the association between the Cinder volume 
definition and the instance is done via another resource definition, namely: 
`OS::Cinder::VolumeAttachment 
<http://docs.openstack.org/developer/heat/template_guide/openstack.html#OS::Cinder::VolumeAttachment>`_. 
Within the *VolumeAttachment* resource definition, the `get_resource 
<http://docs.openstack.org/developer/heat/template_guide/hot_spec.html#get-resource>`_ 
intrinsic function is used to resolve the uuid of the instance as well as the 
uuid of the volume. Generally the *get_resource* intrinsic function is used to 
return the uuid of a resource defined **within the current template** while 
also creating a dependency between the resource calling the function and the 
resource passed as an input to the function.

The reader will notice that some parameters have an extra attribute definition, 
namely `constraints 
<http://docs.openstack.org/developer/heat/template_guide/hot_spec.html#parameter-constraints>`_. 
This attribute imposes certain constraints on the input value specified by the 
user (ie. a range for a parameter of type number). The more interesting type of 
constraint is a `custom constraint 
<http://docs.openstack.org/developer/heat/template_guide/hot_spec.html#custom-constraint>`_. 
Custom constraints are used to validate the existence of a specified resource 
in the backend prior to attempting template deployment, thus introducing a 
further template validation tool. 

Lastly, the outputs section allows for the user to specify what the template 
should output at the end of the deployment. The `get_attr 
<http://docs.openstack.org/developer/heat/template_guide/hot_spec.html#get-attr>`_ 
intrinsic function is used to extract resource attributes (as documented in 
each resource specification) for populating the output values of the stack. The 
outputs of a stack can be gathered after the stack reaches a  
*CREATE_COMPLETE* state using the following command:

.. code:: bash

  $ openstack stack output show <stack name> --all

Upon successful stack deployment, the reader can validate that the instance was 
created and the cinder volume was attached by logging in to the instance (via 
the jumphost) and running *sudo fdisk -l* and finding the 1GB disk listing. 

**Deployment** 

This template can be deployed using the following command:

.. code:: bash

  $ openstack stack create -t ex1.3.yaml ex1.3 

**Extras** 

Although the *neutron.security_group* is listed as a custom constraint in the 
documentation, it is only part of the Mitaka template version. The 
documentation seems to lack what template version each custom constraint 
belongs to. Custom constraints can be very useful when referencing other 
instances or Openstack resources (by UUID) for example. That being said, it's 
still best practice to specify them wherever it is applicable for readability 
and extra validation purposes.  

Clean up
========

You can clean up each stack we defined throughout this tutorial as follows:

  ``$ openstack stack delete <stack_name>``

The reader should try and delete the *setup-stack* before deleting the other 
stacks and notice that the stack deletion failed due to dependencies from other 
running stacks. You can view more information regarding the stack status by 
running:

  ``$ openstack stack show <stack_name>``

and pay close attention to the *stack_status_reason* attribute of the result. 
