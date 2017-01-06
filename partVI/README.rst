=========================================
Vertical and Horizontal Scaling with Heat
=========================================

This is the last section of the tutorial and by the end of this section the 
reader should be able to vertically scale (increase instance resources) and 
horizontally scale (deploy a cluster of instances of the same type) any Heat 
stack. 

Prerequisites
============

This portion of the tutorial requires a network, a router, a subnet, and two
security groups.

Setup
=====

The reader can either choose to deploy their own prerequisite resources or they
can use the setup.yaml stack definition to automatically do so.  The setup file
can be deployed as follows:

.. code:: bash

  $ openstack stack create -t setup.yaml --parameter public_network_id=$PUBLIC_NETOWRK_ID setup
  
Training Templates
==================

ex6.1.yaml
----------

This exercise showcases how vertical scaling can be performed on a Heat stack 

**Notes**

The format of this template should already be familiar to the reader. This stack 
can be deployed using the following command: 

.. code:: bash

  $ openstack stack create -t ex6.1.yaml -e env.yaml ex6.1

This will launch the stack with a webserver instance of flavor: m1.small. A 
stack update operation will be performed to change the flavor of this instance 
to a larger one. The reader should note that although the instance will not be 
destroyed and recreated, it will in fact be rebooted. This will cause a service 
downtime (in our case httpd). The reader should take careful care and ensure 
that whatever packages or services were installed via SoftwareDeployemtns or 
cloud-init are marked to start at instance boot-time otherwise they will not be 
available after the instance resizing. 

**Deployment**

This template can be deployed as follows:

.. code:: bash

  $ openstack stack create -t ex6.1.yaml -e env.yaml ex6.1

and the instance be resized by performing the following stack update command:

.. code:: bash

  $ openstack stack update -t ex6.1.yaml -e env.yaml ex6.1 --parameter flavor=m1.large 


ex6.2.yaml
----------

This exercise showcases how horizontal scaling can be performed on a Heat stack

**Notes** 

Within this template, the reader will notice a new resource type, namely 
`OS::Heat::ResourceGroup 
<http://docs.openstack.org/developer/heat/template_guide/openstack.html#OS::Heat::ResourceGroup>`_ 
and it's definition looks as follows:

.. code:: yaml

  cluster:
    type: OS::Heat::ResourceGroup
    properties:
      count: { get_param: cluster_size }
      resource_def:
        type: Tutorial::Application::HTTP_FI
        properties:
          name: ex6_2.%index%
          image: { get_param: image }
          security_group_icmp: { get_param: security_group_icmp }
          security_group_web: { get_param: security_group_web }
          ssh_key: { get_param: ssh_key }
          flavor: { get_param: flavor }
          network_name: { get_param: network_name }
          message: { get_param: message }
          public_network_id: { get_param: public_network_id }

A resource of type *OS::Heat::ResourceGroup* creates one or more identically 
configured nested resources; the resource to be replicated is specified by the 
*resource_def* attribute while the number of replicas is specified by the 
*count* attribute. 

The actual resource to be replicated is of type 
*Tutorial::Application::HTTP_FI* which points to the 
*lib/applications/httpd_fi.yaml* file. The only difference between this 
application template and the regulat *httpd.yaml* application template is that 
the FloatingIP definition has been pushed within that template. The design 
pattern for utilizing ResourceGroup is to place all related resources that need 
to be replicated within the same template (ie. instance, floating IP, volumes).

Another interesting feature of ResourceGroup is the use of the *%index%* 
variable as seen in the *name* attribute. This variable lets the user reference 
the unique index associated with each replica and thus each instance will have 
a unique name. 

The outputs section is also a little different:

.. code:: yaml

  outputs:
    http_ipaddrs:
      value: { get_attr: [ cluster, floating_ip ] }

The *floating_ip* attribute is actually an output of the resource defined 
within the *resource_def* property of the *ResourceGroup* and this will 
actually be a list of every floating IP of each replica. 

As part of this exercise, the stack should be first launched with a count value 
of 1, then updated to a value of 3, and lastly updated to a value of 2. When 
downsizing a cluster, Heat will choose one instance at random to destroy (not 
necessarily the last one created). 

The reader is encouraged to validate the names of the instances as well as the 
number of instances at each step of exercise. 

**Deployment** 

This stack can be created as follows:

.. code:: bash

  $ openstack stack create -t ex6.2.yaml -e env.yaml ex6.2 --parameter cluster_size=1

Resized to a size of 3 replicas as follows:

