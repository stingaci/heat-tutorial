===============================
Part II - Full Stack Deployment
===============================

By the end of this section of the tutorial you should be able to deploy an 
instance stack complete with networking access. The first portion of this 
tutorial part will mostly focus on introducing a number of new Heat resource 
types while the second portion will focus on template flexibility. 

Training Templates
==================

ex2.1.yaml
----------
  
This exercise builds on top of the partI templates by adding the necessary 
components to orchestrate the deployment of a full network stack alongside the 
instance and volume deployment. 

**Notes**

The seasoned Openstack user knows that an Openstack networking stack requires 
the following three components: a router, a network, and a subnet. Within this 
template, these three components are defined as follows:

.. code:: yaml

  ..
  router:
    type: OS::Neutron::Router
    properties:
      name: { get_param: router_name }
      external_gateway_info:
        network: { get_param: public_network_id }

  net:
    type: OS::Neutron::Net
    properties:
      name: { get_param: network_name }

  subnet:
    type: OS::Neutron::Subnet
    properties:
      name: { get_param: subnet_name }
      cidr: 10.0.56.0/24
      enable_dhcp: true
      dns_nameservers:
        - 8.8.8.8
      network_id: { get_resource: net }

  router_interface_add:
    type: OS::Neutron::RouterInterface
    properties:
      router_id: { get_resource: router }
      subnet_id: { get_resource: subnet }
  ..

The router is a resource of type `OS::Neutron::Router 
<http://docs.openstack.org/developer/heat/template_guide/openstack.html#OS::Neutron::Router>`_. 
Its name is supplied as an input parameter and the only other property it has 
is the *external_gateway_info* which points to the UUID of the public network. 

The network definition is a resource of type `OS::Neutron::Net 
<http://docs.openstack.org/developer/heat/template_guide/openstack.html#OS::Neutron::Net>`_ 
and the only property it has is its name which is supplied as an input 
parameter. 

The next component in the network stack is the subnet definition of 
type `OS::Neutron::Subnet 
<http://docs.openstack.org/developer/heat/template_guide/openstack.html#OS::Neutron::Subnet>`_. 
Within this resource definition, we specify the name (as an input parameter), 
the CIDR of the subnet, the enable_dhcp flag is set to true, 8.8.8.8 is used as 
a DNS nameserver and lastly we associate this subnet with the previously 
defined network via the *get_resource* intrinsic function. 

The last component 
of this stack is adding the subnet to the router as interface. This is done via 
a resource definition of type `OS::Neutron::RouterInterface 
<http://docs.openstack.org/developer/heat/template_guide/openstack.html#RouterInterface>`_ 
and the use of the *get_resource* function. 

The next component of a full application stack is a Security Group allowing 
specific traffic protocols on specific ports to our application:

.. code:: yaml

  security_group:
    type: OS::Neutron::SecurityGroup
    properties:
      description: Add security group rules for server
      name: { get_param: security_group_name }
      rules:
        - remote_ip_prefix: 0.0.0.0/0
          protocol: tcp
          port_range_min: 22
          port_range_max: 22
        - protocol: icmp 

The security group is a resource definition of type `OS::Neutron::SecurityGroup 
<http://docs.openstack.org/developer/heat/template_guide/openstack.html#OS::Neutron::SecurityGroup>`_. 
The name properity is supplied as user input while the rules property is a list 
of hardcoded rules for the tcp protocol (which specifies a remote IP Prefix and 
a port range min and max) as well as the icmp protocol. This component will 
allow us to ping and ssh into our instance. 

The next component of a full application stack is the instance and instance 
port definition:

.. code:: yaml

  instance_port:
    type: OS::Neutron::Port
    properties:
      network_id: { get_resource: net }
      security_groups:
        - { get_resource: security_group }

  instance:
    type: OS::Nova::Server
    properties:
      name: ex2.1
      image: { get_param: image }
      flavor: { get_param: flavor }
      key_name: { get_param: ssh_key }
      networks:
        - port: { get_resource: instance_port }

The neutron port is a resource definition of type `OS::Neutron::Port 
<http://docs.openstack.org/developer/heat/template_guide/openstack.html#OS::Neutron::Port>`_. 
The network_id property specifies which network this port should connect to and 
the security_groups property specifies which security groups should be 
associated with this port. 

Lastly the instance definition has the port 
attribute of the networks attribute linked to the port we just created via the 
*get_resource* function. The instance port could've been intrinsically defined 
by directly specifying the network and security group directly in the instance 
definition as was done in partI, however the port is easier referenced and 
logically separates the networking component of the instance definition. 

In order to access this instance, a floating IP must be associated with 
this instance: 

.. code:: yaml

  floating_ip:
    type: OS::Neutron::FloatingIP
    properties:
      floating_network: { get_param: public_network_id }

  floating_ip_assoc:
    type: OS::Neutron::FloatingIPAssociation
    properties:
      floatingip_id: { get_resource: floating_ip  }
      port_id: { get_resource: instance_port }