.. code:: bash

  $ openstack stack updated -t ex6.2.yaml -e env.yaml ex6.2 --parameter cluster_size=3

And lastly, downsized to two replicas like so:

.. code:: bash

  $ openstack stack updated -t ex6.2.yaml -e env.yaml ex6.2 --parameter cluster_size=2

**Extras**

It's important to note that Vertical Scaling can also be performed on a 
Resource Group. In this case the reader can vertically scale each instance in 
the resource group by simply performing a stack update command with a different 
flavor. 

ex5.3.yaml
----------

This template deployed a cluster of webservers behind a loadbalancer (LBaaS v1) 

**Notes**

The previous exercise deployed a cluster of webservers, each with their own 
floating IP which implies they will all be used independently. Although the 
previous exercise exemplifies how a cluster of identical replicas can be 
deployed, it is not a very realistic example of how webservers are typically 
deployed. 

Within the main template of this exercise, a LoadBalancer is used to connect to 
all the webserver replicas within the ResourceGroup resource definition:

.. code:: yaml

  loadbalancer:
    type: OS::Neutron::LoadBalancer
    properties:
      pool_id: { get_resource: pool }
      protocol_port: 80

  pool:
    type: OS::Neutron::Pool
    properties:
      name: http_pool
      protocol: TCP
      subnet_id: { get_param: subnet }
      lb_method: ROUND_ROBIN
      monitors:
        - { get_resource: monitor }
      vip:
        name: http_vip
        protocol_port: 80
        session_persistence:
          type: SOURCE_IP
        subnet: { get_param: subnet }

  monitor:
    type: OS::Neutron::HealthMonitor
    properties:
      type: TCP
      delay: 5
      max_retries: 3
      timeout: 2

The loadbalancer resource is of type `OS::Neutron::LoadBalancer 
<http://docs.openstack.org/developer/heat/template_guide/unsupported.html#OS::Neutron::LoadBalancer>`_. 
The *pool_id* attribute references a NeutronPool resource defined within the 
template while the *protocol_port* attribute specifies which port the members of 
the pool will expose their service. 

The pool resource is of type `OS::Neutron::Pool 
<http://docs.openstack.org/developer/heat/template_guide/unsupported.html#OS::Neutron::Pool>`_. 
Most of the attributes in this definition are fairly self explanatory. The 
*lb_method* property specifies the algorithm used to distribute load between 
the members of the pool while the *subnet_id* specifies which subnet these the 
members in the pool belong to. The *vip* attribute specifies the configuration 
for the Virtual IP Address that will be used to connect to any of these 
wbeservers. The *protocol_port* attribute specifies which port the LB will be 
listening on, and in this particular case the *session_persistence* is maintained
based on the SOURCE_IP of the user connection. Lastly, this Neutron Pool 
definition also references a monitor defined below. 

The monitor resource is of type `OS::Neutron::HealthMonitor 
<http://docs.openstack.org/developer/heat/template_guide/unsupported.html#OS::Neutron::HealthMonitor>`_. 
Its function is to basically monitor each member of the Neutron Pool 
periodically and remove it from the active list of pool IP address if it 
becomes unresponsive. 

Each replica definition within the ResourceGroup must also be configured as a 
Pool Member and thus the Pool Member definition belongs in the 
*Tutorial::Application::HTTP_LB* template definition:

.. code:: yaml

  member:
    type: OS::Neutron::PoolMember
    properties:
      pool_id: {get_param: pool_id}
      address: {get_attr: [instance, first_address]}
      protocol_port: 80

The member resource is of type `OS::Neutron::PoolMember 
<http://docs.openstack.org/developer/heat/template_guide/unsupported.html#OS::Neutron::PoolMember>`_. 
The *pool_id* attribute is passed as an input parameter and referenced from the 
main template. 

Lastly, a floating IP is assigned in the main template to expose the VIP of the 
Load Balancer externally like so:

.. code:: yaml

  http_floating_ip:
    type: Tutorial::FloatingIP
    properties:
      public_network_id: { get_param: public_network_id }
      port: { get_attr: [pool, vip] }

The reader is encouraged to launch this template with the following message:

.. code:: bash
 
  --parameter message="\`hostname\`"

This way a different value will be returned for each curl request as the 
*lb_method* is set to ROUND_ROBIN. 

**Deployment**

This template can be deployed as follows:

.. code:: bash

  $ os stack create -t ex6.3.yaml -e env.yaml ex6.3 --parameter cluster_size=3 --parameter message="\`hostname\`" 