The floating IP is a resource definition of type `OS::Neutron::FloatingIP 
<http://docs.openstack.org/developer/heat/template_guide/openstack.html#OS::Neutron::FloatingIP>`_ 
with its only attribute specifying which public network the floating IP belongs 
to. 

Lastly, in order to associate an floating IP to an instance, a resource 
definition of type `OS::Neutron::FloatingIPAssociation 
<http://docs.openstack.org/developer/heat/template_guide/openstack.html#OS::Neutron::FloatingIPAssociation>`_ 
is used which references the floating IP that was previously created and the 
instance port. If we had elected to not define an instance port explicitly as 
previously discussed, the port_id attribute could've referenced the instance 
port via the following value: 

.. code:: yaml

  { get_attr: [instance, addresses, { get_param: network_name} ,0 , port] } 

The reader should be familiar with the rest of the template. Upon successful 
deployment, the user should determine the floating IP of the deployed instance 
via the stack outputs and confirm he can ssh into the instance. 

The reader is encouraged to deploy another version of this stack using a different 
stack name and notice that although the stack deployment was successful, 
performing a *openstack network list* or a *nova list* command will result in 
ambiguous resources as they all share the same name. The next exercise will 
address this issue. 

**Deployment**

This template can be deployed as follows:

.. code:: bash

  $ openstack stack create -t ex2.1.yaml --parameter public_network_id=<public_network_id>--parameter instance_name=full_stack ex2.1

ex2.2.yaml
----------

This exercise introduces the *str_replace* and *repeat* intrinsic functions to 
illustrate further flexibility tools of HOT templates


**Notes** 

As discussed in the last point of the previous exercise, if deploying multiple 
stacks with equivalent resources names there will not be a naming conflict (as 
openstack uses UUID as the primary key), and it may become very conffusing 
later on if you need to make any changes or reference the resource by name in 
another template. However, having to specify the name for each resource (as an 
input parameter) may become tedious as well. Using the *application_name* input 
parameter all of the names for the rest of the stack resources will be 
automatically generated via the use of the `str_replace 
<http://docs.openstack.org/developer/heat/template_guide/hot_spec.html#str-replace>`_ 
intrinsic function. The *str_replace* function dynamically constructs strings 
by providing a template string with placeholders and a list of mappings to 
assign values to those placeholders at runtime. Take the router name attribute 
definition as an example:

.. code:: yaml

  name:
    str_replace:
      template: $app_name_router
      params:
        "$app_name": { get_param: application_name }

The template attribute of the *str_replace* function is the raw text that will 
be used while the params attribute is a map containing entries of the following format 
*parameter: value*. In this example the string $app_name in the template will 
be replaced by the value of the $app_name parameter defined in the params 
section (which is generated via the *get_param* function), and thus the name 
attribute will evaluate to something similar to *my_app_name_router*. 

Another great intrinsic function is the `repeat 
<http://docs.openstack.org/developer/heat/template_guide/hot_spec.html#repeat>`_ 
intrinsic function. Consider the following situation: your template requires 
different multiple ports to be open for each deployment. Instead of directly 
modifying the template for every deployment the *repeat* function can be used 
to dynamically create a rule for each port. Generally, the repeat function 
allows for dynamically transforming lists by iterating over the contents of one 
or more source lists and replacing the list elements into a template. The 
result of this function is a new list, where the elements are set to the 
template, rendered for each list item. The *security_group* resource definition 
in this exercise looks as follows:

.. code:: yaml

  security_group:
    type: OS::Neutron::SecurityGroup
    properties:
      description: Add security group rules for server
      name:
        str_replace:
          template: $app_name_sg
          params:
            "$app_name": { get_param: application_name }
      rules:
        repeat:
          for_each:
            $port: { get_param: ports }
            $protocol: { get_param: protocols }
          template:
            protocol: $protocol
            port_range_min: $port
            port_range_max: $port
            remote_ip_prefix: 0.0.0.0/0

The *for_each* property of the repeat function contains all of the parameters 
that will be replaced in the *template* section (similar to the *str_replace* 
function). These parameters need to be of type *comma_delimited_list* if 
supplied as input parameters (see definition for the ports and protocols input 
parameters). The repeat function will iterate over all combinations of the 
parameters (think nested for loops) and for each combination of parameters it 
will create a list entry by replacing the parameters within the template 
section. 

Upon successful deployment, the reader is encouraged to investigate the names 
for all the resources created as part of the stack and validate the output of 
the *str_replace* function. Lastly, the reader is also encouraged to validate 
the rules created within the security group for this stack. 

**Deployment**

.. code:: bash

  $ os stack create -t ex2.2.yaml --parameter public_network_id=<public_network_id> --parameter application_name=full_stack ex2.2

Clean up
========

You can clean up each stack we defined throughout this tutorial as follows:

.. code:: bash
  $ openstack stack delete <stack_name>
